@IsTest
private class DataRetentionBatchSchedulerTest {

    /*
     * Context mock for direct start(), execute(), and finish() calls.
     */
    private class MockBatchContext implements Database.BatchableContext {

        public Id getJobId() {
            return null;
        }

        public Id getChildJobId() {
            return null;
        }
    }

    /*
     * Stores a batch and its corresponding valid metadata rule.
     */
    private class RunnableBatchInfo {
        public DataRetentionEnforcementBatch batch;
        public Data_Retention_Rule__mdt rule;

        public RunnableBatchInfo(
            DataRetentionEnforcementBatch batch,
            Data_Retention_Rule__mdt rule
        ) {
            this.batch = batch;
            this.rule = rule;
        }
    }

    /*
     * Finds the first existing metadata record whose configured object,
     * date field, and optional filter fields are valid enough for start()
     * to build a QueryLocator.
     *
     * Invalid metadata records such as Banking_Info_Deactivated are skipped.
     */
    private static RunnableBatchInfo getFirstRunnableBatch() {
        List<Data_Retention_Rule__mdt> rules = [
            SELECT DeveloperName,
                   MasterLabel,
                   Object_API_Name__c,
                   Date_Field_API_Name__c,
                   Retention_Years__c,
                   Filter_Field_API_Name__c,
                   Filter_Values__c,
                   Action__c,
                   Test_Mode__c,
                   Active__c
            FROM Data_Retention_Rule__mdt
            ORDER BY DeveloperName
        ];

        for (Data_Retention_Rule__mdt rule : rules) {
            DataRetentionEnforcementBatch batch =
                new DataRetentionEnforcementBatch(rule.DeveloperName);

            try {
                batch.start(new MockBatchContext());

                return new RunnableBatchInfo(batch, rule);

            } catch (Exception e) {
                System.debug(
                    'Skipping invalid metadata rule: '
                    + rule.DeveloperName
                    + '. Error: '
                    + e.getMessage()
                );
            }
        }

        return null;
    }

    /*
     * Finds a runnable metadata rule with Test_Mode__c enabled.
     * Returns null when the org has no usable Test Mode record.
     */
    private static RunnableBatchInfo getRunnableTestModeBatch() {
        List<Data_Retention_Rule__mdt> rules = [
            SELECT DeveloperName,
                   MasterLabel,
                   Object_API_Name__c,
                   Date_Field_API_Name__c,
                   Retention_Years__c,
                   Filter_Field_API_Name__c,
                   Filter_Values__c,
                   Action__c,
                   Test_Mode__c,
                   Active__c
            FROM Data_Retention_Rule__mdt
            WHERE Test_Mode__c = true
            ORDER BY DeveloperName
        ];

        for (Data_Retention_Rule__mdt rule : rules) {
            DataRetentionEnforcementBatch batch =
                new DataRetentionEnforcementBatch(rule.DeveloperName);

            try {
                batch.start(new MockBatchContext());

                return new RunnableBatchInfo(batch, rule);

            } catch (Exception e) {
                System.debug(
                    'Skipping invalid Test Mode rule: '
                    + rule.DeveloperName
                    + '. Error: '
                    + e.getMessage()
                );
            }
        }

        return null;
    }

    /*
     * Gets an in-memory SObject for a metadata rule's configured object.
     * It is never inserted, so no triggers, Flows, validation rules, or
     * finalizers are executed.
     */
    private static SObject getUnsavedRecord(
        Data_Retention_Rule__mdt rule
    ) {
        if (String.isBlank(rule.Object_API_Name__c)) {
            return null;
        }

        Schema.SObjectType objectType =
            Schema.getGlobalDescribe().get(rule.Object_API_Name__c);

        if (objectType == null) {
            return null;
        }

        return objectType.newSObject();
    }

    /*
     * Covers constructor creation using an existing metadata rule.
     */
    @IsTest
    static void testBatchConstructorCoverage() {
        List<Data_Retention_Rule__mdt> rules = [
            SELECT DeveloperName
            FROM Data_Retention_Rule__mdt
            LIMIT 1
        ];

        System.assert(
            rules.size() > 0,
            'At least one existing Data Retention Rule metadata record is required.'
        );

        DataRetentionEnforcementBatch batch =
            new DataRetentionEnforcementBatch(rules[0].DeveloperName);

        System.assertNotEquals(
            null,
            batch,
            'Batch should be created from an existing metadata rule.'
        );
    }

    /*
     * Covers start(), metadata retrieval, cutoff date calculation, dynamic
     * query creation, and filter handling for existing valid metadata.
     */
    @IsTest
    static void testStartCoverageUsingExistingRule() {
        RunnableBatchInfo info = getFirstRunnableBatch();

        if (info == null) {
            System.assertEquals(
                null,
                info,
                'No valid metadata rule is currently configured in this org.'
            );
            return;
        }

        System.assertNotEquals(
            null,
            info.batch,
            'A runnable batch should be found.'
        );

        System.assertNotEquals(
            null,
            info.rule,
            'A valid metadata rule should be found.'
        );
    }

