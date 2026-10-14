public inherited sharing class AccountTriggerHelper {

    private static Boolean isRunningCompanies = false;
    private static Boolean isRunningFranchises = false;
    public static Boolean bypassActiveStatusSync = false;
    // ── NEW: Bypass flag to prevent address sync loop when inbound Shopify sync runs ──
    public static Boolean bypassAddressSync = false;
    // ── Bypass flag to prevent recursive trigger loop when cascading Company → Store Locations ──
    public static Boolean bypassChildActiveSync = false;

    public static void fillParentRecordInformation(List<Account> newAccounts) {
        for (Account acc : newAccounts) {
            if (acc.ParentId != null) {
                if (acc.RecordTypeId == getStoreLocationRecordTypeId()) {
                    acc.Parent_Record__c = acc.ParentId;
                } else if (acc.RecordTypeId == getCompanyRecordTypeId()) {
                    acc.Parent_Record__c = acc.ParentId;
                }
            }
        }
    }

    public static void removeSymbolsFromTaxId(List<Account> newAccounts) {
        for (Account acc : newAccounts) {
            if (String.isNotBlank(acc.Tax_Id__c)) {
                acc.Tax_Id__c = acc.Tax_Id__c.replaceAll('[^0-9]', '');
            }
        }
    }

    public static void updateCompanyDoors(List<Account> touchedAccounts) {
        if (isRunningCompanies) {
            return;
        }
        isRunningCompanies = true;
        try {
            Set<Id> companyIds = new Set<Id>();

            for (Account acc : touchedAccounts) {
                if (acc == null) {
                    continue;
                }

                if (acc.RecordTypeId == getStoreLocationRecordTypeId() && acc.ParentId != null) {
                    companyIds.add(acc.ParentId);
                }
                if (acc.RecordTypeId == getCompanyRecordTypeId()) {
                    companyIds.add(acc.Id);
                }
            }

            if (companyIds.isEmpty()) {
                return;
            }

            Map<Id, Integer> companyToStoreCount = new Map<Id, Integer>();
            for (AggregateResult ar : [
                SELECT ParentId companyId, COUNT(Id) storeCount
                FROM Account
                WHERE ParentId IN :companyIds
                  AND RecordTypeId = :getStoreLocationRecordTypeId()
                GROUP BY ParentId
            ]) {
                companyToStoreCount.put((Id)ar.get('companyId'), (Integer)ar.get('storeCount'));
            }

            List<Account> toUpdate = new List<Account>();
            for (Id cid : companyIds) {
                Integer cnt = companyToStoreCount.get(cid);
                toUpdate.add(new Account(
                    Id = cid,
                    Doors__c = (cnt == null) ? 0 : cnt
                ));
            }

            if (!toUpdate.isEmpty()) {
                update toUpdate;
            }
        } finally {
            isRunningCompanies = false;
        }
    }

    public static void updateCompanyTotalSales(List<Account> touchedAccounts) {
        if (isRunningCompanies) {
            return;
        }
        isRunningCompanies = true;
        try {
            Set<Id> companyIds = new Set<Id>();

            for (Account acc : touchedAccounts) {
                if (acc == null) {
                    continue;
                }

                if (acc.RecordTypeId == getStoreLocationRecordTypeId() && acc.ParentId != null) {
                    companyIds.add(acc.ParentId);
                }
                if (acc.RecordTypeId == getCompanyRecordTypeId()) {
                    companyIds.add(acc.Id);
                }
            }

            if (companyIds.isEmpty()) {
                return;
            }

            Map<Id, Decimal> companyToTotalSales  = new Map<Id, Decimal>();
            Map<Id, Decimal> companyToTotalOrders = new Map<Id, Decimal>();

            for (AggregateResult ar : [
                SELECT ParentId companyId,
                    SUM(Total_Sales__c) totalSales,
                    SUM(Total_Orders__c) totalOrders
                FROM Account
                WHERE ParentId IN :companyIds
                AND RecordTypeId = :getStoreLocationRecordTypeId()
                GROUP BY ParentId
            ]) {
                Id cid = (Id)ar.get('companyId');
                companyToTotalSales.put(cid, (Decimal)ar.get('totalSales'));
                companyToTotalOrders.put(cid, (Decimal)ar.get('totalOrders'));
            }

            List<Account> toUpdate = new List<Account>();
            for (Id cid : companyIds) {
                Decimal sales  = companyToTotalSales.get(cid);
                Decimal orders = companyToTotalOrders.get(cid);
                toUpdate.add(new Account(
                    Id              = cid,
                    Total_Sales__c  = (sales == null)  ? 0 : sales,
                    Total_Orders__c = (orders == null) ? 0 : orders
                ));
            }

            if (!toUpdate.isEmpty()) {
                update toUpdate;
            }
        } finally {
            isRunningCompanies = false;
        }
    }

    public static List<Account> filterAccountsWithRevenueChanges(
        List<Account> newAccounts,
        Map<Id, Account> oldMap
    ) {
        List<Account> result = new List<Account>();
        for (Account acc : newAccounts) {
            if (acc.RecordTypeId != AccountTriggerHelper.getStoreLocationRecordTypeId()) {
                continue;
            }
            Account oldAcc = oldMap.get(acc.Id);
            Boolean revenueChanged = (
                acc.Total_Sales__c  != oldAcc.Total_Sales__c ||
                acc.Total_Orders__c != oldAcc.Total_Orders__c
            );
            if (revenueChanged && acc.ParentId != null) {
                result.add(acc);
            }
        }
        return result;
    }

    // ── UPDATED: Now includes both Store Location AND Company record types ──
    public static List<Account> filterAccountsWithActiveChanges(
        List<Account> newAccounts,
        Map<Id, Account> oldMap
    ) {
        List<Account> result = new List<Account>();
        for (Account acc : newAccounts) {
            Boolean isStoreLocation =
                acc.RecordTypeId == AccountTriggerHelper.getStoreLocationRecordTypeId();
            Boolean isCompany =
                acc.RecordTypeId == AccountTriggerHelper.getCompanyRecordTypeId();

            if (!isStoreLocation && !isCompany) {
                continue;
            }

            Account oldAcc = oldMap.get(acc.Id);
            if (acc.Active__c != oldAcc.Active__c) {
                result.add(acc);
            }
        }
        return result;
    }

    // ── NEW: Filter Store Locations where Shipping or Billing address changed ──
    // ── Skipped when bypassAddressSync is true (set during inbound Shopify     ──
    // ── batch sync) to prevent a SF→Shopify→SF→Shopify infinite loop           ──
    public static List<Account> filterAccountsWithAddressChanges(
        List<Account> newAccounts,
        Map<Id, Account> oldMap
    ) {
        List<Account> result = new List<Account>();

        // If inbound Shopify sync is writing addresses, do not push back out
        if (AccountTriggerHelper.bypassAddressSync) {
            return result;
        }

        for (Account acc : newAccounts) {
            // Only Store Locations are linked to a Shopify CompanyLocation
            if (acc.RecordTypeId != AccountTriggerHelper.getStoreLocationRecordTypeId()) {
                continue;
            }

            // Must have a Shopify ID to push anything
            if (String.isBlank(acc.Shopify_Company_Id__c)) {
                continue;
            }

            Account oldAcc = oldMap.get(acc.Id);

            Boolean shippingChanged =
                acc.ShippingStreet     != oldAcc.ShippingStreet     ||
                acc.ShippingCity       != oldAcc.ShippingCity       ||
                acc.ShippingState      != oldAcc.ShippingState      ||
                acc.ShippingPostalCode != oldAcc.ShippingPostalCode ||
                acc.ShippingCountry    != oldAcc.ShippingCountry;

            Boolean billingChanged =
                acc.BillingStreet     != oldAcc.BillingStreet     ||
                acc.BillingCity       != oldAcc.BillingCity       ||
                acc.BillingState      != oldAcc.BillingState      ||
                acc.BillingPostalCode != oldAcc.BillingPostalCode ||
                acc.BillingCountry    != oldAcc.BillingCountry;

            if (shippingChanged || billingChanged) {
                result.add(acc);
            }
        }
        return result;
    }

    // ── Roll up Active__c from Store Locations to Company ────────────────────
    // ── UPDATED: Also copies Offboarding_Reason__c, Offboarding_Notes__c,     ──
    // ── Offboarding_Date__c, and Offboarded_By__c from the Store Location     ──
    // ── that triggered the rollup, but ONLY on a genuine TRUE -> FALSE        ──
    // ── transition. If multiple Store Locations under the same Company        ──
    // ── deactivate in the same transaction, the one with the most recent      ──
    // ── Offboarding_Date__c is used as the source of truth.                   ──
    public static void updateCompanyActiveStatus(List<Account> touchedAccounts) {
        if (isRunningCompanies) {
            return;
        }
        isRunningCompanies = true;
        try {
            Set<Id> companyIds = new Set<Id>();

            for (Account acc : touchedAccounts) {
                if (acc == null) {
                    continue;
                }
                if (acc.RecordTypeId == getStoreLocationRecordTypeId() && acc.ParentId != null) {
                    companyIds.add(acc.ParentId);
                }
            }

            if (companyIds.isEmpty()) {
                return;
            }

            Set<Id> companiesWithActiveLocation = new Set<Id>();
            for (Account loc : [
                SELECT Id, ParentId
                FROM Account
                WHERE ParentId IN :companyIds
                AND RecordTypeId = :getStoreLocationRecordTypeId()
                AND Active__c = true
            ]) {
                companiesWithActiveLocation.add(loc.ParentId);
            }

            // NEW: need each company's CURRENT Active__c to confirm this is a
            // genuine transition, not an already-inactive company being
            // touched again for an unrelated reason
            Map<Id, Account> existingCompanies = new Map<Id, Account>([
                SELECT Id, Active__c FROM Account WHERE Id IN :companyIds
            ]);

            // NEW: identify the triggering Store Location per company. If
            // multiple locations deactivate in the same transaction, use the
            // one with the latest Offboarding_Date__c for a deterministic result.
            Map<Id, Account> companyToTriggeringLocation = new Map<Id, Account>();
            for (Account acc : touchedAccounts) {
                if (acc.RecordTypeId == getStoreLocationRecordTypeId()
                    && acc.ParentId != null
                    && acc.Active__c == false
                    && !companiesWithActiveLocation.contains(acc.ParentId)) {

                    Account existingPick = companyToTriggeringLocation.get(acc.ParentId);
                    if (existingPick == null
                        || (acc.Offboarding_Date__c != null
                            && (existingPick.Offboarding_Date__c == null
                                || acc.Offboarding_Date__c > existingPick.Offboarding_Date__c))) {
                        companyToTriggeringLocation.put(acc.ParentId, acc);
                    }
                }
            }

            List<Account> toUpdate = new List<Account>();
            for (Id cid : companyIds) {
                Boolean willBeActive = companiesWithActiveLocation.contains(cid);
                Account existing = existingCompanies.get(cid);
                Boolean wasActive = existing != null ? existing.Active__c : null;

                Account companyUpdate = new Account(
                    Id        = cid,
                    Active__c = willBeActive
                );

                // NEW: only copy offboarding fields on a genuine TRUE -> FALSE transition
                if (willBeActive == false && wasActive == true) {
                    Account triggerLoc = companyToTriggeringLocation.get(cid);
                    if (triggerLoc != null) {
                        companyUpdate.Offboarding_Reason__c = triggerLoc.Offboarding_Reason__c;
                        companyUpdate.Offboarding_Notes__c  = triggerLoc.Offboarding_Notes__c;
                        companyUpdate.Offboarding_Date__c   = triggerLoc.Offboarding_Date__c;
                        companyUpdate.Offboarded_By__c      = triggerLoc.Offboarded_By__c;
                    }
                }

                toUpdate.add(companyUpdate);
            }

            if (!toUpdate.isEmpty()) {
                update toUpdate;
            }
        } finally {
            isRunningCompanies = false;
        }
    }

    // ── FIX: Cascade Company Active/Inactive down to Child Store Locations ───
    // ── Only change from original: update toUpdate → Database.update(false) ──
    // ── This prevents one bad ShippingState record from rolling back         ──
    // ── Active__c updates for ALL other store locations in the same batch    ──
    // ── UPDATED: Also copies Offboarding_Reason__c, Offboarding_Notes__c,     ──
    // ── Offboarding_Date__c, and Offboarded_By__c from the Company down to    ──
    // ── each cascaded Store Location, but ONLY when cascading to INACTIVE.    ──
    // ── companyActiveMap (Map<Id, Boolean>) is now companiesById              ──
    // ── (Map<Id, Account>) so the full Company record's offboarding fields    ──
    // ── are available, not just its Active__c value.                         ──
    public static List<Account> syncChildLocationsActiveStatus(List<Account> changedCompanies) {

        Map<Id, Account> companiesById = new Map<Id, Account>();
        for (Account acc : changedCompanies) {
            if (acc.RecordTypeId == getCompanyRecordTypeId()) {
                companiesById.put(acc.Id, acc);
            }
        }

        if (companiesById.isEmpty()) {
            return new List<Account>();
        }

        List<Account> childLocations = [
            SELECT Id, ParentId, Active__c, Shopify_Company_Id__c, Sales_Channel__c
            FROM Account
            WHERE ParentId IN :companiesById.keySet()
            AND RecordTypeId = :getStoreLocationRecordTypeId()
        ];

        if (childLocations.isEmpty()) {
            return new List<Account>();
        }

        List<Account> toUpdate          = new List<Account>();
        List<Account> affectedLocations = new List<Account>();

        for (Account loc : childLocations) {
            Account parentCompany = companiesById.get(loc.ParentId);
            Boolean companyActive = parentCompany.Active__c;

            if (loc.Active__c != companyActive) {
                Account updateRecord = new Account(
                    Id        = loc.Id,
                    Active__c = companyActive
                );

                // NEW: only copy offboarding fields when cascading to INACTIVE
                if (companyActive == false) {
                    updateRecord.Offboarding_Reason__c = parentCompany.Offboarding_Reason__c;
                    updateRecord.Offboarding_Notes__c  = parentCompany.Offboarding_Notes__c;
                    updateRecord.Offboarding_Date__c   = parentCompany.Offboarding_Date__c;
                    updateRecord.Offboarded_By__c      = parentCompany.Offboarded_By__c;
                }

                toUpdate.add(updateRecord);
                affectedLocations.add(loc);
            }
        }

        if (!toUpdate.isEmpty()) {
            AccountTriggerHelper.bypassChildActiveSync  = true;
            AccountTriggerHelper.bypassActiveStatusSync = true;

            // FIX: Database.update with allOrNone=false
            // Previously: update toUpdate (allOrNone=true — one bad ShippingState
            // on any store rolls back Active__c for ALL stores in the batch)
            // Now: each row is independent — one failure does not affect others
            Database.SaveResult[] results = Database.update(toUpdate, false);

            AccountTriggerHelper.bypassChildActiveSync  = false;
            AccountTriggerHelper.bypassActiveStatusSync = false;

            // Log any individual row failures as Api_Log__c records
            // so they are visible in the API Logs tab for investigation
            List<Api_Log__c> errorLogs = new List<Api_Log__c>();
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for (Database.Error err : results[i].getErrors()) {
                        System.debug(
                            'syncChildLocationsActiveStatus DML failed for store '
                            + toUpdate[i].Id + ': ' + err.getMessage()
                        );
                        errorLogs.add(new Api_Log__c(
                            Context__c           = 'Account Trigger - Active Sync Error',
                            Response_Message__c  = err.getMessage(),
                            Stack_Trace__c       = 'Store Location Id: ' + toUpdate[i].Id +
                                                   ' | Fields: ' +
                                                   String.valueOf(err.getFields()) +
                                                   ' | Fix: correct ShippingState on this record',
                            Related_Record_Id__c = toUpdate[i].Id,
                            Log_Type__c          = 'API Errors'
                        ));
                    }
                }
            }
            if (!errorLogs.isEmpty()) {
                insert errorLogs;
            }
        }

        return affectedLocations;
    }

    public static void updateFranchiseDoors(List<Account> touchedAccounts) {
        if (isRunningFranchises) {
            return;
        }
        isRunningFranchises = true;
        try {
            Set<Id> franchiseIds = new Set<Id>();

            for (Account acc : touchedAccounts) {
                if (acc == null) {
                    continue;
                }

                if (acc.RecordTypeId == getCompanyRecordTypeId() && acc.ParentId != null) {
                    franchiseIds.add(acc.ParentId);
                }
            }

            if (franchiseIds.isEmpty()) {
                return;
            }

            Map<Id, Decimal> franchiseToDoors         = new Map<Id, Decimal>();
            Map<Id, Decimal> franchiseToDoorsOverride = new Map<Id, Decimal>();

            for (AggregateResult ar : [
                SELECT ParentId franchiseId,
                    SUM(Doors__c) totalDoors,
                    SUM(Doors_Override__c) totalDoorsOverride
                FROM Account
                WHERE ParentId IN :franchiseIds
                  AND RecordTypeId = :getCompanyRecordTypeId()
                GROUP BY ParentId
            ]) {
                Id fid = (Id)ar.get('franchiseId');
                franchiseToDoors.put(fid, (Decimal)ar.get('totalDoors'));
                franchiseToDoorsOverride.put(fid, (Decimal)ar.get('totalDoorsOverride'));
            }

            List<Account> toUpdate = new List<Account>();
            for (Id fid : franchiseIds) {
                Decimal sumDoors = franchiseToDoors.get(fid);
                toUpdate.add(new Account(
                    Id               = fid,
                    Doors__c         = (sumDoors == null) ? 0 : sumDoors,
                    Doors_Override__c = franchiseToDoorsOverride.containsKey(fid)
                                        ? franchiseToDoorsOverride.get(fid) : 0
                ));
            }

            if (!toUpdate.isEmpty()) {
                update toUpdate;
            }
        } finally {
            isRunningFranchises = false;
        }
    }

    public static String getStoreLocationRecordTypeId() {
        return Schema.SObjectType.Account
            .getRecordTypeInfosByName().get('Store Location').getRecordTypeId();
    }

    public static String getCompanyRecordTypeId() {
        return Schema.SObjectType.Account
            .getRecordTypeInfosByName().get('Company').getRecordTypeId();
    }

    public static void assignStoreLocationsToCompany(List<Account> newAccounts) {
        List<Account> storeLocationsToAssign = new List<Account>();
        Set<String> taxIds = new Set<String>();

        for (Account acc : newAccounts) {
            if (acc.RecordTypeId == getStoreLocationRecordTypeId() &&
                String.isNotBlank(acc.Tax_Id__c) &&
                acc.ParentId == null) {
                storeLocationsToAssign.add(acc);
                taxIds.add(acc.Tax_Id__c);
            }
        }

        if (storeLocationsToAssign.isEmpty()) {
            return;
        }

        Map<String, Account> taxIdToCompanyMap = new Map<String, Account>();
        for (Account company : [
            SELECT Id, Tax_Id__c
            FROM Account
            WHERE Tax_Id__c IN :taxIds
            AND RecordType.DeveloperName = 'Company'
        ]) {
            if (String.isNotBlank(company.Tax_Id__c)) {
                taxIdToCompanyMap.put(company.Tax_Id__c, company);
            }
        }

        Set<String> companyIds = new Set<String>();
        for (Account storeLoc : storeLocationsToAssign) {
            Account matchedCompany = taxIdToCompanyMap.get(storeLoc.Tax_Id__c);
            if (matchedCompany != null) {
                companyIds.add(matchedCompany.Id);
            }
        }

        Map<Id, List<Account>> companyToExistingStoresMap = new Map<Id, List<Account>>();
        if (!companyIds.isEmpty()) {
            for (Account existingStore : [
                SELECT Id, ShippingStreet, ShippingPostalCode, ShippingCity, ParentId
                FROM Account
                WHERE ParentId IN :companyIds
                AND RecordType.DeveloperName = 'Store_Location'
                AND ShippingStreet != null
                AND ShippingPostalCode != null
                AND ShippingCity != null
            ]) {
                if (!companyToExistingStoresMap.containsKey(existingStore.ParentId)) {
                    companyToExistingStoresMap.put(existingStore.ParentId, new List<Account>());
                }
                companyToExistingStoresMap.get(existingStore.ParentId).add(existingStore);
            }
        }

        List<Account> accountsToUpdate = new List<Account>();
        List<Case>    rejectionCases   = new List<Case>();
        List<Account> accountsToDelete = new List<Account>();
        // ── NEW: Api_Log__c records replacing the rejectionCases Cases below ──
        List<Api_Log__c> rejectionLogs = new List<Api_Log__c>();

        Decimal SIMILARITY_THRESHOLD = 96;

        for (Account storeLoc : storeLocationsToAssign) {
            Account matchedCompany = taxIdToCompanyMap.get(storeLoc.Tax_Id__c);

            if (matchedCompany != null) {
                Boolean isDuplicate    = false;
                Account duplicateStore = null;
                Decimal maxSimilarity  = 0;

                List<Account> existingStores =
                    companyToExistingStoresMap.get(matchedCompany.Id);

                if (existingStores != null) {
                    for (Account existingStore : existingStores) {
                        Boolean isStreetIdentical = AddressDuplicateService.areAddressesIdentical(
                            storeLoc.ShippingStreet,
                            existingStore.ShippingStreet
                        );
                        if (isStreetIdentical) {
                            String normCity1 = AddressDuplicateService.normalizeAddress(storeLoc.ShippingCity);
                            String normCity2 = AddressDuplicateService.normalizeAddress(existingStore.ShippingCity);
                            String normZip1  = storeLoc.ShippingPostalCode != null
                                ? storeLoc.ShippingPostalCode.replaceAll('[^0-9]', '') : '';
                            String normZip2  = existingStore.ShippingPostalCode != null
                                ? existingStore.ShippingPostalCode.replaceAll('[^0-9]', '') : '';

                            if (normCity1 == normCity2 && normZip1 == normZip2) {
                                isDuplicate    = true;
                                duplicateStore = existingStore;
                                maxSimilarity  = 100;
                                break;
                            }
                        }

                        Decimal similarity = AddressDuplicateService.compareFullAddresses(
                            storeLoc.ShippingStreet,
                            storeLoc.ShippingCity,
                            storeLoc.ShippingPostalCode,
                            existingStore.ShippingStreet,
                            existingStore.ShippingCity,
                            existingStore.ShippingPostalCode
                        );

                        if (similarity > maxSimilarity) {
                            maxSimilarity = similarity;
                        }

                        if (similarity > SIMILARITY_THRESHOLD) {
                            isDuplicate    = true;
                            duplicateStore = existingStore;
                            break;
                        }
                    }
                }

                if (isDuplicate) {
                    // ── CHANGE: Case creation disabled — replaced with Api_Log__c below ──
                    // rejectionCases.add(new Case(
                    //     Subject     = 'Duplicate Store Location Address',
                    //     Status      = 'New',
                    //     Origin      = 'Web',
                    //     Reason      = 'Duplicate Address Found',
                    //     Description = 'Store Location with Tax ID ' + storeLoc.Tax_Id__c +
                    //         ' has a duplicate address. Address: ' +
                    //         storeLoc.ShippingStreet + ', ' +
                    //         storeLoc.ShippingCity   + ', ' +
                    //         storeLoc.ShippingPostalCode +
                    //         (String.isNotBlank(storeLoc.Name)
                    //             ? ' | Name: '  + storeLoc.Name : '') +
                    //         (String.isNotBlank(storeLoc.New_User_Phone__c)
                    //             ? ' | Phone: ' + storeLoc.New_User_Phone__c : '') +
                    //         (String.isNotBlank(storeLoc.New_User_Email__c)
                    //             ? ' | Email: ' + storeLoc.New_User_Email__c : '')
                    // ));

                    // ── NEW: Api_Log__c creation replacing the Case creation above ──
                    rejectionLogs.add(new Api_Log__c(
                        Context__c = 'Duplicate Store Location Address',
                        Response_Message__c = 'Store Location with Tax ID ' + storeLoc.Tax_Id__c +
                            ' has a duplicate address. Address: ' +
                            storeLoc.ShippingStreet + ', ' +
                            storeLoc.ShippingCity   + ', ' +
                            storeLoc.ShippingPostalCode +
                            (String.isNotBlank(storeLoc.Name)
                                ? ' | Name: '  + storeLoc.Name : '') +
                            (String.isNotBlank(storeLoc.New_User_Phone__c)
                                ? ' | Phone: ' + storeLoc.New_User_Phone__c : '') +
                            (String.isNotBlank(storeLoc.New_User_Email__c)
                                ? ' | Email: ' + storeLoc.New_User_Email__c : ''),
                        Related_Record_Id__c = storeLoc.Id,
                        Log_Type__c = 'Duplicate Detection'
                    ));
                    accountsToDelete.add(new Account(Id = storeLoc.Id));
                } else {
                    accountsToUpdate.add(new Account(
                        Id                 = storeLoc.Id,
                        Name               = storeLoc.Name + ' ' +
                                             storeLoc.ShippingStreet + ' ' +
                                             storeLoc.ShippingPostalCode,
                        ParentId           = matchedCompany.Id,
                        ShippingStreet     = storeLoc.ShippingStreet,
                        ShippingCity       = storeLoc.ShippingCity,
                        ShippingState      = storeLoc.ShippingState,
                        ShippingPostalCode = storeLoc.ShippingPostalCode,
                        ShippingCountry    = storeLoc.ShippingCountry
                    ));

                    if (!companyToExistingStoresMap.containsKey(matchedCompany.Id)) {
                        companyToExistingStoresMap.put(matchedCompany.Id, new List<Account>());
                    }
                    companyToExistingStoresMap.get(matchedCompany.Id).add(storeLoc);
                }
            } else {
                // ── CHANGE: Case creation disabled — replaced with Api_Log__c below ──
                // rejectionCases.add(new Case(
                //     Subject     = 'Company Not Found',
                //     Status      = 'New',
                //     Origin      = 'Web',
                //     Reason      = 'Parent Company Not Found',
                //     Description = 'Store Location with Tax ID ' + storeLoc.Tax_Id__c +
                //         ' could not find a matching Company. ' +
                //         (String.isNotBlank(storeLoc.Name)
                //             ? ' | Name: '  + storeLoc.Name : '') +
                //         (String.isNotBlank(storeLoc.New_User_Phone__c)
                //             ? ' | Phone: ' + storeLoc.New_User_Phone__c : '') +
                //         (String.isNotBlank(storeLoc.New_User_Email__c)
                //             ? ' | Email: ' + storeLoc.New_User_Email__c : '')
                // ));

                // ── NEW: Api_Log__c creation replacing the Case creation above ──
                rejectionLogs.add(new Api_Log__c(
                    Context__c = 'Store Location - Company Not Found',
                    Response_Message__c = 'Store Location with Tax ID ' + storeLoc.Tax_Id__c +
                        ' could not find a matching Company. ' +
                        (String.isNotBlank(storeLoc.Name)
                            ? ' | Name: '  + storeLoc.Name : '') +
                        (String.isNotBlank(storeLoc.New_User_Phone__c)
                            ? ' | Phone: ' + storeLoc.New_User_Phone__c : '') +
                        (String.isNotBlank(storeLoc.New_User_Email__c)
                            ? ' | Email: ' + storeLoc.New_User_Email__c : ''),
                    Related_Record_Id__c = storeLoc.Id,
                    Log_Type__c = 'Match Failure'
                ));
                accountsToDelete.add(new Account(Id = storeLoc.Id));
            }
        }

        // ── CHANGE: Case insert disabled — replaced with Api_Log__c insert below ──
        // if (!rejectionCases.isEmpty()) {
        //     insert rejectionCases;
        // }

        // ── NEW: Api_Log__c insert replacing the Case insert above ──
        if (!rejectionLogs.isEmpty()) {
            insert rejectionLogs;
        }
        if (!accountsToDelete.isEmpty()) {
            delete accountsToDelete;
        }
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }

    public static void handleRejectedStoreLocations(List<Account> rejectedAccounts) {
        // ── CHANGE: Case creation disabled — replaced with Api_Log__c below ──
        // List<Case>    casesToInsert        = new List<Case>();
        List<Account> accountsCopyToDelete = new List<Account>();
        // ── NEW: Api_Log__c list replacing casesToInsert above ──
        List<Api_Log__c> logsToInsert = new List<Api_Log__c>();

        for (Account acc : rejectedAccounts) {
            // ── CHANGE: Case creation disabled — replaced with Api_Log__c below ──
            // casesToInsert.add(new Case(
            //     Subject     = 'Rejected Store Location: ' + acc.Name,
            //     Status      = 'New',
            //     Type        = 'Manual Rejection',
            //     Origin      = 'System',
            //     Description = 'Store Location was manually rejected. ' +
            //         'Name: ' + acc.Name +
            //         (String.isNotBlank(acc.New_User_Phone__c)
            //             ? ' | Phone: ' + acc.New_User_Phone__c : '') +
            //         (String.isNotBlank(acc.New_User_Email__c)
            //             ? ' | Email: ' + acc.New_User_Email__c : '')
            // ));

            // ── NEW: Api_Log__c creation replacing the Case creation above ──
            logsToInsert.add(new Api_Log__c(
                Context__c = 'Store Location Manually Rejected',
                Response_Message__c = 'Store Location was manually rejected. ' +
                    'Name: ' + acc.Name +
                    (String.isNotBlank(acc.New_User_Phone__c)
                        ? ' | Phone: ' + acc.New_User_Phone__c : '') +
                    (String.isNotBlank(acc.New_User_Email__c)
                        ? ' | Email: ' + acc.New_User_Email__c : ''),
                Related_Record_Id__c = acc.Id,
                Log_Type__c = 'Manual Rejection'
            ));
            accountsCopyToDelete.add(new Account(Id = acc.Id));
        }

        // ── CHANGE: Case insert disabled — replaced with Api_Log__c insert below ──
        // if (!casesToInsert.isEmpty()) {
        //     insert casesToInsert;
        // }

        // ── NEW: Api_Log__c insert replacing the Case insert above ──
        if (!logsToInsert.isEmpty()) {
            insert logsToInsert;
        }
        delete accountsCopyToDelete;
    }

    private static String generateAddressHash(
        String street,
        String zipCode,
        String city
    ) {
        String combinedAddress = '';
        if (String.isNotBlank(street))  { combinedAddress += street; }
        if (String.isNotBlank(zipCode)) { combinedAddress += zipCode; }
        if (String.isNotBlank(city))    { combinedAddress += city; }
        return combinedAddress.toLowerCase().replaceAll('[\\s\',]', '');
    }
}