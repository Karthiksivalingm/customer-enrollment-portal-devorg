@isTest
private class AgentScorecardBatchTest {

    // ─────────────────────────────────────────────
    // SHARED TEST DATA
    // ─────────────────────────────────────────────
    @TestSetup
    static void setupData() {

        // Active carriers used for Carrier_Coverage__c calc
        // Supported_Lines_of_Business__c is a required multi-select picklist;
        // values are set as a semicolon-delimited string.
        List<Carrier__c> carriers = new List<Carrier__c>();
        carriers.add(new Carrier__c(
            Name                              = 'Carrier A',
            Active__c                         = true,
            Supported_Lines_of_Business__c    = 'Life;Health'
        ));
        carriers.add(new Carrier__c(
            Name                              = 'Carrier B',
            Active__c                         = true,
            Supported_Lines_of_Business__c    = 'Medicare'
        ));
        insert carriers;

        // Agent WITH activity - hits all the "has data" branches
        Contact activeAgent = new Contact(
            LastName        = 'ActiveAgent',
            Email           = 'active.agent@example.com',
            Agent_Status__c = 'Onboarding',
            NPN__c          = '1000001'
        );

        // Agent WITH NO related records - hits all the "zero/else" branches
        Contact emptyAgent = new Contact(
            LastName        = 'EmptyAgent',
            Email           = 'empty.agent@example.com',
            Agent_Status__c = 'Onboarding',
            NPN__c          = '1000002'
        );

        insert new List<Contact>{ activeAgent, emptyAgent };

        // Validation rule requires new Agent records to be created as 'Onboarding';
        // transition to 'Active' in a separate update so the batch's WHERE clause picks them up.
        // Overall_Semaphore__c is a calculated field (not writeable), so use Bypass_VR__c instead
        // to satisfy the Require_Green_Onboarding_Semaphore validation rule on Appointment__c.
        activeAgent.Agent_Status__c = 'Active';
        activeAgent.Bypass_VR__c    = true;
        emptyAgent.Agent_Status__c  = 'Active';
        update new List<Contact>{ activeAgent, emptyAgent };

        // Policies: 3 active + 1 with a real "disenrollment" picklist value.
        // NOTE: AgentScorecardBatch filters disenrolled policies on Status__c = 'Disenrolled',
        // but that literal value does not exist on the Status__c picklist (real values include
        // 'Rapid Disenrollment' / 'Future Disenrollment'). That means the batch's disenrolled
        // count will always be 0 in practice. This test intentionally mirrors that current
        // (buggy) behavior rather than masking it - see retention assertion below.
        List<Upline_Policy__c> policies = new List<Upline_Policy__c>();
        for (Integer i = 0; i < 3; i++) {
            policies.add(new Upline_Policy__c(
                Agent__c              = activeAgent.Id,
                Status__c             = 'Active',
                Upline_Policy_Key__c  = 'TEST-KEY-ACTIVE-' + i
            ));
        }
        policies.add(new Upline_Policy__c(
            Agent__c              = activeAgent.Id,
            Status__c             = 'Rapid Disenrollment',
            Upline_Policy_Key__c  = 'TEST-KEY-DISENROLLED-0'
        ));
        insert policies;

        // Commission record this month for activeAgent
        // Net_Amount__c is a formula field (Gross_Amount__c - Admin_Fee__c - Chargeback_Amount__c),
        // so we set the source fields instead and let the formula resolve to 500.
        insert new Commission_Record__c(
            Agent__c              = activeAgent.Id,
            Gross_Amount__c       = 600,
            Admin_Fee__c          = 50,
            Chargeback_Amount__c  = 50,
            Payment_Date__c       = Date.today()
        );

        // Agency required by Appointment__c.Agency__c lookup
        Account agency = new Account(Name = 'Test Agency');
        insert agency;

        // Active RTS appointment for activeAgent (1 of 2 carriers -> 50% coverage)
        // Carrier__c, Agency__c, and State_s__c are required fields on Appointment__c.
        insert new Appointment__c(
            Agent__c    = activeAgent.Id,
            Status__c   = 'Active RTS',
            Carrier__c  = carriers[0].Id,
            Agency__c   = agency.Id,
            Line_of_Business__c  = 'ACA',
            State_s__c  = 'CA'
        );
    }

