@isTest
private class CommissionReconciliationEngineTest {

    private static final String STATUS_MATCHED          = 'Matched';
    private static final String STATUS_DISCREPANCY       = 'Discrepancy';
    private static final String STATUS_NO_MATCH          = 'No Match Found';
    private static final String STATUS_UNMATCHED_AGENT   = 'Unmatched - No Agent Code';
    private static final String STATUS_INTEGRATION_ERROR = 'Integration Error - Not Reconciled';

    @testSetup
    static void setupTestData() {

        Account agency = new Account(
            Name = 'Test Agency'
        );
        insert agency;

        // Agent with a resolvable Agent_Code__c — the "happy path" contact.
        // NPN__c and Agent_Status__c are required by validation rules
        // (NPN_Required, Agent_Status_Onboarding_required) on any new
        // Agent-record-type Contact, same as in LicenseAlertBatchTest.
        Contact codedAgent = new Contact(
            LastName        = 'Coded Agent',
            AccountId       = agency.Id,
            Email           = 'codedagent@example.com',
            NPN__c          = '1234567890',
            Agent_Status__c = 'Onboarding',
            Agent_Code__c   = 'AGT001'
        );

        // Agent record present, but Agent_Code__c left blank — mirrors the
        // real-world state called out in the class doc comment (only 1 of
        // 243 Contacts has Agent_Code__c populated today).
        Contact blankCodeAgent = new Contact(
            LastName        = 'Blank Code Agent',
            AccountId       = agency.Id,
            Email           = 'blankcodeagent@example.com',
            NPN__c          = '0987654321',
            Agent_Status__c = 'Onboarding'
        );

        insert new List<Contact>{ codedAgent, blankCodeAgent };

        // NOTE: an org-level AgentCreatedTrigger (Contact AfterInsert)
        // auto-populates Agent_Code__c as 'AGT-' + NPN__c whenever a new
        // Contact is inserted without one — confirmed via debug log. So
        // leaving Agent_Code__c off the insert above does NOT leave it
        // blank; it gets backfilled to 'AGT-0987654321'. To genuinely
        // exercise the "no agent code" branch, force it blank with an
        // explicit follow-up update (AgentCreatedTrigger only listens for
        // AfterInsert, not AfterUpdate, so this sticks).
        blankCodeAgent.Agent_Code__c = null;
        update blankCodeAgent;
    }

    //====================================================
    // Helpers
    //====================================================

    private static Contact getCodedAgent(){
        return [SELECT Id, Agent_Code__c FROM Contact WHERE Email = 'codedagent@example.com' LIMIT 1];
    }

    private static Contact getBlankCodeAgent(){
        return [SELECT Id, Agent_Code__c FROM Contact WHERE Email = 'blankcodeagent@example.com' LIMIT 1];
    }

    private static Commission_Record__c buildRecord(
        Id agentId,
        String policyNumber,
        String paymentPeriod,
        Decimal grossAmount
    ){
        return new Commission_Record__c(
            Agent__c           = agentId,
            Policy_Number__c   = policyNumber,
            Payment_Period__c  = paymentPeriod,
            Gross_Amount__c    = grossAmount
        );
    }

    private static Commission_Record__c createRecord(
        Id agentId,
        String policyNumber,
        String paymentPeriod,
        Decimal grossAmount
    ){
        Commission_Record__c cr = buildRecord(agentId, policyNumber, paymentPeriod, grossAmount);
        insert cr;
        return cr;
    }

    private static Commission_Record__c refetch(Id crId){
        return [
            SELECT Id, Policy_Number__c, Payment_Period__c, Recon_Status__c, Gross_Amount__c
            FROM Commission_Record__c
            WHERE Id = :crId
        ];
    }

    private static Integer errorLogCount(){
        return [
            SELECT Count()
            FROM Error_Log__c
            WHERE Event_Type__c = 'Commission_Reconciliation'
        ];
    }

    private static Integer incidentCount(){
        return [
            SELECT Count()
            FROM Security_Incident__c
            WHERE Detection_Method__c = 'Sync_Discrepancy'
        ];
    }

    //====================================================
    // MOCKS
    //====================================================

