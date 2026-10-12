@isTest
public class APILoggerTest {

    @isTest
    static void testLogCalloutError() {
        Test.startTest();
        APILogger.logCalloutError(
            'Test Context',
            500,
            'Request',
            'Response',
            'Stack Trace',
            'a0X000000000001',
            'Error'
        );
        Test.stopTest();
        
        API_Log__c log = [SELECT Context__c, Status_Code__c, Stack_Trace__c, Related_Record_Id__c 
                          FROM API_Log__c WHERE Context__c = 'Test Context'];
        System.assertEquals(500, log.Status_Code__c);
        System.assertEquals('Stack Trace', log.Stack_Trace__c);
        System.assertEquals('a0X000000000001', log.Related_Record_Id__c);
    }
    
    @isTest
    static void testLogCalloutError_NullValues() {
        Test.startTest();
        APILogger.logCalloutError('Minimal', 200, 'Req', 'Res', null, null, 'Success');
        Test.stopTest();
        
        API_Log__c log = [SELECT Stack_Trace__c, Related_Record_Id__c FROM API_Log__c WHERE Context__c = 'Minimal'];
        System.assertEquals(null, log.Stack_Trace__c);
        System.assertEquals(null, log.Related_Record_Id__c);
    }
    
    @isTest
    static void testCreateLog() {
        Test.startTest();
        API_Log__c log = APILogger.createLog('Create', 201, 'Req', 'Res', 'Stack', 'a0X000000000002', 'Info');
        Test.stopTest();
        
        System.assertEquals('Create', log.Context__c);
        System.assertEquals(201, log.Status_Code__c);
        
        System.assertEquals(0, [SELECT COUNT() FROM API_Log__c WHERE Context__c = 'Create']);
    }
    
    // ── FIXED: Test.setCreatedDate() does NOT survive the @testSetup save-point   ──
    // ── replay — @testSetup only replays the DML records themselves before each   ──
    // ── @isTest method runs, not out-of-band field edits like setCreatedDate().   ──
    // ── That meant every test method saw all 80 logs with today's CreatedDate,    ──
    // ── so the batch's "CreatedDate < cutoff" query matched nothing and deleted   ──
    // ── 0 rows (confirmed by "Actual: 50" i.e. none deleted). Fix: create the     ──
    // ── records and call Test.setCreatedDate() directly inside this test method,  ──
    // ── which IS part of this method's own transaction and is honored correctly.  ──
    // ── CHANGED: retention window updated to match APILogCleanupBatch's new       ──
    // ── 6-month cutoff (was 90 days). Old logs are backdated to just past 6       ──
    // ── months ago so they're unambiguously outside the retention window.        ──
    @isTest
    static void testBatchCleanup() {
        List<API_Log__c> oldLogs = new List<API_Log__c>();
        for (Integer i = 0; i < 50; i++) {
            oldLogs.add(new API_Log__c(
                Context__c = 'Old Log ' + i,
                Status_Code__c = 500,
                Log_Type__c = 'Error'
            ));
        }
        insert oldLogs;

        List<API_Log__c> newLogs = new List<API_Log__c>();
        for (Integer i = 0; i < 30; i++) {
            newLogs.add(new API_Log__c(
                Context__c = 'New Log ' + i,
                Status_Code__c = 200,
                Log_Type__c = 'Success'
            ));
        }
        insert newLogs;

        for (API_Log__c log : oldLogs) {
            Test.setCreatedDate(log.Id, DateTime.now().addMonths(-6).addDays(-1));
        }

        // ── DIAGNOSTIC: directly verify the backdate took effect BEFORE running   ──
        // ── the batch. If this assertion itself fails, the problem is with        ──
        // ── Test.setCreatedDate() not taking effect in this environment/context — ──
        // ── not with the batch's query or delete logic.                          ──
        API_Log__c checkLog = [SELECT CreatedDate FROM API_Log__c WHERE Id = :oldLogs[0].Id];
        System.debug('Backdated CreatedDate check: ' + checkLog.CreatedDate);
        System.assert(
            checkLog.CreatedDate < DateTime.now().addMonths(-5),
            'Test.setCreatedDate did not backdate this record as expected. Actual CreatedDate: ' + checkLog.CreatedDate
        );

        Integer oldLogsBeforeCleanup = [SELECT COUNT() FROM API_Log__c WHERE Context__c LIKE 'Old Log%'];
        Integer newLogsBeforeCleanup = [SELECT COUNT() FROM API_Log__c WHERE Context__c LIKE 'New Log%'];
        System.assertEquals(50, oldLogsBeforeCleanup, 'Setup should have created 50 old logs');
        System.assertEquals(30, newLogsBeforeCleanup, 'Setup should have created 30 new logs');

        Test.startTest();
        Database.executeBatch(new APILogCleanupBatch(), 200);
        Test.stopTest();

        Integer oldLogsAfterCleanup = [SELECT COUNT() FROM API_Log__c WHERE Context__c LIKE 'Old Log%'];
        Integer newLogsAfterCleanup = [SELECT COUNT() FROM API_Log__c WHERE Context__c LIKE 'New Log%'];

        System.assertEquals(0, oldLogsAfterCleanup, 'All old logs (>6 months) should have been deleted');
        System.assertEquals(30, newLogsAfterCleanup, 'New logs should remain untouched');
    }
    
  
  @isTest
static void testScheduleDailyJob() {

    // Abort any existing scheduled job with the same name
    for (CronTrigger ct : [
        SELECT Id
        FROM CronTrigger
        WHERE CronJobDetail.Name = 'API Error Log Cleanup'
    ]) {
        System.abortJob(ct.Id);
    }

    Test.startTest();
    APILogCleanupBatch.scheduleDailyJob();
    Test.stopTest();

    CronTrigger job = [
        SELECT CronExpression
        FROM CronTrigger
        WHERE CronJobDetail.Name = 'API Error Log Cleanup'
        LIMIT 1
    ];

    System.assertEquals('0 0 2 * * ?', job.CronExpression);
}

