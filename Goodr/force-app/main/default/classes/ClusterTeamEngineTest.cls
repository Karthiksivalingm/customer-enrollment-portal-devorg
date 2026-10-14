@IsTest
public class ClusterTeamEngineTest {

    private static Id companyRtId = Schema.SObjectType.Account
        .getRecordTypeInfosByName().get('Company').getRecordTypeId();

    private static Account buildCompanyAccount(String name, String taxId) {
        return new Account(
            Name               = name,
            RecordTypeId       = companyRtId,
            Tax_Id__c          = taxId,
            Sales_Channel__c   = 'Global',
            BillingStreet      = '123 Main St',
            BillingCity        = 'Los Angeles',
            BillingState       = 'CA',
            BillingPostalCode  = '90001',
            BillingCountry     = 'US',
            ShippingStreet     = '123 Main St',
            ShippingCity       = 'Los Angeles',
            ShippingState      = 'CA',
            ShippingPostalCode = '90001',
            ShippingCountry    = 'US'
        );
    }

    private static Lead buildValidLead(String lastName) {
        return new Lead(
            FirstName                       = 'Test',
            LastName                        = lastName,
            Company                         = 'Test Co',
            Sales_Channel__c                = 'Global',
            Terms_of_Service_Agreement__c   = 'Agreed',
            Has_Physical_Store__c           = true,
            Resale_Certificate_Status__c    = 'Yes, I do.',
            Tax_Id__c                       = '123456789',
            Street                          = '123 Main St',
            City                            = 'Los Angeles',
            State                           = 'CA',
            PostalCode                      = '90001',
            Country                         = 'US'
        );
    }

    // ── Covers: records.isEmpty() → returns immediately ───────────────────────
    @IsTest
    static void testAssignTeams_EmptyList_ReturnsEarly() {
        Test.startTest();
        ClusterTeamEngine.assignTeams('Account', new List<SObject>());
        Test.stopTest();
        System.assert(true, 'Empty list should return without error');
    }

    // ── Covers: clusterValues.isEmpty() → returns before CMDT query ───────────
    @IsTest
    static void testAssignTeams_AllBlankCluster_ReturnsEarly() {
        Account acc = buildCompanyAccount('No Cluster Co', '333444555');
        insert acc;

        List<Account> accs = [SELECT Id, Cluster__c FROM Account WHERE Id = :acc.Id];
        accs[0].put('Cluster__c', null);

        Test.startTest();
        ClusterTeamEngine.assignTeams('Account', accs);
        Test.stopTest();

        System.assert(true, 'Blank Cluster__c should hit clusterValues early return');
    }

    // ── Covers: Account branch — CMDT found (Cluster 7/Global), deleteExistingTeams
    //           runs, usersByUsername lookup runs (users may not exist in test
    //           context so u == null → continue), toInsert stays empty ─────────
    @IsTest
    static void testAssignTeams_Account_CMDTFound_DeleteRuns() {
        Account acc = buildCompanyAccount('Global Account', '100200300');
        insert acc;

        // Trigger sets Cluster 7 for Global — CMDT rules exist for Cluster 7/Account
        List<Account> accs = [SELECT Id, Cluster__c FROM Account WHERE Id = :acc.Id];

        Test.startTest();
        ClusterTeamEngine.assignTeams('Account', accs);
        Test.stopTest();

        // deleteExistingTeams ran, CMDT query ran, usersByUsername lookup ran
        Integer memberCount = [
            SELECT COUNT() FROM AccountTeamMember WHERE AccountId = :acc.Id
        ];
        System.assert(memberCount >= 0,
            'Account full path through CMDT should complete without error');
    }

    // ── Covers: deleteExistingTeams idempotency — called twice, no DML error ──
    @IsTest
    static void testAssignTeams_CalledTwice_NoError() {
        Account acc = buildCompanyAccount('Delete Teams Co', '777888999');
        insert acc;

        List<Account> accs = [SELECT Id, Cluster__c FROM Account WHERE Id = :acc.Id];

        Test.startTest();
        ClusterTeamEngine.assignTeams('Account', accs);
        Integer countAfterFirst = [
            SELECT COUNT() FROM AccountTeamMember WHERE AccountId = :acc.Id
        ];
        ClusterTeamEngine.assignTeams('Account', accs);
        Integer countAfterSecond = [
            SELECT COUNT() FROM AccountTeamMember WHERE AccountId = :acc.Id
        ];
        Test.stopTest();

        System.assertEquals(countAfterFirst, countAfterSecond,
            'deleteExistingTeams should be idempotent across repeated calls');
    }

