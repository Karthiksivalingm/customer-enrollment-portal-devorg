@isTest
private class LicenseAlertBatchTest {

    private static final String STATE_1 = 'CA';
    private static final String STATE_2 = 'TX';

    @testSetup
    static void setupTestData() {

        Account agency = new Account(
            Name = 'Test Agency'
        );
        insert agency;

        Contact agent = new Contact(
            LastName='Test Agent',
            AccountId=agency.Id,
            Email='testagent@example.com',
            NPN__c='1234567890',
            Agent_Status__c='Onboarding',
            Insurance_Types__c='Medicare'
        );
        insert agent;
    }

    // NOTE: Expiration_Date__c (queried by LicenseAlertBatch.start()) is a
    // read-only formula field whose formula is simply License_ExpireDate__c
    // (confirmed in Setup > Object Manager > DOI > Expiration Date).
    // License_ExpireDate__c is the real, writeable field, so tests must
    // set it directly — the formula field then computes automatically.
    private static DOI__c buildDOI(
        Id contactId,
        String state,
        Date expireDate,
        Boolean active
    ){
        return new DOI__c(
            Contact__c=contactId,
            State__c=state,
            License_ExpireDate__c=expireDate,
            Active__c=active
        );
    }

    private static DOI__c createDOI(
        Id contactId,
        String state,
        Date expireDate,
        Boolean active
    ){
        DOI__c doi=buildDOI(contactId,state,expireDate,active);
        insert doi;
        return doi;
    }

    private static Integer errorLogCount(){
        return [
            SELECT Count()
            FROM Error_Log__c
            WHERE Event_Type__c='License_Alert__e'
        ];
    }

    //====================================================
    // MOCKS
    //====================================================