    // ── Covers ApiLogTriggerHandler.handleAfterInsert() — confirms the             ──
    // ── Case-creation deactivation is working and API_Log__c insertion is         ──
    // ── completely unaffected by it.                                             ──
    @isTest
    static void testApiLogTriggerHandlerDoesNotCreateCases() {
        Test.startTest();
        insert new API_Log__c(
            Context__c     = 'Trigger Handler Test - No Case Expected',
            Status_Code__c = 500,
            Log_Type__c    = 'API Errors',
            Stack_Trace__c = 'Unauthorized'
        );
        Test.stopTest();

        API_Log__c savedLog = [
            SELECT Context__c, Status_Code__c
            FROM API_Log__c
            WHERE Context__c = 'Trigger Handler Test - No Case Expected'
        ];
        System.assertEquals(500, savedLog.Status_Code__c, 'API_Log__c record should still be created normally');

        Integer caseCount = [SELECT COUNT() FROM Case WHERE Subject LIKE 'Shopify Integration Failure%'];
        System.assertEquals(0, caseCount, 'No Case should be created since Case creation is disabled');
    }

    // ── Bulk-insert variant, and a direct call to handleAfterInsert() to           ──
    // ── guarantee the single reachable line is covered regardless of trigger      ──
    // ── timing.                                                                   ──
    @isTest
    static void testApiLogTriggerHandlerBulkAndDirectCall() {
        List<API_Log__c> bulkLogs = new List<API_Log__c>();
        for (Integer i = 0; i < 20; i++) {
            bulkLogs.add(new API_Log__c(
                Context__c     = 'Bulk Trigger Test Log ' + i,
                Status_Code__c = 500,
                Log_Type__c    = 'API Errors'
            ));
        }

        Test.startTest();
        insert bulkLogs;
        // ── Direct call as well, to guarantee coverage independent of trigger context ──
        ApiLogTriggerHandler.handleAfterInsert(bulkLogs);
        Test.stopTest();

        Integer caseCount = [SELECT COUNT() FROM Case WHERE Subject LIKE 'Shopify Integration Failure%'];
        System.assertEquals(0, caseCount, 'No Cases should be created from bulk insert or direct call');
    }
}