    // OAuth succeeds; the commission-read call fails with a non-2xx.
    private class FetchHttpFailMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('oauth')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"token"}');
            } else {
                res.setStatusCode(500);
                res.setBody('{"error":"server"}');
            }
            return res;
        }
    }

    // OAuth succeeds; the commission-read call returns 200 with a body
    // that isn't valid JSON, forcing JSON.deserializeUntyped() to throw —
    // exercises the catch block inside fetchGoAmsCommissions(), a
    // different path than the non-2xx branch above.
    private class FetchMalformedJsonMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('oauth')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"token"}');
            } else {
                res.setStatusCode(200);
                res.setBody('not valid json{{{');
            }
            return res;
        }
    }

    // OAuth fails outright.
    private class OAuthFailMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(401);
            res.setBody('{"error":"unauthorized"}');
            return res;
        }
    }

    // OAuth succeeds; the commission-read call returns a caller-supplied
    // JSON array as the GO AMS rows, so each scenario test can hand in
    // exactly the row shape it needs.
    private class FetchRowsMock implements HttpCalloutMock {
        private String rowsJson;
        FetchRowsMock(String rowsJson) {
            this.rowsJson = rowsJson;
        }
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('oauth')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"token"}');
            } else {
                res.setStatusCode(200);
                res.setBody(rowsJson);
            }
            return res;
        }
    }

    //====================================================
    // start() — key filters
    //====================================================

    @isTest
    static void testStart_MissingPolicyNumber_NotQueried(){

        Contact agent = getCodedAgent();

        Commission_Record__c cr = createRecord(agent.Id, null, '2026-01', 100);

        Test.startTest();
        Database.executeBatch(new CommissionReconciliationEngine());
        Test.stopTest();

        Assert.areEqual(null, refetch(cr.Id).Recon_Status__c);

    }

    @isTest
    static void testStart_MissingPaymentPeriod_NotQueried(){

        Contact agent = getCodedAgent();

        Commission_Record__c cr = createRecord(agent.Id, 'POL999', null, 100);

        Test.startTest();
        Database.executeBatch(new CommissionReconciliationEngine());
        Test.stopTest();

        Assert.areEqual(null, refetch(cr.Id).Recon_Status__c);

    }

    //====================================================
    // Unmatched agent code — no callout should occur at all
    //====================================================

    @isTest
    static void testExecute_NoAgentOnRecord_UnmatchedNoAgentCode(){

        // Agent__c left null entirely — Agent__r?.Agent_Code__c resolves
        // via the safe-navigation operator without a NullPointerException.
        Commission_Record__c cr = createRecord(null, 'POL100', '2026-01', 100);

        // Deliberately no Test.setMock(...): if the code attempted a
        // callout here, the test would fail with a
        // System.CalloutException ("mock response not set"), proving the
        // OAuth/fetch calls are correctly skipped when nothing is
        // matchable.
        Test.startTest();
        Database.executeBatch(new CommissionReconciliationEngine());
        Test.stopTest();

        Assert.areEqual(STATUS_UNMATCHED_AGENT, refetch(cr.Id).Recon_Status__c);
        Assert.areEqual(0, errorLogCount());
        Assert.areEqual(0, incidentCount());

    }

  

    //====================================================
    // OAuth failure
    //====================================================

    @isTest
    static void testExecute_OAuthFailure_IntegrationErrorLogged(){

        Contact agent = getCodedAgent();

        Commission_Record__c cr = createRecord(agent.Id, 'POL200', '2026-01', 100);

        Test.setMock(HttpCalloutMock.class, new OAuthFailMock());

        Test.startTest();
        Database.executeBatch(new CommissionReconciliationEngine());
        Test.stopTest();

        Assert.areEqual(STATUS_INTEGRATION_ERROR, refetch(cr.Id).Recon_Status__c);
        Assert.areEqual(1, errorLogCount());
        Assert.areEqual(0, incidentCount());

    }

    //====================================================
    // GO AMS read failure — HTTP non-2xx
    //====================================================

    @isTest
    static void testExecute_FetchHttpFailure_IntegrationErrorLogged(){

        Contact agent = getCodedAgent();

        Commission_Record__c cr = createRecord(agent.Id, 'POL201', '2026-01', 100);

        Test.setMock(HttpCalloutMock.class, new FetchHttpFailMock());

        Test.startTest();
        Database.executeBatch(new CommissionReconciliationEngine());
        Test.stopTest();

        Assert.areEqual(STATUS_INTEGRATION_ERROR, refetch(cr.Id).Recon_Status__c);
        Assert.areEqual(1, errorLogCount());

    }

    //====================================================
    // GO AMS read failure — malformed JSON body (parse exception)
    //====================================================

    @isTest
    static void testExecute_FetchMalformedJson_IntegrationErrorLogged(){

        Contact agent = getCodedAgent();

        Commission_Record__c cr = createRecord(agent.Id, 'POL202', '2026-01', 100);

        Test.setMock(HttpCalloutMock.class, new FetchMalformedJsonMock());

        Test.startTest();
        Database.executeBatch(new CommissionReconciliationEngine());
        Test.stopTest();

        Assert.areEqual(STATUS_INTEGRATION_ERROR, refetch(cr.Id).Recon_Status__c);
        Assert.areEqual(1, errorLogCount());

    }

    //====================================================
    // No matching GO AMS record
    //====================================================

    @isTest
    static void testExecute_NoMatchingGoAmsRecord_IncidentRaised(){

        Contact agent = getCodedAgent();

        Commission_Record__c cr = createRecord(agent.Id, 'POL300', '2026-01', 100);

        // GO AMS returns no rows at all for this policy.
        Test.setMock(HttpCalloutMock.class, new FetchRowsMock('[]'));

        Test.startTest();
        Database.executeBatch(new CommissionReconciliationEngine());
        Test.stopTest();

        Assert.areEqual(STATUS_NO_MATCH, refetch(cr.Id).Recon_Status__c);
        Assert.areEqual(1, incidentCount());
        Assert.areEqual(0, errorLogCount());

    }

    //====================================================
    // Amount mismatch — SF value is retained, never overwritten
    //====================================================

    @isTest
    static void testExecute_AmountMismatch_DiscrepancyRaised_SFAmountRetained(){

        Contact agent = getCodedAgent();

        Commission_Record__c cr = createRecord(agent.Id, 'POL400', '2026-01', 150.00);

        String rows = '[{"policy_number":"POL400","payment_period":"2026-01",'
            + '"agent_code":"AGT001","amount":140.00}]';

        Test.setMock(HttpCalloutMock.class, new FetchRowsMock(rows));

        Test.startTest();
        Database.executeBatch(new CommissionReconciliationEngine());
        Test.stopTest();

        Commission_Record__c updated = refetch(cr.Id);
        Assert.areEqual(STATUS_DISCREPANCY, updated.Recon_Status__c);
        // Per 9.4.1, SF is source of truth — the field must be untouched.
        Assert.areEqual(150.00, updated.Gross_Amount__c);
        Assert.areEqual(1, incidentCount());

    }

    //====================================================
    // Amount match — clean reconciliation, no incident
    //====================================================

    @isTest
    static void testExecute_AmountMatch_StatusMatched_NoIncident(){

        Contact agent = getCodedAgent();

        Commission_Record__c cr = createRecord(agent.Id, 'POL500', '2026-01', 200.00);

        String rows = '[{"policy_number":"POL500","payment_period":"2026-01",'
            + '"agent_code":"AGT001","amount":200.00}]';

        Test.setMock(HttpCalloutMock.class, new FetchRowsMock(rows));

        Test.startTest();
        Database.executeBatch(new CommissionReconciliationEngine());
        Test.stopTest();

        Assert.areEqual(STATUS_MATCHED, refetch(cr.Id).Recon_Status__c);
        Assert.areEqual(0, incidentCount());

    }

    //====================================================
    // Amount match within the 0.01 tolerance / both-null edge case
    //====================================================

    @isTest
    static void testExecute_BothAmountsNull_TreatedAsMatch(){

        Contact agent = getCodedAgent();

        Commission_Record__c cr = createRecord(agent.Id, 'POL501', '2026-01', null);

        // amount omitted from the row entirely -> Decimal null on the GO AMS side too.
        String rows = '[{"policy_number":"POL501","payment_period":"2026-01",'
            + '"agent_code":"AGT001"}]';

        Test.setMock(HttpCalloutMock.class, new FetchRowsMock(rows));

        Test.startTest();
        Database.executeBatch(new CommissionReconciliationEngine());
        Test.stopTest();

        Assert.areEqual(STATUS_MATCHED, refetch(cr.Id).Recon_Status__c);
        Assert.areEqual(0, incidentCount());

    }

    //====================================================
    // Key matching ignores case and surrounding whitespace
    //====================================================

    @isTest
    static void testExecute_KeyMatchIgnoresCaseAndWhitespace_StatusMatched(){

        Contact agent = getCodedAgent();

        // SF side stored lower-case with padding.
        Commission_Record__c cr = createRecord(agent.Id, ' pol600 ', '2026-01', 75.00);

        // GO AMS side upper-case, no padding.
        String rows = '[{"policy_number":"POL600","payment_period":"2026-01",'
            + '"agent_code":"AGT001","amount":75.00}]';

        Test.setMock(HttpCalloutMock.class, new FetchRowsMock(rows));

        Test.startTest();
        Database.executeBatch(new CommissionReconciliationEngine());
        Test.stopTest();

        Assert.areEqual(STATUS_MATCHED, refetch(cr.Id).Recon_Status__c);

    }

    //====================================================
    // Database.Stateful counters carry across the run
    //====================================================

   

    //====================================================
    // finish()
    //====================================================

    @isTest
    static void testFinish_CompletesWithoutError(){

        Test.startTest();
        Database.executeBatch(new CommissionReconciliationEngine());
        Test.stopTest();

        Assert.isTrue(true);

    }

}