public class ProgramBundleAssociationTriggerHandler {

    private static final String API_USER_ALIAS_PATTERN = 'ApiUser';

    // TEST-ONLY HOOK: lets test classes simulate "last modified by ApiUser" without needing
    // to create/activate/reuse a real User record with Alias = 'ApiUser' (which in this org
    // keeps hitting duplicate-alias validation rules and managed-package activation triggers).
    // Only takes effect when Test.isRunningTest() is true, so production behavior is unchanged.
    @TestVisible
    private static Set<Id> testOverrideApiUserIds = null;

    // ==========================================================================================
    // AFTER INSERT - covers the case where NetSuite_Bundle_Association_ID__c is ALREADY
    // populated at creation time.
    // ==========================================================================================
    public static void handleAfterInsert(List<Program_Bundle_Associations__c> newRecords) {

        System.debug('===== ProgramBundleAssociationTriggerHandler (AFTER INSERT) START =====');
        System.debug('Total records in Trigger.new: ' + newRecords.size());

        List<Program_Bundle_Associations__c> relevantRecords = new List<Program_Bundle_Associations__c>();

        for (Program_Bundle_Associations__c pba : newRecords) {
            System.debug('--- Processing PBA record Id: ' + pba.Id + ' | LastModifiedById: ' + pba.LastModifiedById + ' ---');
            System.debug('NetSuite_Bundle_Association_ID__c at creation: ' + pba.NetSuite_Bundle_Association_ID__c);

            // Step 1: NetSuite_Bundle_Association_ID__c must be populated
            if (String.isNotBlank(pba.NetSuite_Bundle_Association_ID__c)) {
                System.debug('PBA Id ' + pba.Id + ' qualifies on Step 1 (NetSuite Id populated at creation).');
                relevantRecords.add(pba);
            } else {
                System.debug('Skipping PBA Id ' + pba.Id + ' - NetSuite_Bundle_Association_ID__c is blank at creation.');
            }
        }

        processQualifyingRecords(relevantRecords);

        System.debug('===== ProgramBundleAssociationTriggerHandler (AFTER INSERT) END =====');
    }

    // ==========================================================================================
    // AFTER UPDATE - covers the case where NetSuite_Bundle_Association_ID__c changes
    // (blank -> populated) in a later update.
    // ==========================================================================================
    public static void handleAfterUpdate(List<Program_Bundle_Associations__c> newRecords, Map<Id, Program_Bundle_Associations__c> oldMap) {

        System.debug('===== ProgramBundleAssociationTriggerHandler (AFTER UPDATE) START =====');
        System.debug('Total records in Trigger.new: ' + newRecords.size());

        List<Program_Bundle_Associations__c> relevantRecords = new List<Program_Bundle_Associations__c>();

        for (Program_Bundle_Associations__c pba : newRecords) {
            Program_Bundle_Associations__c oldPba = oldMap.get(pba.Id);

            String oldNetSuiteId = oldPba.NetSuite_Bundle_Association_ID__c;
            String newNetSuiteId = pba.NetSuite_Bundle_Association_ID__c;

            System.debug('--- Processing PBA record Id: ' + pba.Id + ' | LastModifiedById: ' + pba.LastModifiedById + ' ---');
            System.debug('Old NetSuite_Bundle_Association_ID__c: ' + oldNetSuiteId + ' | New: ' + newNetSuiteId);

            // Step 1: NetSuite_Bundle_Association_ID__c must have changed to populated
            Boolean fieldChanged = oldNetSuiteId != newNetSuiteId && String.isNotBlank(newNetSuiteId);

            if (fieldChanged) {
                System.debug('PBA Id ' + pba.Id + ' qualifies on Step 1 (NetSuite Id changed to populated).');
                relevantRecords.add(pba);
            } else {
                System.debug('Skipping PBA Id ' + pba.Id + ' - NetSuite_Bundle_Association_ID__c did not change to a populated value.');
            }
        }

        processQualifyingRecords(relevantRecords);

        System.debug('===== ProgramBundleAssociationTriggerHandler (AFTER UPDATE) END =====');
    }