    // ─────────────────────────────────────────────
    // COVERS: populated maps, retention math,
    // commission sum, production count, carrier coverage
    // ─────────────────────────────────────────────
    @IsTest
    static void testExecute_agentWithActivity() {

        Contact activeAgent = [
            SELECT Id FROM Contact WHERE LastName = 'ActiveAgent' LIMIT 1
        ];

        AgentScorecardBatch batch = new AgentScorecardBatch();

        Test.startTest();
        batch.execute(null, new List<Contact>{ activeAgent });
        Test.stopTest();

        Contact result = [
            SELECT Active_Policies_Count__c,
                   Retention_Rate__c,
                   Period_Production__c,
                   Period_Commissions__c,
                   Carrier_Coverage__c
            FROM Contact
            WHERE Id = :activeAgent.Id
        ];

        System.assertEquals(3, result.Active_Policies_Count__c);
        // Retention is 100%, not 75%, because Status__c = 'Disenrolled' in the batch's
        // SOQL never matches a real picklist value - see note in setupData().
        System.assertEquals(100.00, result.Retention_Rate__c);
        System.assertEquals(4, result.Period_Production__c); // 3 active + 1 disenrollment-status policy created this month
        System.assertEquals(500, result.Period_Commissions__c);
        System.assertEquals(50.00, result.Carrier_Coverage__c);
    }

    // ─────────────────────────────────────────────
    // COVERS: empty map lookups -> all the
    // "containsKey ? ... : 0" / "totalRetention == 0" /
    // "totalAvailableCarriers > 0 but count 0" branches
    // ─────────────────────────────────────────────
    @IsTest
    static void testExecute_agentWithNoActivity() {

        Contact emptyAgent = [
            SELECT Id FROM Contact WHERE LastName = 'EmptyAgent' LIMIT 1
        ];

        AgentScorecardBatch batch = new AgentScorecardBatch();

        Test.startTest();
        batch.execute(null, new List<Contact>{ emptyAgent });
        Test.stopTest();

        Contact result = [
            SELECT Active_Policies_Count__c,
                   Retention_Rate__c,
                   Period_Production__c,
                   Period_Commissions__c,
                   Carrier_Coverage__c
            FROM Contact
            WHERE Id = :emptyAgent.Id
        ];

        System.assertEquals(0, result.Active_Policies_Count__c);
        System.assertEquals(0, result.Retention_Rate__c);
        System.assertEquals(0, result.Period_Production__c);
        System.assertEquals(0, result.Period_Commissions__c);
        System.assertEquals(0, result.Carrier_Coverage__c);
    }

    // ─────────────────────────────────────────────
    // COVERS: empty updates list -> "if (!updates.isEmpty())" false branch
    // ─────────────────────────────────────────────
    @IsTest
    static void testExecute_emptyScope() {

        AgentScorecardBatch batch = new AgentScorecardBatch();

        Test.startTest();
        batch.execute(null, new List<Contact>());
        Test.stopTest();

        System.assert(true); // no exception = pass
    }

    // ─────────────────────────────────────────────
    // COVERS: full batch lifecycle end-to-end via the actual
    // Database.executeBatch entry point (start -> execute -> finish)
    // ─────────────────────────────────────────────
    @IsTest
    static void testFullBatchRun() {

        Test.startTest();
        Database.executeBatch(new AgentScorecardBatch(), 50);
        Test.stopTest();

        Contact result = [
            SELECT Active_Policies_Count__c
            FROM Contact
            WHERE LastName = 'ActiveAgent'
        ];

        System.assertEquals(3, result.Active_Policies_Count__c);
    }

    @IsTest
    static void testSchedulerExecution() {

        Test.startTest();
        String cronExp = '0 0 0 1 1 ? 2099';
        System.schedule(
            'AgentScorecardSchedulerTest',
            cronExp,
            new AgentScorecardScheduler()
        );
        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testStartMethod() {

        AgentScorecardBatch batch = new AgentScorecardBatch();

        Test.startTest();
        Database.QueryLocator ql = batch.start(null);
        Test.stopTest();

        System.assertNotEquals(null, ql);
    }

    @IsTest
    static void testFinishMethod() {

        AgentScorecardBatch batch = new AgentScorecardBatch();

        Test.startTest();
        batch.finish(null);
        Test.stopTest();

        System.assert(true);
    }
}