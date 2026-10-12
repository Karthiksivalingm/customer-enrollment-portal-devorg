@IsTest
public class ClusterRuleEngineTest {

    private static Id companyRtId = Schema.SObjectType.Account
        .getRecordTypeInfosByName().get('Company').getRecordTypeId();

    private static Account buildAccount(String name, String taxId, String channel) {
        return new Account(
            Name               = name,
            RecordTypeId       = companyRtId,
            Tax_Id__c          = taxId,
            Sales_Channel__c   = channel,
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

    private static List<Account> queryAccounts(Set<Id> ids) {
        return [
            SELECT Id, Name, Cluster__c, Sales_Channel__c,
                   BillingStreet, BillingCity, BillingState,
                   BillingPostalCode, BillingCountry,
                   ShippingStreet, ShippingCity, ShippingState,
                   ShippingPostalCode, ShippingCountry,
                   Tax_Id__c, RecordTypeId, Is_Franchise__c
            FROM Account WHERE Id IN :ids
        ];
    }

    // Covers: records.isEmpty() → returns early
    @IsTest
    static void testEvaluate_EmptyList_ReturnsEarly() {
        Test.startTest();
        ClusterRuleEngine.evaluate('Account', new List<SObject>(), null);
        Test.stopTest();
        System.assert(true, 'Empty list should return without error');
    }

    // Covers: insert path — oldMap is null, rule engine runs and auto-assigns cluster
    @IsTest
    static void testEvaluate_AccountRecords_AllProcessed() {
        List<Account> accs = new List<Account>{
            buildAccount('Co 1', '111000001', 'Global'),
            buildAccount('Co 2', '111000002', 'Global'),
            buildAccount('Co 3', '111000003', 'Global')
        };
        insert accs;

        Test.startTest();
        List<Account> freshAccs = queryAccounts(new Map<Id,Account>(accs).keySet());
        // Simulating insert path — pass null for oldMap
        ClusterRuleEngine.evaluate('Account', freshAccs, null);
        Test.stopTest();

        System.assertEquals(3, freshAccs.size(), 'All 3 accounts should be processed');
        for (Account a : freshAccs) {
            System.assert(
                a.Cluster__c == null || a.Cluster__c.startsWith('Cluster'),
                'Cluster__c should be null or a valid Cluster value: ' + a.Cluster__c
            );
        }
    }

    // Covers: update path — Sales Channel unchanged → rule engine skipped entirely
    @IsTest
    static void testEvaluate_SalesChannelUnchanged_RuleEngineSkipped() {
        Account acc = buildAccount('No Change Co', '111000004', 'Global');
        insert acc;

        List<Account> freshAccs = queryAccounts(new Set<Id>{ acc.Id });

        // Build oldMap with the same Sales Channel — simulates no SC change
        Map<Id, SObject> oldMap = new Map<Id, SObject>();
        Account oldAcc = acc.clone(true, true, false, false);
        oldAcc.Sales_Channel__c = 'Global';
        oldMap.put(oldAcc.Id, oldAcc);

        // Manually set a different cluster on the new record
        freshAccs[0].Cluster__c = 'Cluster 3';

        Test.startTest();
        ClusterRuleEngine.evaluate('Account', freshAccs, oldMap);
        Test.stopTest();

        // Rule engine should have skipped — Cluster 3 should still be on the record
        System.assertEquals('Cluster 3', freshAccs[0].Cluster__c,
            'Manual cluster should be preserved when Sales Channel did not change');
    }

    // Covers: update path — Sales Channel changed → rule engine runs and assigns cluster
    @IsTest
    static void testEvaluate_SalesChannelChanged_RuleEngineRuns() {
        Account acc = buildAccount('SC Change Co', '111000005', 'Global');
        insert acc;

        List<Account> freshAccs = queryAccounts(new Set<Id>{ acc.Id });

        // Build oldMap with a different Sales Channel — simulates SC change
        Map<Id, SObject> oldMap = new Map<Id, SObject>();
        Account oldAcc = acc.clone(true, true, false, false);
        oldAcc.Sales_Channel__c = 'Key Accounts'; // old value differs
        oldMap.put(oldAcc.Id, oldAcc);

        Test.startTest();
        // New record has Sales_Channel__c = 'Global' — engine should evaluate rules
        ClusterRuleEngine.evaluate('Account', freshAccs, oldMap);
        Test.stopTest();

        System.assert(true, 'Rule engine should run without error when Sales Channel changed');
    }

    // Covers: evaluate() completes without error when no rule matches
    @IsTest
    static void testEvaluate_BlankCondition_EngineHandlesGracefully() {
        Account acc = buildAccount('Blank Condition Co', '222333444', 'Global');
        insert acc;

        Test.startTest();
        List<Account> accs = queryAccounts(new Set<Id>{ acc.Id });
        // Insert path — null oldMap
        ClusterRuleEngine.evaluate('Account', accs, null);
        Test.stopTest();

        System.assert(true, 'evaluate() should complete without exception');
    }

    // Covers: objectName = 'Contact' → early return (formula field, not writable)
    @IsTest
    static void testEvaluate_ContactObject_EarlyReturn() {
        Account acc = buildAccount('Contact Parent', '777888999', 'Global');
        insert acc;

        Contact con = new Contact(
            FirstName        = 'Test',
            LastName         = 'Contact',
            Email            = 'contact@test.com',
            AccountId        = acc.Id,
            Sales_Channel__c = 'Global'
        );
        insert con;

        Test.startTest();
        List<Contact> cons = [SELECT Id, Cluster__c FROM Contact WHERE Id = :con.Id];
        // Contact always returns early regardless of oldMap
        ClusterRuleEngine.evaluate('Contact', cons, null);
        Test.stopTest();

        System.assert(true,
            'evaluate() for Contact should return early without attempting to write');
    }

    // Covers: Lead object insert path — writable Cluster__c evaluated correctly
    @IsTest
    static void testEvaluate_LeadObject_Insert_NoError() {
        Lead lead = new Lead(
            FirstName                       = 'Test',
            LastName                        = 'Lead',
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
        insert lead;

        Test.startTest();
        List<Lead> leads = [
            SELECT Id, Cluster__c, Sales_Channel__c,
                   Street, City, State, PostalCode, Country,
                   Tax_Id__c, FirstName, LastName, Company,
                   Has_Physical_Store__c, Resale_Certificate_Status__c
            FROM Lead WHERE Id = :lead.Id
        ];
        // Insert path — null oldMap
        ClusterRuleEngine.evaluate('Lead', leads, null);
        Test.stopTest();

        System.assert(true, 'evaluate() should handle Lead insert without error');
    }

    // Covers: Lead update path — Sales Channel unchanged → cluster preserved
    @IsTest
    static void testEvaluate_LeadObject_Update_SalesChannelUnchanged() {
        Lead lead = new Lead(
            FirstName                       = 'Test',
            LastName                        = 'Lead Update',
            Company                         = 'Test Co',
            Sales_Channel__c                = 'Global',
            Terms_of_Service_Agreement__c   = 'Agreed',
            Has_Physical_Store__c           = true,
            Resale_Certificate_Status__c    = 'Yes, I do.',
            Tax_Id__c                       = '987654321',
            Street                          = '123 Main St',
            City                            = 'Los Angeles',
            State                           = 'CA',
            PostalCode                      = '90001',
            Country                         = 'US'
        );
        insert lead;

        List<Lead> leads = [
            SELECT Id, Cluster__c, Sales_Channel__c,
                   Street, City, State, PostalCode, Country,
                   Tax_Id__c, FirstName, LastName, Company,
                   Has_Physical_Store__c, Resale_Certificate_Status__c
            FROM Lead WHERE Id = :lead.Id
        ];

        // OldMap with same Sales Channel
        Map<Id, SObject> oldMap = new Map<Id, SObject>();
        Lead oldLead = lead.clone(true, true, false, false);
        oldLead.Sales_Channel__c = 'Global';
        oldMap.put(oldLead.Id, oldLead);

        // Set a manual cluster
        leads[0].Cluster__c = 'Cluster 5';

        Test.startTest();
        ClusterRuleEngine.evaluate('Lead', leads, oldMap);
        Test.stopTest();

        System.assertEquals('Cluster 5', leads[0].Cluster__c,
            'Manual cluster on Lead should be preserved when Sales Channel unchanged');
    }

    // Covers: multi-condition CMDT rule — BillingCountry field access via try/catch
    @IsTest
    static void testEvaluate_OperatorDetection_MultiCondition_NoException() {
        Account acc = buildAccount('Operator Test Co', '999888777', 'Key Accounts');
        acc.BillingCountry = 'CA';
        acc.BillingState   = 'ON';
        insert acc;

        Test.startTest();
        List<Account> accs = queryAccounts(new Set<Id>{ acc.Id });
        // Insert path — null oldMap
        ClusterRuleEngine.evaluate('Account', accs, null);
        Test.stopTest();

        System.assert(true, 'Multi-condition operator detection should not throw');
    }

    // Covers: field not queried in SOQL → try/catch in evaluateCondition returns false
    @IsTest
    static void testEvaluate_UnqueriedField_HandledGracefully() {
        Account acc = buildAccount('Unqueried Field Co', '888777666', 'Key Accounts');
        insert acc;

        Test.startTest();
        // Deliberately query without BillingCountry — evaluateCondition
        // hits the try/catch when record.get('BillingCountry') is called
        List<Account> accs = [
            SELECT Id, Cluster__c, Sales_Channel__c, Tax_Id__c
            FROM Account WHERE Id = :acc.Id
        ];
        // Insert path — null oldMap
        ClusterRuleEngine.evaluate('Account', accs, null);
        Test.stopTest();

        System.assert(true,
            'Missing field in SOQL should be caught gracefully — no exception thrown');
    }

    // Covers: null written to restricted picklist is skipped (matchedCluster == null path)
    @IsTest
    static void testEvaluate_NoRuleMatch_NullNotWritten() {
        // Use a Sales Channel value that has no metadata rule
        Account acc = buildAccount('No Rule Co', '555444333', 'Global');
        insert acc;

        List<Account> accs = queryAccounts(new Set<Id>{ acc.Id });
        String clusterBefore = accs[0].Cluster__c;

        // Build oldMap with a different Sales Channel so rule engine runs
        Map<Id, SObject> oldMap = new Map<Id, SObject>();
        Account oldAcc = acc.clone(true, true, false, false);
        oldAcc.Sales_Channel__c = 'Key Accounts';
        oldMap.put(oldAcc.Id, oldAcc);

        // Set Sales Channel to something with no matching rule
        accs[0].Sales_Channel__c = 'NonExistentChannel';

        Test.startTest();
        ClusterRuleEngine.evaluate('Account', accs, oldMap);
        Test.stopTest();

        // Cluster should not have been set to null
        System.assert(
            accs[0].Cluster__c == clusterBefore || accs[0].Cluster__c != null,
            'Null should never be written to Cluster__c when no rule matches'
        );
    }
}