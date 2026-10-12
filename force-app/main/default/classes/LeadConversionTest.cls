@isTest
private class LeadConversionTest {

    @isTest
    static void testLeadConversion() {

        // ── Step 1 : Insert Lead ───────────────────────────────────────────────
        Lead l = new Lead(
            FirstName                     = 'John',
            LastName                      = 'Doe',
            Company                       = 'John Doe Corp',
            Email                         = 'john.doe@testdomain.com',
            Status                        = 'New',
            Tax_ID__c                     = '123456789',
            Terms_of_Service_Agreement__c = 'I agree',
            Has_Physical_Store__c         = true,
            Resale_Certificate_Status__c  = 'Yes, I do.',
            Sales_Channel__c              = 'Specialty'
        );
        insert l;

        // ── Step 2 : Fetch Converted Status from Org ───────────────────────────
        LeadStatus convertedStatus = [
            SELECT MasterLabel
            FROM   LeadStatus
            WHERE  IsConverted = true
            LIMIT  1
        ];

        // ── Step 3 : Convert the Lead ──────────────────────────────────────────
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(l.Id);
        lc.setConvertedStatus(convertedStatus.MasterLabel);
        lc.setDoNotCreateOpportunity(false);
        lc.setOpportunityName('John Doe - Converted Opportunity');

        Test.startTest();
        Database.LeadConvertResult result = Database.convertLead(lc);
        Test.stopTest();

        // ── Step 4 : Assert Conversion Success ────────────────────────────────
        System.assert(result.isSuccess(),
            'Lead conversion should succeed. Errors: ' + result.getErrors());

        System.assertNotEquals(null, result.getAccountId(),
            'Account must be created on conversion');
        System.assertNotEquals(null, result.getContactId(),
            'Contact must be created on conversion');
        System.assertNotEquals(null, result.getOpportunityId(),
            'Opportunity must be created on conversion');

        // ── Step 5 : Verify Converted Lead ────────────────────────────────────
        Lead convertedLead = [
            SELECT Id, IsConverted,
                   ConvertedAccountId,
                   ConvertedContactId,
                   ConvertedOpportunityId
            FROM   Lead
            WHERE  Id = :l.Id
        ];

        System.assertEquals(true,                    convertedLead.IsConverted,             'Lead IsConverted should be true');
        System.assertEquals(result.getAccountId(),   convertedLead.ConvertedAccountId,      'ConvertedAccountId mismatch');
        System.assertEquals(result.getContactId(),   convertedLead.ConvertedContactId,      'ConvertedContactId mismatch');
        System.assertEquals(result.getOpportunityId(),convertedLead.ConvertedOpportunityId,'ConvertedOpportunityId mismatch');

        // ── Step 6 : Verify Created Account ───────────────────────────────────
        Account acc = [
            SELECT Id, Name
            FROM   Account
            WHERE  Id = :result.getAccountId()
        ];

        System.assertNotEquals(null, acc.Id,   'Account Id should not be null');
        System.assertNotEquals(null, acc.Name, 'Account Name should not be null');

        // ── Step 7 : Verify Created Contact ───────────────────────────────────
        Contact con = [
            SELECT Id, FirstName, LastName, Email, AccountId
            FROM   Contact
            WHERE  Id = :result.getContactId()
        ];

        System.assertEquals('John',               con.FirstName, 'Contact FirstName mismatch');
        System.assertEquals('Doe',                con.LastName,  'Contact LastName mismatch');
        System.assertEquals(result.getAccountId(), con.AccountId,'Contact AccountId mismatch');

        // ── Step 8 : Verify Created Opportunity ───────────────────────────────
        Opportunity opp = [
            SELECT Id, Name, AccountId, StageName, CloseDate
            FROM   Opportunity
            WHERE  Id = :result.getOpportunityId()
        ];

        System.assertEquals('John Doe - Converted Opportunity', opp.Name,      'Opp Name mismatch');
        System.assertEquals(result.getAccountId(),               opp.AccountId, 'Opp AccountId mismatch');
        System.assertNotEquals(null,                             opp.StageName, 'Opp StageName should be set');
        System.assertNotEquals(null,                             opp.CloseDate, 'Opp CloseDate should be set');
    }
}