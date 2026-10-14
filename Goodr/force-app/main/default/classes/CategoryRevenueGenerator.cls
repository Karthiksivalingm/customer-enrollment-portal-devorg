public class CategoryRevenueGenerator {

    /*@AuraEnabled
    public static void generateCategoryRevenueForAllStoresWithChanges() {
        Set<Id> storeIds = new Set<Id>();
        List<Contact> contactsWithChanges = [
            SELECT AccountId
            FROM Contact
            WHERE Revenue_Changed__c = true
        ];
        for (Contact c : contactsWithChanges) {
            if (c.AccountId != null) {
                storeIds.add(c.AccountId);
            }
        }

        Set<Id> processedStoreIds = new Set<Id>();
        for (Id storeId : storeIds) {
            if (!processedStoreIds.contains(storeId)) {
                processedStoreIds.add(storeId);
                generateCategoryRevenue(storeId);
            }
        }
    }

    public static void generateCategoryRevenue(Id inputAccountId) {
        try {
            HierarchyData hierarchyData = determineHierarchy(inputAccountId);
            if (hierarchyData == null) {
                System.debug('Could not determine account hierarchy');
                return;
            }

            List<Account> allStores = getAllStoresInHierarchy(hierarchyData);
            if (allStores.isEmpty()) {
                System.debug('No Store accounts found in hierarchy');
                return;
            }

            Set<Id> storeIds = new Set<Id>();
            for (Account s : allStores) storeIds.add(s.Id);
            Set<Id> allAccountIds = new Set<Id>(storeIds);
            allAccountIds.addAll(hierarchyData.companyIds);
            if (hierarchyData.franchiseId != null) {
                allAccountIds.add(hierarchyData.franchiseId);
            }

            Set<Id> storesWithChanges = new Set<Id>();
            for (AggregateResult ar : [
                SELECT AccountId accId
                FROM Contact
                WHERE AccountId IN :storeIds
                AND Revenue_Changed__c = true
                GROUP BY AccountId
            ]) {
                storesWithChanges.add((Id)ar.get('accId'));
            }
            if (storesWithChanges.isEmpty()) {
                System.debug('No store accounts have contacts with Revenue_Changed__c = true');
                return;
            }

            Set<Id> companiesToUpdate = new Set<Id>();
            for (Account store : allStores) {
                if (storesWithChanges.contains(store.Id)) {
                    companiesToUpdate.add(store.ParentId);
                }
            }

            Set<Id> franchisesToUpdate = new Set<Id>();
            if (hierarchyData.franchiseId != null && !companiesToUpdate.isEmpty()) {
                franchisesToUpdate.add(hierarchyData.franchiseId);
            }

            Set<Id> accountsToUpdate = new Set<Id>();
            accountsToUpdate.addAll(storesWithChanges);
            accountsToUpdate.addAll(companiesToUpdate);
            accountsToUpdate.addAll(franchisesToUpdate);

            List<Contact> allContacts = [
                SELECT Id, AccountId, Annual_Revenue__c, Parent_Vertical__c,
                       Vertical__c, Sport_Category__c, Retail_Category__c
                FROM Contact
                WHERE AccountId IN :allAccountIds
                AND Annual_Revenue__c != null
            ];
            if (allContacts.isEmpty()) {
                System.debug('No contacts with revenue found in hierarchy');
                return;
            }

            List<Category_Revenue__c> existingRecords = [
                SELECT Id 
                FROM Category_Revenue__c
                WHERE Account__c IN :accountsToUpdate
            ];
            if (!existingRecords.isEmpty()) {
                delete existingRecords;
            }
            
            List<Category_Revenue__c> newRecords = new List<Category_Revenue__c>();

            for (Id storeId : storesWithChanges) {
                List<Category_Revenue__c> storeRecords = calculateTop3ForAccount(storeId, allContacts);
                newRecords.addAll(storeRecords);
            }

            for (Id companyId : companiesToUpdate) {
                List<Category_Revenue__c> companyRecords = calculateTop3ForCompany(companyId, allContacts);
                newRecords.addAll(companyRecords);
            }

            for (Id franchiseId : franchisesToUpdate) {
                List<Category_Revenue__c> franchiseRecords = calculateTop3ForFranchise(franchiseId, allContacts);
                newRecords.addAll(franchiseRecords);
            }
            
            if (!newRecords.isEmpty()) {
                insert newRecords;
                System.debug('Created ' + newRecords.size() + ' Category_Revenue records total');
            }
            
            List<Contact> contactsToReset = [
                SELECT Id, Revenue_Changed__c
                FROM Contact
                WHERE AccountId IN :accountsToUpdate
                AND Revenue_Changed__c = true
            ];
            
            for (Contact c : contactsToReset) {
                c.Revenue_Changed__c = false;
            }
            
            if (!contactsToReset.isEmpty()) {
                update contactsToReset;
            }
            
        } catch (Exception e) {
            System.debug('CategoryRevenueGenerator Error: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new AuraHandledException('Failed to generate category revenue: ' + e.getMessage());
        }
    }
    
    private static HierarchyData determineHierarchy(Id inputAccountId) {
        try {
            Account inputAccount = [
                SELECT Id, ParentId, RecordType.DeveloperName,
                       Parent.Id, Parent.ParentId, Parent.RecordType.DeveloperName
                FROM Account 
                WHERE Id = :inputAccountId
                LIMIT 1
            ];
            
            HierarchyData result = new HierarchyData();
            
            if (inputAccount.RecordType.DeveloperName == 'Franchise') {
                result.franchiseId = inputAccount.Id;
                result.companyIds = getCompanyIdsForFranchise(inputAccount.Id);
            } else if (inputAccount.RecordType.DeveloperName == 'Company') {
                result.companyIds = new Set<Id>{inputAccount.Id};
                if (inputAccount.ParentId != null && inputAccount.Parent.RecordType.DeveloperName == 'Franchise') {
                    result.franchiseId = inputAccount.ParentId;
                    result.companyIds = getCompanyIdsForFranchise(inputAccount.ParentId);
                }
            } else if (inputAccount.RecordType.DeveloperName == 'Store_Location') {
                if (inputAccount.ParentId != null) {
                    result.companyIds = new Set<Id>{inputAccount.ParentId};
                    if (inputAccount.Parent.ParentId != null) {
                        Account grandParent = [
                            SELECT Id, RecordType.DeveloperName
                            FROM Account 
                            WHERE Id = :inputAccount.Parent.ParentId
                            LIMIT 1
                        ];
                        if (grandParent.RecordType.DeveloperName == 'Franchise') {
                            result.franchiseId = grandParent.Id;
                            result.companyIds = getCompanyIdsForFranchise(grandParent.Id);
                        }
                    }
                }
            }
            return result.companyIds.isEmpty() ? null : result;
        } catch (Exception e) {
            System.debug('Error determining hierarchy: ' + e.getMessage());
            return null;
        }
    }
    
    private static Set<Id> getCompanyIdsForFranchise(Id franchiseId) {
        List<Account> companies = [
            SELECT Id 
            FROM Account
            WHERE ParentId = :franchiseId
            AND RecordType.DeveloperName = 'Company'
        ];
        Set<Id> companyIds = new Set<Id>();
        for (Account company : companies) companyIds.add(company.Id);
        return companyIds;
    }
    
    private static List<Account> getAllStoresInHierarchy(HierarchyData hierarchyData) {
        return [
            SELECT Id, ParentId
            FROM Account
            WHERE ParentId IN :hierarchyData.companyIds
            AND RecordType.DeveloperName = 'Store_Location'
        ];
    }
    
    private static List<Category_Revenue__c> calculateTop3ForAccount(Id accountId, List<Contact> allContacts) {
        List<Contact> relevantContacts = new List<Contact>();
        for (Contact c : allContacts) {
            if (c.AccountId == accountId) relevantContacts.add(c);
        }
        return processContactsForRevenue(accountId, relevantContacts);
    }
    
    private static List<Category_Revenue__c> calculateTop3ForCompany(Id companyId, List<Contact> allContacts) {
        Set<Id> storeIds = getStoreIdsForCompany(companyId);
        storeIds.add(companyId);
        List<Contact> relevantContacts = new List<Contact>();
        for (Contact c : allContacts) {
            if (storeIds.contains(c.AccountId)) relevantContacts.add(c);
        }
        return processContactsForRevenue(companyId, relevantContacts);
    }
    
    private static List<Category_Revenue__c> calculateTop3ForFranchise(Id franchiseId, List<Contact> allContacts) {
        return processContactsForRevenue(franchiseId, allContacts);
    }
    
    private static Set<Id> getStoreIdsForCompany(Id companyId) {
        List<Account> stores = [
            SELECT Id FROM Account
            WHERE ParentId = :companyId
            AND RecordType.DeveloperName = 'Store_Location'
        ];
        Set<Id> storeIds = new Set<Id>();
        for (Account s : stores) storeIds.add(s.Id);
        return storeIds;
    }
    
    private static List<Category_Revenue__c> processContactsForRevenue(Id accountId, List<Contact> contacts) {
        if (contacts.isEmpty()) return new List<Category_Revenue__c>();
        
        Map<String, CombinationData> combinationMap = new Map<String, CombinationData>();
        for (Contact c : contacts) {
            String key = createCombinationKey(
                c.Parent_Vertical__c,
                c.Vertical__c,
                c.Sport_Category__c,
                c.Retail_Category__c
            );
            if (!combinationMap.containsKey(key)) {
                combinationMap.put(key, new CombinationData(
                    c.Parent_Vertical__c,
                    c.Vertical__c,
                    c.Sport_Category__c,
                    c.Retail_Category__c,
                    0
                ));
            }
            CombinationData cd = combinationMap.get(key);
            cd.totalRevenue += c.Annual_Revenue__c;
        }
        
        List<CombinationData> sortedList = new List<CombinationData>();
        sortedList.addAll(combinationMap.values());
        sortedList.sort(new CombinationRevenueComparator());
        
        List<Category_Revenue__c> newRecords = new List<Category_Revenue__c>();
        Integer countToCreate = Math.min(3, sortedList.size());
        
        for (Integer i=0; i<countToCreate; i++) {
            CombinationData cd = sortedList[i];
            newRecords.add(new Category_Revenue__c(
                Account__c = accountId,
                Annual_Revenue__c = cd.totalRevenue,
                Parent_Vertical__c = cd.parentVertical,
                Vertical__c = cd.vertical,
                Sport_Category__c = cd.sportCategory,
                Retail_Category__c = cd.retailCategory
            ));
        }
        return newRecords;
    }

    private static String createCombinationKey(String parentVertical, String vertical,
                                              String sportCategory, String retailCategory) {
        return String.valueOf(parentVertical) + '|' +
               String.valueOf(vertical) + '|' +
               String.valueOf(sportCategory) + '|' +
               String.valueOf(retailCategory);
    }

    private class HierarchyData {
        public Id franchiseId;
        public Set<Id> companyIds = new Set<Id>();
        public HierarchyData() {
            companyIds = new Set<Id>();
        }
    }

    private class CombinationData {
        public String parentVertical;
        public String vertical;
        public String sportCategory;
        public String retailCategory;
        public Decimal totalRevenue;

        public CombinationData(String parentVertical, String vertical, 
                              String sportCategory, String retailCategory, Decimal totalRevenue) {
            this.parentVertical = parentVertical;
            this.vertical = vertical;
            this.sportCategory = sportCategory;
            this.retailCategory = retailCategory;
            this.totalRevenue = totalRevenue;
        }
    }

    private class CombinationRevenueComparator implements Comparator<CombinationData> {
        public Integer compare(CombinationData c1, CombinationData c2) {
            if (c1.totalRevenue == null && c2.totalRevenue == null) return 0;
            if (c1.totalRevenue == null) return 1;
            if (c2.totalRevenue == null) return -1;
            
            if (c1.totalRevenue > c2.totalRevenue) return -1;
            if (c1.totalRevenue < c2.totalRevenue) return 1;
            return 0;
        }
    }*/
}