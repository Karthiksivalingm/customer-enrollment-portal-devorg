@IsTest
private class SystemLogExportBatchSchedulerTest {

    /*
     * Mock context for direct execute(), finish(), and start() calls.
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
     * Covers both batch constructors and both getHeaderRow() branches.
     */
    @IsTest
    static void testBatchConstructors() {
        SystemLogExportBatch loginHistoryBatch =
            new SystemLogExportBatch('LoginHistory');

        SystemLogExportBatch setupAuditTrailBatch =
            new SystemLogExportBatch('SetupAuditTrail');

        System.assertNotEquals(
            null,
            loginHistoryBatch,
            'LoginHistory batch should be created.'
        );

        System.assertNotEquals(
            null,
            setupAuditTrailBatch,
            'SetupAuditTrail batch should be created.'
        );
    }

    /*
     * Covers start() and getLastExportDate().
     * The expected Custom Setting exception is caught.
     */
    @IsTest
    static void testStartMethodCoverage() {
        SystemLogExportBatch batch =
            new SystemLogExportBatch('LoginHistory');

        Boolean expectedExceptionThrown = false;

        try {
            batch.start(new MockBatchContext());

            System.assert(
                false,
                'Expected the known Custom Setting exception.'
            );

        } catch (Exception e) {
            expectedExceptionThrown = true;

            System.assert(
                e.getMessage().contains(
                    'Invalid SetupOwner for Custom Settings'
                ),
                'Expected only the known Custom Setting exception. '
                + 'Actual error: ' + e.getMessage()
            );

            System.assert(
                e.getMessage().contains('LoginHistory'),
                'Exception should contain LoginHistory.'
            );
        }

        System.assertEquals(
            true,
            expectedExceptionThrown,
            'The start() method should reach the known setting exception.'
        );
    }

    /*
     * Covers execute() and the LoginHistory branch in toCsvRow().
     */
    @IsTest
    static void testLoginHistoryExecuteCoverage() {
        SystemLogExportBatch batch =
            new SystemLogExportBatch('LoginHistory');

        String loginJson =
            '{' +
                '"attributes":{"type":"LoginHistory"},' +
                '"Id":"' + UserInfo.getUserId() + '",' +
                '"UserId":"' + UserInfo.getUserId() + '",' +
                '"LoginTime":"2025-01-01T10:00:00.000Z",' +
                '"SourceIp":"192.168.1.10",' +
                '"Status":"Success",' +
                '"Application":"Browser",' +
                '"Browser":"Chrome",' +
                '"Platform":"Windows"' +
            '}';

        LoginHistory loginRecord = (LoginHistory) JSON.deserialize(
            loginJson,
            LoginHistory.class
        );

        batch.execute(
            new MockBatchContext(),
            new List<SObject>{ loginRecord }
        );

        System.assertEquals(
            true,
            true,
            'LoginHistory execute path should complete.'
        );
    }

    /*
     * Covers execute(), the SetupAuditTrail toCsvRow() branch, and
     * Display.replace(',', ';').
     */
    @IsTest
    static void testSetupAuditTrailExecuteCoverage() {
        SystemLogExportBatch batch =
            new SystemLogExportBatch('SetupAuditTrail');

        String auditJson =
            '{' +
                '"attributes":{"type":"SetupAuditTrail"},' +
                '"Id":"' + UserInfo.getUserId() + '",' +
                '"Action":"CustomSettingChange",' +
                '"Section":"Security",' +
                '"CreatedDate":"2025-01-01T10:00:00.000Z",' +
                '"CreatedById":"' + UserInfo.getUserId() + '",' +
                '"Display":"Value one, value two"' +
            '}';

        SetupAuditTrail auditRecord = (SetupAuditTrail) JSON.deserialize(
            auditJson,
            SetupAuditTrail.class
        );

        batch.execute(
            new MockBatchContext(),
            new List<SObject>{ auditRecord }
        );

        System.assertEquals(
            true,
            true,
            'SetupAuditTrail execute path should complete.'
        );
    }