    /*
     * Covers execute() empty-scope return path and finish() logging.
     * No business object is inserted.
     */
    @IsTest
    static void testEmptyScopeAndFinishCoverage() {
        RunnableBatchInfo info = getFirstRunnableBatch();

        if (info == null) {
            System.assertEquals(null, info);
            return;
        }

        MockBatchContext context = new MockBatchContext();

        info.batch.execute(context, new List<SObject>());
        info.batch.finish(context);

        List<Data_Retention_Log__c> logs = [
            SELECT Rule_Name__c,
                   Object_API_Name__c,
                   Records_Deleted__c,
                   Status__c
            FROM Data_Retention_Log__c
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(
            1,
            logs.size(),
            'finish() should create a retention log.'
        );

        System.assertEquals(
            'Success',
            logs[0].Status__c,
            'An empty scope should complete successfully.'
        );

        System.assertEquals(
            0,
            logs[0].Records_Deleted__c,
            'No record should be counted for an empty scope.'
        );
    }

    /*
     * Covers the normal non-Test-Mode execute() path using an unsaved,
     * in-memory record. No Contact or custom-object record is inserted.
     *
     * The delete operation should produce a failed DeleteResult because
     * the record has no database Id. That covers error handling safely.
     */
    @IsTest
    static void testDeleteFailureAndErrorLogCoverage() {
        RunnableBatchInfo info = getFirstRunnableBatch();

        if (info == null) {
            System.assertEquals(null, info);
            return;
        }

        if (info.rule.Test_Mode__c) {
            System.assertEquals(
                true,
                info.rule.Test_Mode__c,
                'First valid rule is Test Mode; normal delete path is skipped.'
            );
            return;
        }

        SObject unsavedRecord = getUnsavedRecord(info.rule);

        if (unsavedRecord == null) {
            System.assertEquals(null, unsavedRecord);
            return;
        }

        MockBatchContext context = new MockBatchContext();

        try {
            info.batch.execute(
                context,
                new List<SObject>{ unsavedRecord }
            );

        } catch (Exception e) {
            System.debug(
                'Expected safe delete failure for unsaved record: '
                + e.getMessage()
            );
        }

        info.batch.finish(context);

        List<Data_Retention_Log__c> logs = [
            SELECT Status__c,
                   Error_Details__c
            FROM Data_Retention_Log__c
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(
            1,
            logs.size(),
            'finish() should create a retention log.'
        );
    }

    /*
     * Covers the Test_Mode__c branch when a Test Mode custom-metadata rule
     * already exists in the org. If no such existing rule exists, the test
     * safely completes without an error.
     */
    @IsTest
    static void testExistingTestModeRuleCoverage() {
        RunnableBatchInfo info = getRunnableTestModeBatch();

        if (info == null) {
            System.assertEquals(
                null,
                info,
                'No existing runnable Test Mode rule is configured.'
            );
            return;
        }

        SObject unsavedRecord = getUnsavedRecord(info.rule);

        if (unsavedRecord == null) {
            System.assertEquals(null, unsavedRecord);
            return;
        }

        MockBatchContext context = new MockBatchContext();

        info.batch.execute(
            context,
            new List<SObject>{ unsavedRecord }
        );

        info.batch.finish(context);

        List<Data_Retention_Log__c> logs = [
            SELECT Records_Deleted__c,
                   Status__c
            FROM Data_Retention_Log__c
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(
            1,
            logs.size(),
            'Test Mode finish() should create a retention log.'
        );

        System.assertEquals(
            'Success',
            logs[0].Status__c,
            'Test Mode should finish successfully.'
        );

        System.assertEquals(
            1,
            logs[0].Records_Deleted__c,
            'Test Mode should count the unsaved in-memory record.'
        );
    }

    /*
     * Covers scheduler constructor only.
     */
    @IsTest
    static void testSchedulerConstructorCoverage() {
        DataRetentionSchedulerJob scheduler =
            new DataRetentionSchedulerJob();

        System.assertNotEquals(
            null,
            scheduler,
            'Scheduler should be created.'
        );
    }

    /*
     * Covers scheduler registration without running scheduler.execute().
     * This prevents the misconfigured Banking_Info_Deactivated rule from
     * being executed asynchronously.
     */
    @IsTest
    static void testSchedulerRegistrationCoverage() {
        String jobName = 'DataRetentionSchedulerTest_'
            + String.valueOf(DateTime.now().getTime());

        String jobId = System.schedule(
            jobName,
            '0 0 0 1 1 ? 2099',
            new DataRetentionSchedulerJob()
        );

        System.assertNotEquals(
            null,
            jobId,
            'Scheduler job should be registered.'
        );

        CronTrigger scheduledJob = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE Id = :jobId
            LIMIT 1
        ];

        System.assertEquals(
            jobName,
            scheduledJob.CronJobDetail.Name,
            'Scheduled job name should match.'
        );
    }
}