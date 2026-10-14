@isTest
public class LeadTriggerHandlerTest {

    @TestSetup
    static void setupTestData() {
        RecordType companyRT = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Account' AND DeveloperName = 'Company' 
            LIMIT 1
        ];
        
        List<Account> testAccounts = new List<Account>();
        testAccounts.add(new Account(
            Name = 'Existing Company 1',
            Tax_Id__c = '111111111',
            RecordTypeId = companyRT.Id
        ));
        testAccounts.add(new Account(
            Name = 'Existing Company 2',
            Tax_Id__c = '222222222',
            RecordTypeId = companyRT.Id
        ));
        insert testAccounts;
        
        List<Lead> existingLeads = new List<Lead>();
        existingLeads.add(new Lead(
            FirstName = 'Existing',
            LastName = 'Lead',
            Company = 'Existing Corp',
            Email = 'existing@test.com',
            Tax_Id__c = '333333333',
            Status = 'New',
            LeadSource = 'Googled It',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        ));
        existingLeads.add(new Lead(
            FirstName = 'Rejected',
            LastName = 'Lead',
            Company = 'Rejected Corp',
            Email = 'rejected@test.com',
            Tax_Id__c = '444444444',
            Status = 'Manual Rejection',
            LeadSource = 'PGA Show 2025',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        ));
        insert existingLeads;
    }
    
    @isTest
    static void testSetLeadSources_LeadForm() {
        Test.startTest();
        Lead newLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Email = 'test@test.com',
            LeadSource = 'Googled It',
            Tax_ID__c = '555555555',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert newLead;
        Test.stopTest();
        
        Lead updatedLead = [SELECT Source__c FROM Lead WHERE Id = :newLead.Id];
        System.assertEquals('Lead Form', updatedLead.Source__c);
    }
    
    @isTest
    static void testSetLeadSources_ContactForm() {
        Test.startTest();
        Lead newLead = new Lead(
            FirstName = 'Contact',
            LastName = 'Form',
            Company = 'Contact Company',
            Email = 'contact@test.com',
            LeadSource = 'Web',
            Tax_ID__c = '555555555',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert newLead;
        Test.stopTest();
        
        Lead updatedLead = [SELECT Source__c FROM Lead WHERE Id = :newLead.Id];
        System.assertEquals('Contact Form', updatedLead.Source__c);
    }
    
    @isTest
    static void testRemoveSymbolsFromTaxId() {
        Test.startTest();
        Lead newLead = new Lead(
            FirstName = 'Tax',
            LastName = 'Test',
            Company = 'Tax Company',
            Email = 'tax@test.com',
            Tax_Id__c = '12-345-6789',
            LeadSource = 'Googled It',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert newLead;
        Test.stopTest();
        
        Lead updatedLead = [SELECT Tax_Id__c FROM Lead WHERE Id = :newLead.Id];
        System.assertEquals('123456789', updatedLead.Tax_Id__c);
    }
    
    @isTest
    static void testAccountAlreadyExist() {
        Test.startTest();
        Lead newLead = new Lead(
            FirstName = 'Account',
            LastName = 'Exist',
            Company = 'Exist Company',
            Email = 'accountexist@test.com',
            Tax_Id__c = '111111111',
            LeadSource = 'Googled It',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert newLead;
        Test.stopTest();
        
        Lead updatedLead = [SELECT Status FROM Lead WHERE Id = :newLead.Id];
        System.assertEquals('Account Already Exist', updatedLead.Status);
        
        // ── CHANGE: Case creation was replaced with Api_Log__c creation ──
        // List<Case> cases = [SELECT Id FROM Case WHERE Origin = 'Lead'];
        // System.assertEquals(1, cases.size());

        // ── NEW: assert Api_Log__c is created instead of Case ──
        List<Api_Log__c> logs = [
            SELECT Id, Context__c, Log_Type__c, Related_Record_Id__c
            FROM Api_Log__c
            WHERE Context__c = 'Lead Rejected - Account Already Exists'
            AND Related_Record_Id__c = :newLead.Id
        ];
        System.assertEquals(1, logs.size(), 'An Api_Log__c should be created instead of a Case');
        System.assertEquals('Lead Duplicate', logs[0].Log_Type__c, 'Log_Type__c should be Lead Duplicate');
    }
    
    @isTest
    static void testDuplicateLead_ByTaxId() {
        Test.startTest();
        Lead duplicateLead = new Lead(
            FirstName = 'Duplicate',
            LastName = 'TaxId',
            Company = 'Duplicate Company',
            Email = 'duplicate@test.com',
            Tax_Id__c = '333333333',
            LeadSource = 'PGA Show 2025',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert duplicateLead;
        Test.stopTest();
        
        Lead updatedLead = [SELECT Status FROM Lead WHERE Id = :duplicateLead.Id];
        System.assertEquals('Duplicate Entry', updatedLead.Status);
    }
    
    @isTest
    static void testDuplicateLead_ByEmail() {
        Test.startTest();
        Lead duplicateLead = new Lead(
            FirstName = 'Duplicate',
            LastName = 'Email',
            Company = 'Duplicate Company',
            Email = 'existing@test.com',
            Tax_Id__c = '999999999',
            LeadSource = 'Surf Expo 2025',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert duplicateLead;
        Test.stopTest();
        
        Lead updatedLead = [SELECT Status FROM Lead WHERE Id = :duplicateLead.Id];
        System.assertEquals('Duplicate Entry', updatedLead.Status);
    }
    
    @isTest
    static void testManualRejection() {
        Lead testLead = new Lead(
            FirstName = 'Manual',
            LastName = 'Reject',
            Company = 'Reject Company',
            Email = 'reject@test.com',
            Tax_Id__c = '666666666',
            Status = 'New',
            LeadSource = 'Other',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert testLead;
        
        Test.startTest();
        testLead.Status = 'Manual Rejection';
        update testLead;
        Test.stopTest();
        
        // ── CHANGE: Case creation was replaced with Api_Log__c creation ──
        // List<Case> cases = [SELECT Type FROM Case WHERE Type = 'Manual Rejection'];
        // System.assertEquals(1, cases.size());

        // ── NEW: assert Api_Log__c is created instead of Case ──
        List<Api_Log__c> logs = [
            SELECT Id, Context__c, Log_Type__c, Related_Record_Id__c
            FROM Api_Log__c
            WHERE Context__c = 'Lead Manually Rejected'
            AND Related_Record_Id__c = :testLead.Id
        ];
        System.assertEquals(1, logs.size(), 'An Api_Log__c should be created instead of a Case');
        System.assertEquals('Manual Rejection', logs[0].Log_Type__c, 'Log_Type__c should be Manual Rejection');
    }
    
    @isTest
    static void testBulkInsert() {
        List<Lead> bulkLeads = new List<Lead>();
        for (Integer i = 0; i < 200; i++) {
            bulkLeads.add(new Lead(
                FirstName = 'Bulk',
                LastName = 'Lead' + i,
                Company = 'Bulk Company ' + i,
                Email = 'bulk' + i + '@test.com',
                Tax_Id__c = '10000000' + i,
                LeadSource = 'Googled It',
                Has_Physical_Store__c = true,
                Resale_Certificate_Status__c = 'Yes, I do.',
                Terms_of_Service_Agreement__c = 'Test'
            ));
        }
        
        Test.startTest();
        insert bulkLeads;
        Test.stopTest();
        
        List<Lead> insertedLeads = [SELECT Id, Source__c FROM Lead WHERE LastName LIKE 'Lead%'];
        System.assertEquals(202, insertedLeads.size()); //200 here + 2 in Setup
        
        for (Lead l : insertedLeads) {
            System.assertEquals('Lead Form', l.Source__c);
        }
    }
    
    @isTest
    static void testHandleAfterUpdate_TaxIdChange() {
        Lead testLead = new Lead(
            FirstName = 'Update',
            LastName = 'Test',
            Company = 'Update Company',
            Email = 'update@test.com',
            Tax_Id__c = '555000000',
            Status = 'Working',
            LeadSource = 'Customer Referral',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert testLead;
        
        Test.startTest();
        testLead.Tax_Id__c = '555000001';
        update testLead;
        Test.stopTest();
        
        Lead updatedLead = [SELECT Tax_Id__c FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('555000001', updatedLead.Tax_Id__c);
    }
    
    @isTest
    static void testMultipleLeadSources() {
        List<Lead> leads = new List<Lead>();
        
        leads.add(new Lead(
            FirstName = 'Source1',
            LastName = 'Test',
            Company = 'Company1',
            Email = 'source1@test.com',
            LeadSource = 'Sporting Event',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        ));
        
        leads.add(new Lead(
            FirstName = 'Source2',
            LastName = 'Test',
            Company = 'Company2',
            Email = 'source2@test.com',
            LeadSource = 'Retailer Referral',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        ));
        
        leads.add(new Lead(
            FirstName = 'Source3',
            LastName = 'Test',
            Company = 'Company3',
            Email = 'source3@test.com',
            LeadSource = 'Back River Referral',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        ));
        
        Test.startTest();
        insert leads;
        Test.stopTest();
        
        List<Lead> insertedLeads = [SELECT Source__c FROM Lead WHERE Email LIKE 'source%@test.com'];
        for (Lead l : insertedLeads) {
            System.assertEquals('Lead Form', l.Source__c);
        }
    }
}