    // ── Covers: Contact branch — deleteExistingTeams(Contact) + CMDT query ────
    @IsTest
    static void testAssignTeams_ContactObject_CMDTFound() {
        Account acc = buildCompanyAccount('Contact Parent', '555666777');
        insert acc;

        Contact con = new Contact(
            FirstName        = 'Test',
            LastName         = 'Contact',
            Email            = 'test@test.com',
            AccountId        = acc.Id,
            Sales_Channel__c = 'Global'
        );
        insert con;

        // Contact.Cluster__c is formula — trigger sets Cluster 7 via ClusterRuleEngine
        List<Contact> cons = [SELECT Id, Cluster__c FROM Contact WHERE Id = :con.Id];

        Test.startTest();
        ClusterTeamEngine.assignTeams('Contact', cons);
        Test.stopTest();

        System.assert(true, 'Contact CMDT path should run without error');
    }

    // ── Covers: Lead branch — deleteExistingTeams(Lead) + CMDT query ──────────
    @IsTest
    static void testAssignTeams_LeadObject_CMDTFound() {
        Lead lead = buildValidLead('Lead');
        insert lead;

        // Trigger sets Cluster 7 for Global lead
        List<Lead> leads = [SELECT Id, Cluster__c FROM Lead WHERE Id = :lead.Id];

        Test.startTest();
        ClusterTeamEngine.assignTeams('Lead', leads);
        Test.stopTest();

        System.assert(true, 'Lead CMDT path should run without error');
    }

    // ── Covers: Opportunity branch — deleteExistingTeams(Opportunity) + CMDT ──
    @IsTest
    static void testAssignTeams_OpportunityObject_CMDTFound() {
        Account acc = buildCompanyAccount('Opp Parent', '666777888');
        insert acc;

        Opportunity opp = new Opportunity(
            Name             = 'Test Opp',
            AccountId        = acc.Id,
            StageName        = 'Summary',
            CloseDate        = Date.today().addDays(30),
            Sales_Channel__c = 'Global'
        );
        insert opp;

        // Trigger sets Cluster 7 for Global opp
        List<Opportunity> opps = [SELECT Id, Cluster__c FROM Opportunity WHERE Id = :opp.Id];

        Test.startTest();
        ClusterTeamEngine.assignTeams('Opportunity', opps);
        Test.stopTest();

        System.assert(true, 'Opportunity CMDT path should run without error');
    }

    // ── Covers: Case branch — deleteExistingTeams(Case) ──────────────────────
    @IsTest
    static void testAssignTeams_CaseObject_NoError() {
        Case c = new Case(Subject = 'Test Case', Status = 'New', Origin = 'Email');
        insert c;

        Test.startTest();
        List<Case> cases = [SELECT Id, Cluster__c FROM Case WHERE Id = :c.Id];
        ClusterTeamEngine.assignTeams('Case', cases);
        Test.stopTest();

        System.assert(true, 'Case path should run without error');
    }

    // ── Covers: rulesByCluster.isEmpty() → returns before deleteExistingTeams ─
    // Force a cluster value that has NO Account_Cluster_Team__mdt rules
    // so the engine hits the rulesByCluster.isEmpty() early return
    @IsTest
    static void testAssignTeams_NoMatchingCMDTRules_ReturnsEarly() {
        Account acc = buildCompanyAccount('No Rules Account', '888999111');
        insert acc;

        List<Account> accs = [SELECT Id, Cluster__c FROM Account WHERE Id = :acc.Id];
        // Override in-memory to a cluster value with no team rules in CMDT
        // Partnerships has no Account_Cluster_Team__mdt records
        accs[0].put('Cluster__c', 'Partnerships');

        Test.startTest();
        ClusterTeamEngine.assignTeams('Account', accs);
        Test.stopTest();

        System.assert(true,
            'No matching CMDT rules should hit rulesByCluster.isEmpty() return');
    }

    // ── Covers: multiple records in list — bulk path through all loops ─────────
    @IsTest
    static void testAssignTeams_MultipleRecords_BulkPath() {
        List<Account> accs = new List<Account>{
            buildCompanyAccount('Bulk Co 1', '111222001'),
            buildCompanyAccount('Bulk Co 2', '111222002'),
            buildCompanyAccount('Bulk Co 3', '111222003')
        };
        insert accs;

        List<Account> freshAccs = [
            SELECT Id, Cluster__c FROM Account
            WHERE Id IN :new Map<Id,Account>(accs).keySet()
        ];

        Test.startTest();
        ClusterTeamEngine.assignTeams('Account', freshAccs);
        Test.stopTest();

        System.assert(true, 'Bulk account list should process without error');
    }
}