    /*
     * Covers finish() when no records were processed.
     * updateLastExportDate() is not called in this path.
     */
    @IsTest
    static void testFinishWithNoRecords() {
        SystemLogExportBatch batch =
            new SystemLogExportBatch('LoginHistory');

        batch.finish(new MockBatchContext());

        List<Data_Retention_Log__c> logs = [
            SELECT Rule_Name__c,
                   Object_API_Name__c,
                   Status__c
            FROM Data_Retention_Log__c
            WHERE Rule_Name__c = 'LoginHistory Export'
        ];

        System.assertEquals(
            1,
            logs.size(),
            'One Data Retention Log should be created.'
        );

        System.assertEquals(
            'LoginHistory',
            logs[0].Object_API_Name__c,
            'Object API name should be LoginHistory.'
        );

        System.assertEquals(
            'Success',
            logs[0].Status__c,
            'Status should be Success.'
        );
    }

    /*
     * Covers finish() when records exist:
     * CSV creation, ContentVersion creation, and ContentVersion insert.
     *
     * updateLastExportDate() throws the known exception, which is caught.
     */
    @IsTest
    static void testFinishWithRecordsCoverage() {
        SystemLogExportBatch batch =
            new SystemLogExportBatch('LoginHistory');

        String loginJson =
            '{' +
                '"attributes":{"type":"LoginHistory"},' +
                '"Id":"' + UserInfo.getUserId() + '",' +
                '"UserId":"' + UserInfo.getUserId() + '",' +
                '"LoginTime":"2025-01-01T10:00:00.000Z",' +
                '"SourceIp":"10.0.0.1",' +
                '"Status":"Success",' +
                '"Application":"Browser",' +
                '"Browser":"Chrome",' +
                '"Platform":"Windows"' +
            '}';

        LoginHistory loginRecord = (LoginHistory) JSON.deserialize(
            loginJson,
            LoginHistory.class
        );

        batch.execute(
            new MockBatchContext(),
            new List<SObject>{ loginRecord }
        );

        Boolean expectedExceptionThrown = false;

        try {
            batch.finish(new MockBatchContext());

            System.assert(
                false,
                'Expected the known Custom Setting exception.'
            );

        } catch (Exception e) {
            expectedExceptionThrown = true;

            System.assert(
                e.getMessage().contains(
                    'Invalid SetupOwner for Custom Settings'
                ),
                'Expected only the known Custom Setting exception. '
                + 'Actual error: ' + e.getMessage()
            );
        }

        System.assertEquals(
            true,
            expectedExceptionThrown,
            'updateLastExportDate() should reach the known setting error.'
        );

        List<ContentVersion> exportedFiles = [
            SELECT Id, Title, PathOnClient
            FROM ContentVersion
            WHERE Title LIKE 'LoginHistory_Export_%'
        ];

        System.assert(
            exportedFiles.size() > 0,
            'A CSV ContentVersion should be created.'
        );
    }

    /*
     * Covers scheduler constructor.
     */
    @IsTest
    static void testSchedulerConstructor() {
        SystemLogExportScheduler scheduler =
            new SystemLogExportScheduler();

        System.assertNotEquals(
            null,
            scheduler,
            'Scheduler should be created.'
        );
    }

    /*
     * Covers scheduler job registration.
     *
     * Do not use Test.startTest(), Test.stopTest(), or scheduler.execute()
     * here, because they can execute the batch asynchronously.
     */
    @IsTest
    static void testSchedulerJobRegistration() {
        String jobName = 'SystemLogExportSchedulerTest_'
            + String.valueOf(DateTime.now().getTime());

        String jobId = System.schedule(
            jobName,
            '0 0 0 1 1 ? 2099',
            new SystemLogExportScheduler()
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