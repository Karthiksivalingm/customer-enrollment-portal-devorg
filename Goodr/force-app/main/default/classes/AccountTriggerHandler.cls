public inherited sharing class AccountTriggerHandler {

    public static void handleAfterInsert(List<Account> newAccounts) {
        AccountTriggerHelper.assignStoreLocationsToCompany(newAccounts);

        List<Id> accountIdsToInsert = new List<Id>();

        // ── CHANGED: removed 'Key Accounts' exclusion — ALL channels now sync ──
        for (Account acc : newAccounts) {
            if (acc.RecordTypeId == AccountTriggerHelper.getCompanyRecordTypeId() &&
                String.isBlank(acc.Shopify_Company_Id__c) &&
                acc.Skip_Shopify_Sync__c != true) { // Create NetSuite records are not sent to Shopify
                accountIdsToInsert.add(acc.Id);
            }
        }

        if (!accountIdsToInsert.IsEmpty()) {
            System.enqueueJob(new ShopifyAccountSyncQueuable(accountIdsToInsert));
        }

        AccountTriggerHelper.updateCompanyDoors(newAccounts);
        AccountTriggerHelper.updateFranchiseDoors(newAccounts);
        AccountTriggerHelper.updateCompanyTotalSales(newAccounts);
    }

    public static void handleAfterUpdate(List<Account> newAccounts, Map<Id, Account> oldMap) {
        Set<Id> parentIds = new Set<Id>();
        List<Account> accountsToDelete = new List<Account>();

        for (Account acc : newAccounts) {
            if (acc.RecordTypeId == AccountTriggerHelper.getStoreLocationRecordTypeId() && acc.ParentId != null) {
                parentIds.add(acc.ParentId);
            }
        }

        Map<Id, Account> parentsMap = new Map<Id, Account>(
            [SELECT Id, Shopify_Company_Id__c FROM Account WHERE Id IN :parentIds]
        );
        List<Id> storeLocationIdsToSync = new List<Id>();

        for (Account acc : newAccounts) {
            if (acc.RecordTypeId == AccountTriggerHelper.getStoreLocationRecordTypeId()) {
                Account parentAcc = parentsMap.get(acc.ParentId);

                // ── CHANGED: removed 'Key Accounts' exclusion — ALL channels now sync ──
                Boolean locationNeedsSync =
                    String.isBlank(acc.Shopify_Company_Id__c) &&
                    parentAcc != null &&
                    String.isNotBlank(parentAcc.Shopify_Company_Id__c) &&
                    acc.Manual_Approval_Status__c == 'Approved' &&
                    acc.Skip_Shopify_Sync__c != true; // Create NetSuite records are not sent to Shopify

                if (locationNeedsSync) {
                    storeLocationIdsToSync.add(acc.Id);
                }

                String oldStatus = oldMap.get(acc.Id).Manual_Approval_Status__c;
                if (acc.Manual_Approval_Status__c == 'Rejected' && oldStatus != 'Rejected') {
                    accountsToDelete.add(acc);
                }
            }
        }

        if (!storeLocationIdsToSync.isEmpty()) {
            System.enqueueJob(new ShopifyStoreLocationSyncQueuable(storeLocationIdsToSync));
        }

        if (!accountsToDelete.isEmpty()) {
            AccountTriggerHelper.handleRejectedStoreLocations(accountsToDelete);
        }

        AccountTriggerHelper.updateCompanyDoors(newAccounts);
        AccountTriggerHelper.updateFranchiseDoors(newAccounts);

        List<Account> accountsWithRevenueChanges = AccountTriggerHelper.filterAccountsWithRevenueChanges(newAccounts, oldMap);
        if (!accountsWithRevenueChanges.isEmpty()) {
            AccountTriggerHelper.updateCompanyTotalSales(accountsWithRevenueChanges);
        }

        // ── Active__c change detection — roll up + cascade + Shopify push ─────
        List<Account> accountsWithActiveChanges =
            AccountTriggerHelper.filterAccountsWithActiveChanges(newAccounts, oldMap);

        if (!accountsWithActiveChanges.isEmpty()) {

            // ── Step 1: Roll up Active__c from Store Locations to Company ──────
            AccountTriggerHelper.updateCompanyActiveStatus(accountsWithActiveChanges);

            // ── Step 2: Cascade Company Active/Inactive down to Store Locations ──
            List<Account> cascadedLocations = new List<Account>();
            if (!AccountTriggerHelper.bypassChildActiveSync) {
                cascadedLocations = AccountTriggerHelper.syncChildLocationsActiveStatus(accountsWithActiveChanges);
            }

            // ── Step 3: Push Active/Inactive to Shopify ───────────────────────
            // ── BATCH/FUTURE GUARD: Skip when running inside a Batch or Future ──
            if (!AccountTriggerHelper.bypassActiveStatusSync
                && !System.isBatch()
                && !System.isFuture()) {

                Set<Id> storeLocationIdsForShopify = new Set<Id>();

                for (Account acc : accountsWithActiveChanges) {
                    if (acc.RecordTypeId == AccountTriggerHelper.getStoreLocationRecordTypeId()) {
                        storeLocationIdsForShopify.add(acc.Id);
                    }
                }

                for (Account loc : cascadedLocations) {
                    storeLocationIdsForShopify.add(loc.Id);
                }

                if (!storeLocationIdsForShopify.isEmpty()) {
                    // ── CHANGED: removed 'Key Accounts' exclusion filter ──
                    List<Account> locationsForShopifySync = [
                        SELECT Id, Active__c, Shopify_Company_Id__c, Sales_Channel__c
                        FROM Account
                        WHERE Id IN :storeLocationIdsForShopify
                        AND Shopify_Company_Id__c != null
                        AND RecordTypeId = :AccountTriggerHelper.getStoreLocationRecordTypeId()
                    ];

                    if (!locationsForShopifySync.isEmpty()) {
                        System.enqueueJob(
                            new ShopifyActiveStatusSyncQueueable(locationsForShopifySync)
                        );
                    }
                }
            }
        }

        // ── NEW: Address change detection — push Shipping/Billing to Shopify ──
        // ── Fires only when a Store Location address field actually changed    ──
        // ── Skipped when bypassAddressSync = true (set by inbound batch sync)  ──
        // ── to prevent SF → Shopify → SF infinite loop                         ──
        // ── Also skipped in Batch/Future context (same guard as Active sync)   ──
        if (!AccountTriggerHelper.bypassAddressSync
            && !System.isBatch()
            && !System.isFuture()) {

            List<Account> accountsWithAddressChanges =
                AccountTriggerHelper.filterAccountsWithAddressChanges(newAccounts, oldMap);

            if (!accountsWithAddressChanges.isEmpty()) {
                System.enqueueJob(
                    new ShopifyAddressSyncQueueable(accountsWithAddressChanges)
                );
            }
        }
    }

    public static void handleBeforeInsert(List<Account> newAccounts) {
        AccountTriggerHelper.fillParentRecordInformation(newAccounts);
        AccountTriggerHelper.removeSymbolsFromTaxId(newAccounts);
    }

    public static void handleBeforeUpdate(List<Account> newAccounts, Map<Id, Account> oldMap) {
        AccountTriggerHelper.removeSymbolsFromTaxId(newAccounts);
        List<Account> accountsToProcess = new List<Account>();
        for (Account acc : newAccounts) {
            Account oldAcc = oldMap.get(acc.Id);

            Boolean parentChanged = acc.ParentId != oldAcc.ParentId;
            Boolean parentRecordIsEmpty = String.isBlank(acc.Parent_Record__c) && acc.ParentId != null;

            if (parentChanged || parentRecordIsEmpty) {
                accountsToProcess.add(acc);
            }
        }
        AccountTriggerHelper.fillParentRecordInformation(accountsToProcess);
    }

    public static void handleAfterDelete(List<Account> deletedAccounts) {
        if (deletedAccounts == null || deletedAccounts.isEmpty()) {
            return;
        }

        Set<Id> companyIds = new Set<Id>();
        Set<Id> franchiseIds = new Set<Id>();
        Set<Id> deletedCompanyIds = new Set<Id>();

        for (Account acc : deletedAccounts) {
            if (acc == null) {
                continue;
            }

            if (acc.RecordTypeId == AccountTriggerHelper.getCompanyRecordTypeId()) {
                deletedCompanyIds.add(acc.Id);
            }

            if (acc.RecordTypeId == AccountTriggerHelper.getStoreLocationRecordTypeId() && acc.ParentId != null) {
                companyIds.add(acc.ParentId);
            }

            if (acc.RecordTypeId == AccountTriggerHelper.getCompanyRecordTypeId() && acc.ParentId != null) {
                franchiseIds.add(acc.ParentId);
            }
        }

        companyIds.removeAll(deletedCompanyIds);

        if (!companyIds.isEmpty()) {
            List<Account> companiesToUpdate = [SELECT Id, RecordTypeId FROM Account WHERE Id IN :companyIds];
            if (!companiesToUpdate.isEmpty()) {
                AccountTriggerHelper.updateCompanyDoors(companiesToUpdate);
                AccountTriggerHelper.updateCompanyTotalSales(companiesToUpdate);
            }
        }

        if (!franchiseIds.isEmpty()) {
            // FIX: Added ParentId to this query — updateFranchiseDoors reads
            // acc.ParentId internally, and without it queried here, accessing
            // it throws System.SObjectException: SObject row was retrieved
            // via SOQL without querying the requested field: Account.ParentId
            List<Account> franchisesToUpdate = [SELECT Id, RecordTypeId, ParentId FROM Account WHERE Id IN :franchiseIds];
            if (!franchisesToUpdate.isEmpty()) {
                AccountTriggerHelper.updateFranchiseDoors(franchisesToUpdate);
            }
        }
    }
}