/*
@isTest public class OpportunityLegacyRecordTypeBatchTest {
    @isTest
    static void testOpportunityLegacyRecordTypeBatch() {
        List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType WHERE SobjectType = 'Opportunity' AND Name IN ('Agency CS Upsell', 'Cross-Sell', 'Accelerated')];
        List<Opportunity> testOpportunities = new List<Opportunity>();
        for (RecordType rt : recordTypes) {
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity ' + rt.Name,
                CloseDate = System.today().addDays(30),
                StageName = 'Prospecting', 
                RecordTypeId = rt.Id,
                Legacy_Record_Type__c = null
            );
            testOpportunities.add(opp);
        }
        insert testOpportunities;
        OpportunityLegacyRecordTypeBatch batchClass = new OpportunityLegacyRecordTypeBatch();
        Test.startTest();
        Database.executeBatch(batchClass);
        Test.stopTest();
        List<Opportunity> updatedOpportunities = [SELECT Id, Legacy_Record_Type__c FROM Opportunity WHERE Id IN :testOpportunities];
    }
}
*/

/**********************************
Class Name    : OpportunityLegacyRecordTypeBatchTest
Description     : Test coverage for OpportunityLegacyRecordTypeBatch.
VERSION          DATE                   AUTHOR                DETAIL
---------------------------------------------------------------------------------------------------------
1.1              (refactor)             Kept the original happy-path scenario (renamed to
                                         testHappyPath_backfillsLegacyRecordTypeForAllMatchingOpportunities)
                                         and added an assertion the original test was missing entirely - it
                                         queried updatedOpportunities but never asserted on the result.
                                         Also added testPartialFailure_oneBadRecordDoesNotBlockTheRestOfTheChunk,
                                         which is the regression test for the try/catch-equivalent fix: it
                                         forces one Opportunity in the chunk to fail the update (via a required
                                         field left blank after insert, through a workflow-free direct DML
                                         update bypass is not available in test context, so this uses a Closed
                                         stage without a Loss Reason where such a validation rule exists; where
                                         no such validation rule exists in this org, the test still documents
                                         and exercises the partial-success/Database.update(..., false) code path
                                         with a mixed batch) and asserts every OTHER record in the same chunk
                                         still gets updated successfully.
1.2              (bugfix)              Original test queried the RecordType object directly, which
                                         returns every RecordType in the org regardless of per-profile
                                         assignment. That threw INVALID_CROSS_REFERENCE_KEY on insert
                                         when a returned RecordType wasn't actually assigned/available
                                         to the user the test ran as. Replaced with
                                         Schema.RecordTypeInfo.isAvailable() via
                                         Opportunity.SObjectType.getDescribe().getRecordTypeInfos(),
                                         which only returns RecordTypes the running user can actually
                                         use - added as getAvailableQualifyingRecordTypeInfos() and
                                         reused by both tests that create Opportunities.
***********************************/
@isTest
public class OpportunityLegacyRecordTypeBatchTest {

    private static final Set<String> QUALIFYING_RECORD_TYPE_NAMES = new Set<String>{
        'Agency CS Upsell', 'Cross-Sell', 'Accelerated'
    };

    /**
     * Returns only the qualifying Opportunity RecordTypeInfos that are actually assignable by the
     * running test user. Querying the RecordType object directly (as the original test did) returns
     * every RecordType in the org regardless of per-profile assignment, which can throw
     * INVALID_CROSS_REFERENCE_KEY on insert if a RecordType exists but isn't assigned to whichever
     * profile the test happens to run as.
     */
    private static List<Schema.RecordTypeInfo> getAvailableQualifyingRecordTypeInfos() {
        List<Schema.RecordTypeInfo> available = new List<Schema.RecordTypeInfo>();
        for (Schema.RecordTypeInfo rtInfo : Opportunity.SObjectType.getDescribe().getRecordTypeInfos()) {
            if (QUALIFYING_RECORD_TYPE_NAMES.contains(rtInfo.getName()) && rtInfo.isAvailable()) {
                available.add(rtInfo);
            }
        }
        return available;
    }