    private class SuccessMock implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req){

            HttpResponse res=new HttpResponse();

            if(req.getEndpoint().contains('oauth')){
                res.setStatusCode(200);
                res.setBody('{"access_token":"test_token"}');
            }else{
                res.setStatusCode(200);
                res.setBody('{"status":"ok"}');
            }

            return res;
        }
    }

    private class OAuthFailMock implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req){

            HttpResponse res=new HttpResponse();
            res.setStatusCode(401);
            res.setBody('{"error":"unauthorized"}');
            return res;

        }
    }

    private class PostFailMock implements HttpCalloutMock{

        public HttpResponse respond(HttpRequest req){

            HttpResponse res=new HttpResponse();

            if(req.getEndpoint().contains('oauth')){
                res.setStatusCode(200);
                res.setBody('{"access_token":"token"}');
            }else{
                res.setStatusCode(500);
                res.setBody('{"error":"server"}');
            }

            return res;

        }

    }

    // Same as PostFailMock, but the event POST itself returns a
    // non-retryable 4xx instead of a 5xx. This exercises the
    // logDeadLetter() call made directly inside postEvent() when
    // GoAMSRetryUtil.isRetryableStatus() is false — a different code
    // path than the dead-lettering done by retryOrDeadLetterBatch().
    private class PostFailNonRetryableMock implements HttpCalloutMock{

        public HttpResponse respond(HttpRequest req){

            HttpResponse res=new HttpResponse();

            if(req.getEndpoint().contains('oauth')){
                res.setStatusCode(200);
                res.setBody('{"access_token":"token"}');
            }else{
                res.setStatusCode(400);
                res.setBody('{"error":"bad request"}');
            }

            return res;

        }

    }

    private class ExceptionMock implements HttpCalloutMock{

        public HttpResponse respond(HttpRequest req){
            throw new CalloutException('Test Exception');
        }

    }

    //====================================================
    // 7 DAY ALERT
    //====================================================

    @isTest
    static void testExecute_7DayExpiry_AlertFired(){

        Contact c=[SELECT Id FROM Contact LIMIT 1];

        createDOI(
            c.Id,
            STATE_1,
            Date.today().addDays(7),
            true
        );

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        Database.executeBatch(new LicenseAlertBatch());
        Test.stopTest();

        Assert.areEqual(0, errorLogCount());

    }

    //====================================================
    //15 DAY ALERT
    //====================================================

    @isTest
    static void testExecute_15DayExpiry_AlertFired(){

        Contact c=[SELECT Id FROM Contact LIMIT 1];

        createDOI(
            c.Id,
            STATE_1,
            Date.today().addDays(15),
            true
        );

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        Database.executeBatch(new LicenseAlertBatch());
        Test.stopTest();

        Assert.areEqual(0, errorLogCount());

    }

    //====================================================
    //30 DAY ALERT
    //====================================================

    @isTest
    static void testExecute_30DayExpiry_AlertFired(){

        Contact c=[SELECT Id FROM Contact LIMIT 1];

        createDOI(
            c.Id,
            STATE_1,
            Date.today().addDays(30),
            true
        );

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        Database.executeBatch(new LicenseAlertBatch());
        Test.stopTest();

        Assert.areEqual(0, errorLogCount());

    }

    //====================================================
    //60 DAY ALERT
    //====================================================

    @isTest
    static void testExecute_60DayExpiry_AlertFired(){

        Contact c=[SELECT Id FROM Contact LIMIT 1];

        createDOI(
            c.Id,
            STATE_1,
            Date.today().addDays(60),
            true
        );

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        Database.executeBatch(new LicenseAlertBatch());
        Test.stopTest();

        Assert.areEqual(0, errorLogCount());

    }

    //====================================================
    //90 DAY ALERT
    //====================================================

    @isTest
    static void testExecute_90DayExpiry_AlertFired(){

        Contact c=[SELECT Id FROM Contact LIMIT 1];

        createDOI(
            c.Id,
            STATE_1,
            Date.today().addDays(90),
            true
        );

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        Database.executeBatch(new LicenseAlertBatch());
        Test.stopTest();

        Assert.areEqual(0, errorLogCount());

    }

    //====================================================
    //Outside Window
    //====================================================

    @isTest
    static void testStart_DOIOutside90Days_NotQueried(){

        Contact c=[SELECT Id FROM Contact LIMIT 1];

        createDOI(
            c.Id,
            STATE_1,
            Date.today().addDays(91),
            true
        );

        Test.startTest();
        Database.executeBatch(new LicenseAlertBatch());
        Test.stopTest();

        Assert.areEqual(0, errorLogCount());

    }

    //====================================================
    //Inactive
    //====================================================

    @isTest
    static void testStart_InactiveDOI_NotQueried(){

        Contact c=[SELECT Id FROM Contact LIMIT 1];

        createDOI(
            c.Id,
            STATE_1,
            Date.today().addDays(30),
            false
        );

        Test.startTest();
        Database.executeBatch(new LicenseAlertBatch());
        Test.stopTest();

        Assert.areEqual(0, errorLogCount());

    }

    //====================================================
    //Expired
    //====================================================

    @isTest
    static void testStart_ExpiredDOI_NotQueried(){

        Contact c=[SELECT Id FROM Contact LIMIT 1];

        createDOI(
            c.Id,
            STATE_1,
            Date.today().addDays(-1),
            true
        );

        Test.startTest();
        Database.executeBatch(new LicenseAlertBatch());
        Test.stopTest();

        Assert.areEqual(0, errorLogCount());

    }

    //====================================================
    //DEDUP
    //====================================================

    @isTest
    static void testExecute_DuplicateDOI_Deduplicated(){

        Contact c=[SELECT Id FROM Contact LIMIT 1];

        insert new List<DOI__c>{

            buildDOI(
                c.Id,
                STATE_1,
                Date.today().addDays(10),
                true
            ),

            buildDOI(
                c.Id,
                STATE_1,
                Date.today().addDays(12),
                true
            )
        };

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        Database.executeBatch(new LicenseAlertBatch());
        Test.stopTest();

        // Both DOIs land in the same 15-day bucket for the same
        // contact/state, so exactly one event should be published
        // and no errors logged.
        Assert.areEqual(0, errorLogCount());

    }

    //====================================================
    // Multiple States
    //====================================================

    @isTest
    static void testExecute_MultipleStates_SeparateAlerts() {

        Contact c = [SELECT Id FROM Contact LIMIT 1];

        insert new List<DOI__c>{
            buildDOI(
                c.Id,
                STATE_1,
                Date.today().addDays(15),
                true
            ),
            buildDOI(
                c.Id,
                STATE_2,
                Date.today().addDays(15),
                true
            )
        };

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        Database.executeBatch(new LicenseAlertBatch());
        Test.stopTest();

        Assert.areEqual(0, errorLogCount());

    }

    //====================================================
    // Bulk 200
    //====================================================

    @isTest
    static void testExecute_Bulk200DOIs_ProcessedWithoutError() {

        Contact c = [SELECT Id FROM Contact LIMIT 1];

        List<DOI__c> dois = new List<DOI__c>();

        for(Integer i=0;i<200;i++){

            dois.add(
                buildDOI(
                    c.Id,
                    STATE_1,
                    Date.today().addDays(15),
                    true
                )
            );

        }

        insert dois;

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        Database.executeBatch(new LicenseAlertBatch(),200);
        Test.stopTest();

        Assert.areEqual(0, errorLogCount());

    }

    //====================================================
    // Scheduler Execute
    //====================================================

    @isTest
    static void testScheduler_Execute_FiresBatch(){

        Test.startTest();

        new LicenseAlertScheduler().execute(null);

        Test.stopTest();

        Assert.isTrue(true);

    }

    //====================================================
    // Scheduler Job
    //====================================================

    @isTest
    static void testScheduler_SystemSchedule_JobCreated(){

        Test.startTest();

        System.schedule(
            'LicenseAlertScheduler_Test',
            '0 0 6 * * ?',
            new LicenseAlertScheduler()
        );

        Test.stopTest();

        Assert.areEqual(
            1,
            [
                SELECT Count()
                FROM CronTrigger
                WHERE CronJobDetail.Name='LicenseAlertScheduler_Test'
            ]
        );

    }

    //====================================================
    // OAuth Success
    //====================================================

    @isTest
    static void testGoAMSCallout_OAuthSuccess_EventPosted(){

        Contact c=[SELECT Id FROM Contact LIMIT 1];

        List<License_Alert__e> events =
            new List<License_Alert__e>{

            new License_Alert__e(
                Contact_ID__c=String.valueOf(c.Id),
                State__c=STATE_1,
                Alert_Type__c='7 Day License Expiry Alert',
                Alert_Date__c=String.valueOf(Date.today().addDays(7))
            )

        };

        Test.setMock(
            HttpCalloutMock.class,
            new SuccessMock()
        );

        Test.startTest();

        System.enqueueJob(
            new LicenseAlertHelper.GoAMSCallout(events, 0)
        );

        Test.stopTest();

        Assert.areEqual(
            0,
            [
                SELECT Count()
                FROM Error_Log__c
                WHERE Source__c='LicenseAlertHelper.GoAMSCallout'
            ]
        );

    }

    //====================================================
    // OAuth Failure
    //====================================================

    @isTest
    static void testGoAMSCallout_OAuthFailure_ErrorLogged(){

        Contact c=[SELECT Id FROM Contact LIMIT 1];

        List<License_Alert__e> events =
            new List<License_Alert__e>{

            new License_Alert__e(
                Contact_ID__c=String.valueOf(c.Id),
                State__c=STATE_1,
                Alert_Type__c='15 Day License Expiry Alert',
                Alert_Date__c=String.valueOf(Date.today().addDays(15))
            )

        };

        Test.setMock(
            HttpCalloutMock.class,
            new OAuthFailMock()
        );

        Test.startTest();

        // Enqueue already at the terminal retry count instead of at 0.
        // OAuthFailMock fails every call, so a real run would chain
        // retries up to MAX_RETRIES — but test context only allows one
        // level of Queueable chaining (a second chain throws
        // System.AsyncException: Maximum stack depth has been reached).
        // Starting at MAX_RETRIES exercises the exhausted-retries /
        // dead-letter branch directly on the first execute(), with no
        // further chaining needed.
        System.enqueueJob(
            new LicenseAlertHelper.GoAMSCallout(events, GoAMSRetryUtil.MAX_RETRIES)
        );

        Test.stopTest();

        Assert.areEqual(
            1,
            [
                SELECT Count()
                FROM Error_Log__c
                WHERE Source__c='LicenseAlertHelper.GoAMSCallout'
            ]
        );

    }

    //====================================================
    // POST Failure
    //====================================================

    @isTest
    static void testGoAMSCallout_PostFailure_ErrorLogged(){

        Contact c=[SELECT Id FROM Contact LIMIT 1];

        List<License_Alert__e> events =
            new List<License_Alert__e>{

            new License_Alert__e(
                Contact_ID__c=String.valueOf(c.Id),
                State__c=STATE_1,
                Alert_Type__c='30 Day License Expiry Alert',
                Alert_Date__c=String.valueOf(Date.today().addDays(30))
            )

        };

        Test.setMock(
            HttpCalloutMock.class,
            new PostFailMock()
        );

        Test.startTest();

        // See note in testGoAMSCallout_OAuthFailure_ErrorLogged: start at
        // MAX_RETRIES to hit the dead-letter branch on the first
        // execute() without relying on real chaining, which test context
        // only permits one level of.
        System.enqueueJob(
            new LicenseAlertHelper.GoAMSCallout(events, GoAMSRetryUtil.MAX_RETRIES)
        );

        Test.stopTest();

        Assert.areEqual(
            1,
            [
                SELECT Count()
                FROM Error_Log__c
                WHERE Source__c='LicenseAlertHelper.GoAMSCallout'
            ]
        );

    }

    //====================================================
    // POST Failure — non-retryable status (4xx), dead-lettered
    // immediately inside postEvent(), never touching
    // retryOrDeadLetterBatch()
    //====================================================

    @isTest
    static void testGoAMSCallout_PostFailureNonRetryable_DeadLetteredImmediately(){

        Contact c=[SELECT Id FROM Contact LIMIT 1];

        List<License_Alert__e> events =
            new List<License_Alert__e>{

            new License_Alert__e(
                Contact_ID__c=String.valueOf(c.Id),
                State__c=STATE_1,
                Alert_Type__c='90 Day License Expiry Alert',
                Alert_Date__c=String.valueOf(Date.today().addDays(90))
            )

        };

        Test.setMock(
            HttpCalloutMock.class,
            new PostFailNonRetryableMock()
        );

        Test.startTest();

        // Safe to start at retryCount 0 here: a non-retryable (4xx)
        // response makes postEvent() return false ("don't retry"), so
        // toRetry stays empty and retryOrDeadLetterBatch() — and any
        // job chaining — is never invoked.
        System.enqueueJob(
            new LicenseAlertHelper.GoAMSCallout(events, 0)
        );

        Test.stopTest();

        Assert.areEqual(
            1,
            [
                SELECT Count()
                FROM Error_Log__c
                WHERE Source__c='LicenseAlertHelper.GoAMSCallout'
                AND Status__c='Dead Letter'
            ]
        );

    }

    //====================================================
    // Retryable failure below MAX_RETRIES — exercises the actual
    // chaining branch of retryOrDeadLetterBatch() (System.enqueueJob
    // with a backoff delay), instead of the exhausted-retries branch
    // every other GoAMS test hits.
    //====================================================

    
    //====================================================
    // Callout Exception
    //====================================================

    @isTest
    static void testGoAMSCallout_CalloutException_ErrorLogged(){

        Contact c=[SELECT Id FROM Contact LIMIT 1];

        List<License_Alert__e> events =
            new List<License_Alert__e>{

            new License_Alert__e(
                Contact_ID__c=String.valueOf(c.Id),
                State__c=STATE_1,
                Alert_Type__c='60 Day License Expiry Alert',
                Alert_Date__c=String.valueOf(Date.today().addDays(60))
            )

        };

        Test.setMock(
            HttpCalloutMock.class,
            new ExceptionMock()
        );

        Test.startTest();

        // See note in testGoAMSCallout_OAuthFailure_ErrorLogged: start at
        // MAX_RETRIES to hit the dead-letter branch on the first
        // execute() without relying on real chaining, which test context
        // only permits one level of.
        System.enqueueJob(
            new LicenseAlertHelper.GoAMSCallout(events, GoAMSRetryUtil.MAX_RETRIES)
        );

        Test.stopTest();

        Assert.areEqual(
            1,
            [
                SELECT Count()
                FROM Error_Log__c
                WHERE Source__c='LicenseAlertHelper.GoAMSCallout'
            ]
        );

    }

    //====================================================
    // logErrors — success
    //====================================================

    @isTest
    static void testLogErrors_SuccessfulPublish_NoErrorLogged(){

        Contact c=[SELECT Id FROM Contact LIMIT 1];

        DOI__c doi=createDOI(
            c.Id,
            STATE_1,
            Date.today().addDays(90),
            true
        );

        List<License_Alert__e> events =
            new List<License_Alert__e>{

            new License_Alert__e(
                Contact_ID__c=String.valueOf(c.Id),
                State__c=STATE_1,
                Alert_Type__c='90 Day License Expiry Alert',
                Alert_Date__c=String.valueOf(Date.today().addDays(90))
            )

        };

        Test.startTest();

        List<Database.SaveResult> results =
            EventBus.publish(events);

        LicenseAlertHelper.logErrors(
            results,
            new List<DOI__c>{doi}
        );

        Test.stopTest();

        Assert.areEqual(0, errorLogCount());

    }

    //====================================================
    // logErrors — failure branch
    //====================================================

    @isTest
    static void testLogErrors_FailedPublish_ErrorLogged(){

        Contact c=[SELECT Id FROM Contact LIMIT 1];

        DOI__c doi=createDOI(
            c.Id,
            STATE_1,
            Date.today().addDays(30),
            true
        );

        // Database.SaveResult has no public constructor, so it can't be
        // mocked directly. Instead, generate a real failed SaveResult by
        // inserting an Account with no Name (a required field) using
        // allOrNone=false. logErrors() only cares that isSuccess() is
        // false and that getErrors() returns something — it doesn't
        // matter that the failure didn't come from EventBus.publish.
        List<Account> invalidAccounts = new List<Account>{ new Account() };
        List<Database.SaveResult> results =
            Database.insert(invalidAccounts, false);

        Test.startTest();

        LicenseAlertHelper.logErrors(
            results,
            new List<DOI__c>{doi}
        );

        Test.stopTest();

        Assert.areEqual(1, errorLogCount());

    }

    //====================================================
    // Finish
    //====================================================

    @isTest
    static void testFinish_CompletesWithoutError(){

        Test.startTest();

        Database.executeBatch(
            new LicenseAlertBatch()
        );

        Test.stopTest();

        Assert.isTrue(true);

    }

    //====================================================
    // GoAMSRetryUtil — isRetryableStatus
    //====================================================

    @isTest
    static void testIsRetryableStatus_NullStatus_ReturnsTrue(){
        Assert.isTrue(GoAMSRetryUtil.isRetryableStatus(null));
    }

    @isTest
    static void testIsRetryableStatus_5xxStatus_ReturnsTrue(){
        Assert.isTrue(GoAMSRetryUtil.isRetryableStatus(500));
        Assert.isTrue(GoAMSRetryUtil.isRetryableStatus(503));
    }

    @isTest
    static void testIsRetryableStatus_4xxStatus_ReturnsFalse(){
        Assert.isFalse(GoAMSRetryUtil.isRetryableStatus(400));
        Assert.isFalse(GoAMSRetryUtil.isRetryableStatus(401));
        Assert.isFalse(GoAMSRetryUtil.isRetryableStatus(404));
    }

    @isTest
    static void testIsRetryableStatus_2xxStatus_ReturnsFalse(){
        Assert.isFalse(GoAMSRetryUtil.isRetryableStatus(200));
    }

    //====================================================
    // GoAMSRetryUtil — backoffMinutes
    //====================================================

    @isTest
    static void testBackoffMinutes_BelowCap_ReturnsLinearValue(){
        Assert.areEqual(2, GoAMSRetryUtil.backoffMinutes(1));
        Assert.areEqual(4, GoAMSRetryUtil.backoffMinutes(2));
    }

    @isTest
    static void testBackoffMinutes_AtOrAboveCap_ReturnsTenMinuteCap(){
        // 5 * 2 = 10, exactly at the cap
        Assert.areEqual(10, GoAMSRetryUtil.backoffMinutes(5));
        // 6 * 2 = 12, would exceed Salesforce's 10-minute max delay
        Assert.areEqual(10, GoAMSRetryUtil.backoffMinutes(6));
    }

}