    // ==========================================================================================
    // SHARED LOGIC - applied to records that already passed Step 1 (NetSuite Id changed/populated):
    //   Step 2: Event_Trigger__c must be true on the parent Bundle - UNLESS this is the first
    //           Program_Bundle_Associations__c ever created for that Bundle, which skips this check.
    //   Step 3: the record's LastModifiedById must be the User whose Alias = 'ApiUser'.
    //   Step 4: fire the platform event (and reset Event_Trigger__c when it was the deciding factor).
    // ==========================================================================================
    private static void processQualifyingRecords(List<Program_Bundle_Associations__c> relevantRecords) {

        System.debug('Total records passing Step 1: ' + relevantRecords.size());

        if (relevantRecords.isEmpty()) {
            System.debug('No records passed Step 1. Exiting.');
            return;
        }

        // Step 3 setup: find the Ids of all Users whose Alias matches 'ApiUser'
        Set<Id> apiUserIds = getApiUserIds();
        System.debug('ApiUser Ids resolved to: ' + apiUserIds);

        if (apiUserIds.isEmpty()) {
            System.debug('No User found with Alias LIKE ' + API_USER_ALIAS_PATTERN + ' - no records can qualify. Exiting.');
            return;
        }

        Set<Id> bundleIds = new Set<Id>();
        for (Program_Bundle_Associations__c pba : relevantRecords) {
            if (pba.Bundle__c != null) {
                bundleIds.add(pba.Bundle__c);
            }
        }

        if (bundleIds.isEmpty()) {
            System.debug('No parent Bundle Ids found on relevant records. Exiting.');
            return;
        }

        // Step 2 setup: bulk query parent ProductBundles__c to check Event_Trigger__c
        Map<Id, ProductBundles__c> bundleMap = new Map<Id, ProductBundles__c>([
            SELECT Id, Event_Trigger__c
            FROM ProductBundles__c
            WHERE Id IN :bundleIds
        ]);

        for (Id bId : bundleMap.keySet()) {
            System.debug('ProductBundles__c Id: ' + bId + ' | Event_Trigger__c: ' + bundleMap.get(bId).Event_Trigger__c);
        }

        // Step 2 setup: count total associations per bundle, to detect the "first record" exception
        Map<Id, Integer> bundleAssociationCounts = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Bundle__c bundleId, COUNT(Id) totalCount
            FROM Program_Bundle_Associations__c
            WHERE Bundle__c IN :bundleIds
            GROUP BY Bundle__c
        ]) {
            Id bId = (Id) ar.get('bundleId');
            Integer cnt = (Integer) ar.get('totalCount');
            bundleAssociationCounts.put(bId, cnt);
            System.debug('Bundle Id: ' + bId + ' | Total Program_Bundle_Associations__c count: ' + cnt);
        }

        List<sfdc_bundle_updated__e> eventsToPublish = new List<sfdc_bundle_updated__e>();
        Set<Id> bundleIdsToReset = new Set<Id>();

        for (Program_Bundle_Associations__c pba : relevantRecords) {

            // Step 3: must have been last modified by one of the ApiUser Ids
            if (!apiUserIds.contains(pba.LastModifiedById)) {
                System.debug('Skipping PBA Id ' + pba.Id + ' - LastModifiedById (' + pba.LastModifiedById + ') is not in the ApiUser Ids (' + apiUserIds + ').');
                continue;
            }

            if (pba.Bundle__c == null) {
                System.debug('Skipping PBA Id ' + pba.Id + ' - Bundle__c is null');
                continue;
            }

            ProductBundles__c parentBundle = bundleMap.get(pba.Bundle__c);

            if (parentBundle == null) {
                System.debug('Skipping PBA Id ' + pba.Id + ' - parent ProductBundles__c not found for Bundle__c: ' + pba.Bundle__c);
                continue;
            }

            Integer totalAssociationsForBundle = bundleAssociationCounts.get(parentBundle.Id);
            Boolean isFirstAssociationForBundle = (totalAssociationsForBundle != null && totalAssociationsForBundle == 1);

            System.debug('PBA Id ' + pba.Id + ' -> Parent Bundle ' + parentBundle.Id
                + ' | Total associations on bundle: ' + totalAssociationsForBundle
                + ' | isFirstAssociationForBundle: ' + isFirstAssociationForBundle
                + ' | Event_Trigger__c = ' + parentBundle.Event_Trigger__c);

            // Step 2: Event_Trigger__c must be true, UNLESS this is the first association on the bundle
            Boolean shouldPublish = isFirstAssociationForBundle || parentBundle.Event_Trigger__c == true;

            if (!shouldPublish) {
                System.debug('Skipping PBA Id ' + pba.Id + ' - not first association and Event_Trigger__c is false/null.');
                continue;
            }

            // Step 4: build and queue the event
            sfdc_bundle_updated__e evt = new sfdc_bundle_updated__e(
                Record_Id__c                      = pba.Id,
                Marketing_Reward_Id__c             = pba.Marketing_Reward__c,
                Program_Name__c                    = pba.Program_Name__c,
                Bundle_Id__c                       = pba.Bundle__c,
                Bundle_Type__c                     = pba.Bundle_Type__c,
                Effective_Date__c                  = pba.Effective_Date__c,
                End_Date__c                        = pba.End_Date__c,
                Active__c                          = pba.Active__c,
                NetSuite_Item_ID__c                = pba.NetSuite_Item_ID__c,
                NetSuite_Bundle_Association_ID__c  = pba.NetSuite_Bundle_Association_ID__c
            );

            System.debug('Built platform event payload for PBA Id ' + pba.Id
                + ' (reason: ' + (isFirstAssociationForBundle ? 'FIRST association on bundle - skipping checkbox check' : 'Event_Trigger__c = true') + '): ' + evt);
            System.debug('Payload as JSON: ' + JSON.serializePretty(evt));

            eventsToPublish.add(evt);

            if (!isFirstAssociationForBundle) {
                bundleIdsToReset.add(parentBundle.Id);
            }
        }

        System.debug('Total events built for publishing: ' + eventsToPublish.size());
        System.debug('Bundle Ids marked for Event_Trigger__c reset: ' + bundleIdsToReset);

        if (!eventsToPublish.isEmpty()) {

            System.debug('Publishing events now. Full list: ' + eventsToPublish);
            System.debug('Full payload list as JSON: ' + JSON.serializePretty(eventsToPublish));

            List<Database.SaveResult> results = EventBus.publish(eventsToPublish);

            System.debug('EventBus.publish returned ' + results.size() + ' SaveResult(s)');

            for (Integer i = 0; i < results.size(); i++) {
                Database.SaveResult sr = results[i];
                System.debug('--- SaveResult[' + i + '] ---');
                System.debug('Corresponding payload: ' + JSON.serializePretty(eventsToPublish[i]));
                System.debug('isSuccess: ' + sr.isSuccess());

                if (sr.isSuccess()) {
                    System.debug('Event published successfully. Check EventBus/Debug log EVENT_SERVICE_PUB entries for Replay ID.');
                } else {
                    for (Database.Error err : sr.getErrors()) {
                        System.debug(LoggingLevel.ERROR,
                            'PUBLISH FAILED - StatusCode: ' + err.getStatusCode()
                            + ' | Message: ' + err.getMessage()
                            + ' | Fields: ' + err.getFields());
                    }
                }
            }

            // Reset Event_Trigger__c to false on parent bundles whose event was built via the checkbox path
            if (!bundleIdsToReset.isEmpty()) {
                List<ProductBundles__c> bundlesToUpdate = new List<ProductBundles__c>();
                for (Id bId : bundleIdsToReset) {
                    bundlesToUpdate.add(new ProductBundles__c(
                        Id = bId,
                        Event_Trigger__c = false
                    ));
                }

                System.debug('Resetting Event_Trigger__c = false on: ' + bundlesToUpdate);

                List<Database.SaveResult> updateResults = Database.update(bundlesToUpdate, false);

                for (Integer i = 0; i < updateResults.size(); i++) {
                    Database.SaveResult ur = updateResults[i];
                    System.debug('--- Update SaveResult[' + i + '] for Bundle Id: ' + bundlesToUpdate[i].Id + ' ---');
                    System.debug('isSuccess: ' + ur.isSuccess());

                    if (!ur.isSuccess()) {
                        for (Database.Error err : ur.getErrors()) {
                            System.debug(LoggingLevel.ERROR,
                                'RESET FAILED - StatusCode: ' + err.getStatusCode()
                                + ' | Message: ' + err.getMessage()
                                + ' | Fields: ' + err.getFields());
                        }
                    } else {
                        System.debug('Event_Trigger__c successfully reset to false for Bundle Id: ' + bundlesToUpdate[i].Id);
                    }
                }
            }
        } else {
            System.debug('No events to publish - eventsToPublish list is empty.');
        }
    }

    // Step 3 helper: resolve the Ids of all Users whose Alias matches 'ApiUser' (LIKE, no LIMIT,
    // so if more than one user shares/collides on this alias, all of them are captured - the
    // membership check downstream still correctly matches whichever one actually made the change).
    private static Set<Id> getApiUserIds() {

        if (Test.isRunningTest() && testOverrideApiUserIds != null) {
            return testOverrideApiUserIds;
        }

        Set<Id> apiUserIds = new Set<Id>();

        for (User u : [
            SELECT Id
            FROM User
            WHERE Alias LIKE :API_USER_ALIAS_PATTERN
        ]) {
            apiUserIds.add(u.Id);
        }

        if (apiUserIds.isEmpty()) {
            System.debug('No User found with Alias LIKE ' + API_USER_ALIAS_PATTERN);
        }

        return apiUserIds;
    }
}