public inherited sharing class ContactTriggerHandler {

    public static void handleBeforeInsert(List<Contact> newContacts) {
        ContactTriggerHelper.removeSymbolsFromTaxId(newContacts);

        // NEW: Inherit Sales_Channel__c from Account if blank
        // This ensures Cluster__c formula has a value after insert
        Set<Id> accountIds = new Set<Id>();
        for (Contact con : newContacts) {
            if (String.isBlank(con.Sales_Channel__c) && con.AccountId != null) {
                accountIds.add(con.AccountId);
            }
        }
        if (!accountIds.isEmpty()) {
            Map<Id, Account> accMap = new Map<Id, Account>(
                [SELECT Id, Sales_Channel__c FROM Account WHERE Id IN :accountIds]
            );
            for (Contact con : newContacts) {
                if (String.isBlank(con.Sales_Channel__c) && con.AccountId != null) {
                    Account acc = accMap.get(con.AccountId);
                    if (acc != null && String.isNotBlank(acc.Sales_Channel__c)) {
                        con.Sales_Channel__c = acc.Sales_Channel__c;
                    }
                }
            }
        }
    }

    public static void handleBeforeUpdate(List<Contact> newContacts, Map<Id, Contact> oldMap) {
        ContactTriggerHelper.removeSymbolsFromTaxId(newContacts);
    }

    public static void handleAfterInsert(List<Contact> newContacts) {
        List<Contact> validContacts = ContactTriggerHelper.validateAndCleanseNewContacts(newContacts);
        ContactTriggerHelper.assignContactToCompany(validContacts);
        ContactTriggerHelper.createStoreLocationNote(validContacts);
        
        // ── CHANGED: removed 'Key Accounts' exclusion — ALL channels now sync ──
        List<Id> contactIdsToInsert = new List<Id>();
        for (Contact con : newContacts) {
            if (String.isNotBlank(con.Email) && 
                String.isBlank(con.Shopify_Customer_Id__c) && 
                con.Manual_Approval_Status__c == 'Approved' &&
                con.Skip_Shopify_Sync__c != true) { // Create NetSuite records are not sent to Shopify
                contactIdsToInsert.add(con.Id);
            }
        }
        if (!contactIdsToInsert.isEmpty()) {
            System.enqueueJob(new ShopifyContactSyncQueueable(contactIdsToInsert));
        }

        // COMMENTED OUT: ClusterTeamEngine not yet deployed to prod
        // Uncomment when ClusterTeamEngine is ready for production deployment
        
        Set<Id> contactIds = new Set<Id>();
        for (Contact con : newContacts) {
            if (con.AccountId != null) {
                contactIds.add(con.Id);
            }
        }
        if (!contactIds.isEmpty()) {
            List<Contact> freshContacts = [
                SELECT Id, Cluster__c, Sales_Channel__c
                FROM Contact
                WHERE Id IN :contactIds
                AND Cluster__c != null
            ];
            if (!freshContacts.isEmpty()) {
                ClusterTeamEngine.assignTeams('Contact', freshContacts);
            }
        }
        
    }

    public static void handleAfterUpdate(List<Contact> newContacts, Map<Id, Contact> oldMap) {
        List<Contact> contactsToUpdate = new List<Contact>();
        List<Contact> contactsToDelete = new List<Contact>();
        List<Id> contactIdsForShopifySync = new List<Id>();

        for (Contact newCon : newContacts) {
            Contact oldCon = oldMap.get(newCon.Id);
            if (newCon.Annual_Revenue__c != oldCon.Annual_Revenue__c) {
                Contact updatedCon = new Contact(
                    Id = newCon.Id,
                    Revenue_Changed__c = true
                );
                contactsToUpdate.add(updatedCon);
            }

            // ── CHANGED: removed 'Key Accounts' exclusion — ALL channels now sync ──
            // ── Renamed to a named boolean, logic identical to before ──
            Boolean approvalJustHappened =
                oldCon.Manual_Approval_Status__c != 'Approved' &&
                newCon.Manual_Approval_Status__c == 'Approved' &&
                String.isNotBlank(newCon.Email) &&
                String.isBlank(newCon.Shopify_Customer_Id__c);

            // ── NEW: fires when a Contact is ALREADY Approved but never          ──
            // ── successfully synced (Shopify_Customer_Id__c still blank), and    ──
            // ── Phone or Email was just corrected. This is what makes "fix the    ──
            // ── invalid phone, then it auto-syncs" work, instead of requiring a   ──
            // ── manual ShopifyContactIntegration.sendToShopify() call every time  ──
            // ── a sync failure (e.g. "Phone is invalid", "Phone has already been  ──
            // ── taken") gets corrected.                                          ──
            Boolean correctionRetryNeeded =
                newCon.Manual_Approval_Status__c == 'Approved' &&
                String.isBlank(newCon.Shopify_Customer_Id__c) &&
                String.isNotBlank(newCon.Email) &&
                (newCon.Phone != oldCon.Phone || newCon.Email != oldCon.Email);

            if ((approvalJustHappened || correctionRetryNeeded) && newCon.Skip_Shopify_Sync__c != true) { // Create NetSuite records are not sent to Shopify
                contactIdsForShopifySync.add(newCon.Id);
            }

            if (oldCon.Manual_Approval_Status__c != 'Rejected' &&
                newCon.Manual_Approval_Status__c == 'Rejected') {
                contactsToDelete.add(newCon);
            }
        }
        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
        if (!contactIdsForShopifySync.isEmpty()) {
            System.enqueueJob(new ShopifyContactSyncQueueable(contactIdsForShopifySync));
            String jobName = 'ShopifyAssociationDelay_' + System.now().getTime();
            DateTime dt = System.now().addMinutes(1);
            String cron = dt.second() + ' ' + dt.minute() + ' ' + dt.hour() + ' '
                        + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
            System.schedule(jobName, cron,
                new ShopifyAssociationSyncSchedulable(contactIdsForShopifySync));
        }
        if (!contactsToDelete.isEmpty()) {
            ContactTriggerHelper.handleRejectedContacts(contactsToDelete);
        }

        Set<Id> changedIds = new Set<Id>();
        for (Contact con : newContacts) {
            Contact old = oldMap.get(con.Id);
            if (con.Cluster__c != old.Cluster__c ||
                con.Sales_Channel__c != old.Sales_Channel__c) {
                changedIds.add(con.Id);
            }
        }
        if (!changedIds.isEmpty()) {
            List<Contact> freshContacts = [
                SELECT Id, Cluster__c, Sales_Channel__c
                FROM Contact
                WHERE Id IN :changedIds
                AND Cluster__c != null
            ];
            if (!freshContacts.isEmpty()) {
                ClusterTeamEngine.assignTeams('Contact', freshContacts);
            }
        }
        
    }
}