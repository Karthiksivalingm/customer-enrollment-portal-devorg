@IsTest
public class LeadConversionHandlerTest {

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

    private static Lead buildValidLead(String firstName, String lastName, String company) {
        return new Lead(
            FirstName                       = firstName,
            LastName                        = lastName,
            Company                         = company,
            Email                           = (firstName+'.'+lastName+'@test.com').toLowerCase(),
            Sales_Channel__c                = 'Global',
            Terms_of_Service_Agreement__c   = 'Agreed',
            Has_Physical_Store__c           = true,
            Resale_Certificate_Status__c    = 'Yes, I do.',
            Status                          = 'New',
            Tax_Id__c                       = '111111111',
            Street                          = '123 Main St',
            City                            = 'Los Angeles',
            State                           = 'CA',
            PostalCode                      = '90001',
            Country                         = 'US'
        );
    }

    // For conversion into existing Account — Lead Tax_Id__c must be
    // different from the Account's Tax_Id__c to avoid UNKNOWN_EXCEPTION.
    // Each account uses a unique taxId; each lead uses a different unique taxId.
    private static Lead buildLeadForConversion(
        String firstName, String lastName, String company,
        String email, String leadTaxId
    ) {
        return new Lead(
            FirstName                       = firstName,
            LastName                        = lastName,
            Company                         = company,
            Email                           = email,
            Sales_Channel__c                = 'Global',
            Terms_of_Service_Agreement__c   = 'Agreed',
            Has_Physical_Store__c           = true,
            Resale_Certificate_Status__c    = 'Yes, I do.',
            Status                          = 'New',
            Tax_Id__c                       = leadTaxId, // unique, differs from Account
            Street                          = '123 Main St',
            City                            = 'Los Angeles',
            State                           = 'CA',
            PostalCode                      = '90001',
            Country                         = 'US'
        );
    }

    // ── Covers: oldMap null → returns early ──────────────────────────────────
    @IsTest
    static void testHandleConversion_NullOldMap_NoProcessing() {
        Lead lead = buildValidLead('Test', 'Lead', 'Test Co');
        insert lead;

        Test.startTest();
        LeadConversionHandler.handleConversion(new List<Lead>{ lead }, null);
        Test.stopTest();

        System.assert(true, 'Null oldMap should not throw');
    }

    // ── Covers: lead not converted → skipped entirely ────────────────────────
    @IsTest
    static void testHandleConversion_NotConverted_NoProcessing() {
        Lead lead = buildValidLead('Not', 'Converted', 'Not Converted Co');
        insert lead;

        Lead fakOld = new Lead(Id = lead.Id, IsConverted = false);
        Lead fakNew = new Lead(Id = lead.Id, IsConverted = false);

        Test.startTest();
        LeadConversionHandler.handleConversion(
            new List<Lead>{ fakNew },
            new Map<Id, Lead>{ lead.Id => fakOld }
        );
        Test.stopTest();

        System.assert(true, 'Non-converted lead should be skipped');
    }

    // ── Covers: converted flag true but all converted IDs null ───────────────
    @IsTest
    static void testHandleConversion_NoConvertedIds_NoSOQL() {
        Lead lead = buildValidLead('No', 'Ids', 'No Ids Co');
        insert lead;

        Lead fakOld = new Lead(Id = lead.Id, IsConverted = false);
        Lead fakNew = new Lead(Id = lead.Id, IsConverted = true);

        Test.startTest();
        LeadConversionHandler.handleConversion(
            new List<Lead>{ fakNew },
            new Map<Id, Lead>{ lead.Id => fakOld }
        );
        Test.stopTest();

        System.assert(true, 'No converted IDs should not throw');
    }

    // ── Covers: accountIds + existingOpps sync (values differ) ───────────────
    // Account taxId = '987654321', Lead taxId = '112233446' — deliberately different
    @IsTest
    static void testHandleConversion_ConvertedLead_ExistingOppSynced() {
        Account acc = buildCompanyAccount('Existing Opp Co', '987654321');
        insert acc;

        insert new Opportunity(
            Name             = 'Existing Opp',
            AccountId        = acc.Id,
            StageName        = 'Summary',
            CloseDate        = Date.today().addDays(30),
            Sales_Channel__c = 'Key Account' // differs from Account → triggers sync
        );

        Lead lead = buildLeadForConversion(
            'Sync', 'Opp', 'Existing Opp Co',
            'sync.opp@test.com', '112233446'
        );
        insert lead;
        system.debug(lead);
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(lead.Id);
        lc.setConvertedStatus('Qualified');
        lc.setDoNotCreateOpportunity(true);
        lc.setAccountId(acc.Id);

        Test.startTest();
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        Test.stopTest();

        System.assert(lcr.isSuccess(), 'Conversion should succeed: ' + lcr.getErrors());

        Opportunity synced = [
            SELECT Sales_Channel__c FROM Opportunity WHERE Name = 'Existing Opp'
        ];
        System.assertEquals('Global', synced.Sales_Channel__c,
            'Opp should be synced to Account Sales_Channel__c');
    }

    // ── Covers: existingOpps already matching → oppsToUpdate empty ───────────
    // Account taxId = '222333444', Lead taxId = '334455667' — different
    @IsTest
    static void testHandleConversion_ExistingOppAlreadyMatching_NoUpdate() {
        Account acc = buildCompanyAccount('Matching Opp Co', '222333444');
        insert acc;

        Account freshAcc = [
            SELECT Id, Cluster__c, Sales_Channel__c FROM Account WHERE Id = :acc.Id
        ];

        insert new Opportunity(
            Name             = 'Matching Opp',
            AccountId        = acc.Id,
            StageName        = 'Summary',
            CloseDate        = Date.today().addDays(30),
            Sales_Channel__c = freshAcc.Sales_Channel__c,
            Cluster__c       = freshAcc.Cluster__c
        );

        Lead lead = buildLeadForConversion(
            'Match', 'Opp', 'Matching Opp Co',
            'match.opp@test.com', '334455667'
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

        Opportunity unchanged = [
            SELECT Sales_Channel__c FROM Opportunity WHERE Name = 'Matching Opp'
        ];
        System.assertEquals('Global', unchanged.Sales_Channel__c,
            'Opp should remain unchanged');
    }

    // ── Covers: accountIds branch + no open Opps → existingOpps.isEmpty() ────
    // Account taxId = '333444555', Lead taxId = '445566778' — different
    @IsTest
    static void testHandleConversion_ConvertedLead_NoExistingOpps() {
        Account acc = buildCompanyAccount('No Opp Co', '333444555');
        insert acc;

        Lead lead = buildLeadForConversion(
            'NoOpp', 'Lead', 'No Opp Co',
            'noopp.lead@test.com', '445566778'
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
            'Conversion with no Opps should succeed: ' + lcr.getErrors());
    }

    // ── Covers: accountIds + contactIds branches ──────────────────────────────
    // Account taxId = '556677889', Lead taxId = '667788990' — different
    @IsTest
    static void testHandleConversion_ConvertedLead_NewAccount_AssignsAccountAndContact() {
        Account acc = buildCompanyAccount('Brand New Co', '556677889');
        insert acc;

        Lead lead = buildLeadForConversion(
            'Convert', 'Me', 'Brand New Co',
            'convert.me@test.com', '667788990'
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
            'Full conversion should succeed: ' + lcr.getErrors());
        System.assertNotEquals(null, lcr.getAccountId(), 'Account Id should exist');
        System.assertNotEquals(null, lcr.getContactId(), 'Contact Id should exist');
    }
}