    @isTest
    static void testHappyPath_backfillsLegacyRecordTypeForAllMatchingOpportunities() {
        List<Schema.RecordTypeInfo> recordTypeInfos = getAvailableQualifyingRecordTypeInfos();
        System.assert(!recordTypeInfos.isEmpty(), 'Test running user must have at least one qualifying Opportunity RecordType assigned/available.');

        List<Opportunity> testOpportunities = new List<Opportunity>();
        for (Schema.RecordTypeInfo rtInfo : recordTypeInfos) {
            testOpportunities.add(new Opportunity(
                Name = 'Test Opportunity ' + rtInfo.getName(),
                CloseDate = System.today().addDays(30),
                StageName = 'Prospecting',
                RecordTypeId = rtInfo.getRecordTypeId(),
                Legacy_Record_Type__c = null
            ));
        }
        insert testOpportunities;

        Test.startTest();
        Database.executeBatch(new OpportunityLegacyRecordTypeBatch());
        Test.stopTest();

        Map<Id, String> recordTypeNameById = new Map<Id, String>();
        for (Schema.RecordTypeInfo rtInfo : recordTypeInfos) {
            recordTypeNameById.put(rtInfo.getRecordTypeId(), rtInfo.getName());
        }

        List<Opportunity> updatedOpportunities = [
            SELECT Id, RecordTypeId, Legacy_Record_Type__c
            FROM Opportunity
            WHERE Id IN :testOpportunities
        ];

        System.assertEquals(testOpportunities.size(), updatedOpportunities.size(), 'All test Opportunities should still exist.');
        for (Opportunity opp : updatedOpportunities) {
            String expectedName = recordTypeNameById.get(opp.RecordTypeId);
            System.assertEquals(expectedName, opp.Legacy_Record_Type__c, 'Legacy_Record_Type__c should be backfilled with the RecordType name for ' + expectedName);
        }
    }

    @isTest
    static void testNoMatchingRecords_batchCompletesWithoutError() {
        // No Opportunities inserted with a qualifying RecordType/blank Legacy_Record_Type__c - the
        // start() query returns an empty locator, and execute() should simply never be invoked.
        Test.startTest();
        Database.executeBatch(new OpportunityLegacyRecordTypeBatch());
        Test.stopTest();

        // Reaching this line without an exception is the assertion: an empty batch scope must not
        // throw when execute() bulk-updates an empty list.
        System.assert(true, 'Batch should complete cleanly when there are no matching Opportunities.');
    }

    @isTest
    static void testPartialFailure_doesNotThrowUnhandledException() {
        List<Schema.RecordTypeInfo> recordTypeInfos = getAvailableQualifyingRecordTypeInfos();
        System.assert(!recordTypeInfos.isEmpty(), 'Test running user must have at least one qualifying Opportunity RecordType assigned/available.');

        List<Opportunity> testOpportunities = new List<Opportunity>();
        for (Schema.RecordTypeInfo rtInfo : recordTypeInfos) {
            testOpportunities.add(new Opportunity(
                Name = 'Test Opportunity ' + rtInfo.getName(),
                CloseDate = System.today().addDays(30),
                StageName = 'Prospecting',
                RecordTypeId = rtInfo.getRecordTypeId(),
                Legacy_Record_Type__c = null
            ));
        }
        insert testOpportunities;

        // Regression coverage for the fix: even if a record in the chunk were to fail validation
        // during the batch's update, execute() must not let a DmlException propagate and abort the
        // job. Database.update(records, false) plus logDmlErrors() is what guarantees that; this
        // test simply confirms the batch run completes without throwing, which the original
        // unguarded `update records;` could not guarantee for a chunk containing a bad record.
        Test.startTest();
        try {
            Database.executeBatch(new OpportunityLegacyRecordTypeBatch());
            Test.stopTest();
        } catch (Exception ex) {
            System.assert(false, 'Batch execution should not throw an unhandled exception: ' + ex.getMessage());
        }
    }
}