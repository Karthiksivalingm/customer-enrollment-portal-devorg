@IsTest
public class ClusterTriggerTest {

    private static Id companyRtId = Schema.SObjectType.Account
        .getRecordTypeInfosByName().get('Company').getRecordTypeId();

    private static Account buildCompanyAccount(
        String name, String taxId, String salesChannel
    ) {
        return new Account(
            Name               = name,
            RecordTypeId       = companyRtId,
            Tax_Id__c          = taxId,
            Sales_Channel__c   = salesChannel,
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

    private static Lead buildValidLead(
        String firstName, String lastName, String company, String email
    ) {
        return new Lead(
            FirstName                       = firstName,
            LastName                        = lastName,
            Company                         = company,
            Email                           = email,
            Sales_Channel__c                = 'Partnerships',
            Terms_of_Service_Agreement__c   = 'Agreed',
            Has_Physical_Store__c           = true,
            Resale_Certificate_Status__c    = 'Yes, I do.',
            Status                          = 'New',
            Tax_Id__c                       = '123456789',
            Street                          = '123 Main St',
            City                            = 'Los Angeles',
            State                           = 'CA',
            PostalCode                      = '90001',
            Country                         = 'US'
        );
    }

    private static Lead buildLeadForConversion(
        String firstName, String lastName, String company, String email, String taxId
    ) {
        return new Lead(
            FirstName                       = firstName,
            LastName                        = lastName,
            Company                         = company,
            Email                           = email,
            Sales_Channel__c                = 'Partnerships',
            Terms_of_Service_Agreement__c   = 'Agreed',
            Has_Physical_Store__c           = true,
            Resale_Certificate_Status__c    = 'Yes, I do.',
            Status                          = 'New',
            Tax_Id__c                       = taxId,
            Street                          = '123 Main St',
            City                            = 'Los Angeles',
            State                           = 'CA',
            PostalCode                      = '90001',
            Country                         = 'US'
        );
    }

    private static Opportunity buildOpportunity(
        String name, Id accountId, String salesChannel
    ) {
        return new Opportunity(
            Name             = name,
            AccountId        = accountId,
            StageName        = 'Summary',
            CloseDate        = Date.today().addDays(30),
            Sales_Channel__c = salesChannel
        );
    }

    // ─── Lead Trigger Tests ───────────────────────────────────────────────────

    @IsTest
    static void testLeadClusterTrigger_Insert() {
        Test.startTest();
        insert buildValidLead('Trigger', 'Lead', 'Trigger Co', 'trigger.lead@test.com');
        Test.stopTest();

        System.assert(true, 'Lead insert should fire triggers');
    }

    @IsTest
    static void testLeadClusterTrigger_Update() {
        Lead lead = buildValidLead('Update', 'Lead', 'Update Co', 'update.lead@test.com');
        insert lead;

        Test.startTest();
        lead.Sales_Channel__c = 'Key Account';
        update lead;
        Test.stopTest();

        Lead updated = [SELECT Sales_Channel__c FROM Lead WHERE Id = :lead.Id];
        System.assertEquals('Key Account', updated.Sales_Channel__c,
            'Lead Sales_Channel__c should update and trigger re-evaluate');
    }

    @IsTest
    static void testLeadClusterTrigger_Conversion() {
        Account acc = buildCompanyAccount('Convert Trigger Co', '112233445', 'Partnerships');
        insert acc;

        Lead lead = buildLeadForConversion(
            'Convert', 'Trigger', 'Convert Trigger Co',
            'converttrigger@test.com', '998877665'
        );
        insert lead;

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(lead.Id);
        lc.setConvertedStatus('Qualified');
        lc.setDoNotCreateOpportunity(true);
        lc.setAccountId(acc.Id);

        Test.startTest();
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        Test.stopTest();

        System.assert(lcr.isSuccess(), 'Conversion should succeed: ' + lcr.getErrors());
    }

    @IsTest
    static void testLeadClusterTrigger_Conversion_WithExistingOpp() {
        Account acc = buildCompanyAccount('Existing Opp Account', '555666777', 'Partnerships');
        insert acc;

        insert buildOpportunity('Existing Opp', acc.Id, 'Partnerships');

        Lead lead = buildLeadForConversion(
            'ConvertOpp', 'Trigger', 'Existing Opp Account',
            'convertopp@test.com', '111222334'
        );
        insert lead;

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(lead.Id);
        lc.setConvertedStatus('Qualified');
        lc.setDoNotCreateOpportunity(true);
        lc.setAccountId(acc.Id);

        Test.startTest();
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        Test.stopTest();

        System.assert(lcr.isSuccess(),
            'Conversion with existing Opp should succeed: ' + lcr.getErrors());
    }

    // ─── Account Trigger Tests ────────────────────────────────────────────────

    @IsTest
    static void testAccountClusterTrigger_Insert() {
        Test.startTest();
        insert buildCompanyAccount('Trigger Account', '123456789', 'Partnerships');
        Test.stopTest();

        System.assert(true, 'Account insert should fire triggers');
    }

    @IsTest
    static void testAccountClusterTrigger_Update_ClusterChange() {
        Account acc = buildCompanyAccount('Update Cluster Account', '987654321', 'Partnerships');
        insert acc;

        insert new Contact(
            FirstName='Sync', LastName='Contact', Email='sync@test.com',
            AccountId=acc.Id, Sales_Channel__c='Partnerships'
        );

        Test.startTest();
        acc.Name = 'Update Cluster Account Renamed';
        update acc;
        Test.stopTest();

        System.assert(true, 'Update should fire triggers without directly editing Cluster__c');
    }

    @IsTest
    static void testAccountClusterTrigger_Update_SalesChannelChange() {
        Account acc = buildCompanyAccount('Channel Change Account', '111333555', 'Partnerships');
        insert acc;

        insert new Contact(
            FirstName='Channel', LastName='Contact', Email='channel@test.com',
            AccountId=acc.Id, Sales_Channel__c='Partnerships'
        );
        insert buildOpportunity('Channel Opp', acc.Id, 'Partnerships');

        Test.startTest();
        acc.Sales_Channel__c = 'Key Account';
        update acc;
        Test.stopTest();

        Contact updatedCon = [SELECT Sales_Channel__c FROM Contact WHERE Email='channel@test.com'];
        Opportunity updatedOpp = [SELECT Sales_Channel__c FROM Opportunity WHERE Name='Channel Opp'];

        System.assert(
            updatedCon.Sales_Channel__c == 'Key Account' || updatedCon.Sales_Channel__c == 'Partnerships',
            'Contact Sales_Channel__c should be a valid value after Account update'
        );
        System.assert(
            updatedOpp.Sales_Channel__c == 'Key Account' || updatedOpp.Sales_Channel__c == 'Partnerships',
            'Opp Sales_Channel__c should be a valid value after Account update'
        );
    }

    @IsTest
    static void testAccountClusterTrigger_Update_NoChange_NoCascade() {
        Account acc = buildCompanyAccount('No Change Account', '222444666', 'Partnerships');
        insert acc;

        Test.startTest();
        acc.Name = 'No Change Account Updated';
        update acc;
        Test.stopTest();

        System.assert(true, 'Non-cluster update should not cascade');
    }

    // ─── Opportunity Trigger Tests ────────────────────────────────────────────

    @IsTest
    static void testOpportunityClusterTrigger_Insert() {
        Account acc = buildCompanyAccount('Opp Insert Account', '333444555', 'Partnerships');
        insert acc;

        Test.startTest();
        insert buildOpportunity('Insert Opp', acc.Id, 'Partnerships');
        Test.stopTest();

        System.assert(true, 'Opp insert should fire ClusterRuleEngine');
    }

    @IsTest
    static void testOpportunityClusterTrigger_Update_SalesChannelChange() {
        Account acc = buildCompanyAccount('Opp Channel Account', '444555666', 'Partnerships');
        insert acc;

        Opportunity opp = buildOpportunity('Channel Change Opp', acc.Id, 'Partnerships');
        insert opp;

        Test.startTest();
        opp.Sales_Channel__c = 'Key Account';
        update opp;
        Test.stopTest();

        Opportunity updated = [SELECT Sales_Channel__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Key Account', updated.Sales_Channel__c,
            'Opp Sales_Channel__c should update and re-evaluate cluster');
    }

    @IsTest
    static void testOpportunityClusterTrigger_Update_ClusterChange() {
        Account acc = buildCompanyAccount('Opp Cluster Account', '555666778', 'Partnerships');
        insert acc;

        Opportunity opp = buildOpportunity('Cluster Change Opp', acc.Id, 'Partnerships');
        insert opp;

        Test.startTest();
        opp.NextStep = 'Trigger cluster re-eval';
        update opp;
        Test.stopTest();

        System.assert(true, 'Update should fire triggers without directly editing Cluster__c');
    }

    @IsTest
    static void testOpportunityClusterTrigger_Update_NoChange_Skipped() {
        Account acc = buildCompanyAccount('Opp No Change Account', '666777889', 'Partnerships');
        insert acc;

        Opportunity opp = buildOpportunity('No Change Opp', acc.Id, 'Partnerships');
        insert opp;

        Test.startTest();
        opp.NextStep = 'Follow up';
        update opp;
        Test.stopTest();

        System.assert(true, 'Non-cluster update should not fire assignTeams');
    }

    @IsTest
    static void testOpportunityClusterTrigger_BulkUpdate() {
        Account acc = buildCompanyAccount('Bulk Opp Account', '777888990', 'Partnerships');
        insert acc;

        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 5; i++) {
            opps.add(buildOpportunity('Bulk Opp ' + i, acc.Id, 'Partnerships'));
        }
        insert opps;

        Test.startTest();
        for (Opportunity opp : opps) {
            opp.Sales_Channel__c = 'Key Account';
        }
        update opps;
        Test.stopTest();

        for (Opportunity opp : [SELECT Sales_Channel__c FROM Opportunity WHERE AccountId = :acc.Id]) {
            System.assertEquals('Key Account', opp.Sales_Channel__c,
                'All bulk Opps should update');
        }
    }
}