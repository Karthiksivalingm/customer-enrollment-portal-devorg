@isTest
public class LeadMergeServiceTest {
    
    @testSetup
    static void setup() {
        List<Lead> testLeads = new List<Lead>();
        
        for (Integer i = 0; i < 5; i++) {
            testLeads.add(new Lead(
                FirstName = 'John' + i,
                LastName = 'Doe' + i,
                Company = 'Test Company ' + i,
                Email = 'test' + i + '@example.com',
                Phone = '555000' + i,
                Status = 'New',
                Has_Physical_Store__c = true,
                Resale_Certificate_Status__c = 'Yes, I do.',
                Terms_of_Service_Agreement__c = 'Test'
            ));
        }
        
        insert testLeads;
    }
    
    /*@isTest
    static void testMergeLeadsWithNote_Success() {
        Lead oldLead = new Lead(
            FirstName = 'Michael',
            LastName = 'Smith',
            Company = 'Old Company',
            Email = 'old@test.com',
            Phone = '5551234567',
            Status = 'Open - Not Contacted',
            Tax_Id__c = '123456789'
        );
        insert oldLead;
        
        Lead newLead = new Lead(
            FirstName = 'Michael',
            LastName = 'Smith',
            Company = 'New Company',
            Email = 'new@test.com',
            Status = 'Working - Contacted',
            Website = 'https://example.com'
        );
        insert newLead;
        
        LeadMergeService.MergeRequest mr = new LeadMergeService.MergeRequest(newLead, oldLead);
        List<LeadMergeService.MergeRequest> requests = new List<LeadMergeService.MergeRequest>{ mr };
        
        Test.startTest();
        LeadMergeService.mergeLeadsWithNote(requests);
        Test.stopTest();
        
        Lead masterLead = [SELECT Id, FirstName, LastName, Company, Email, Phone, Website, Tax_Id__c 
                          FROM Lead WHERE Id = :newLead.Id];
        
        System.assertEquals('Michael', masterLead.FirstName);
        System.assertEquals('New Company', masterLead.Company);
        System.assertEquals('new@test.com', masterLead.Email);
        System.assertEquals('5551234567', masterLead.Phone);
        System.assertEquals('123456789', masterLead.Tax_Id__c);
        System.assertEquals('https://example.com', masterLead.Website);
        
        List<ContentNote> notes = [SELECT Id, Title, Content FROM ContentNote];
        System.assertEquals(4, notes.size());
        
        List<ContentDocumentLink> links = [SELECT Id, LinkedEntityId FROM ContentDocumentLink 
                                          WHERE LinkedEntityId IN (:newLead.Id)];
        System.assertEquals(1, links.size());
    }
    
    @isTest
    static void testMergeLeadsWithNote_MultipleLeads() {
        List<Lead> oldLeads = new List<Lead>();
        List<Lead> newLeads = new List<Lead>();
        
        for (Integer i = 0; i < 3; i++) {
            oldLeads.add(new Lead(
                FirstName = 'Old' + i,
                LastName = 'Lead' + i,
                Company = 'Company' + i,
                Status = 'Open - Not Contacted',
                Email = 'old' + i + '@test.com'
            ));
        }
        insert oldLeads;
        
        for (Integer i = 0; i < 3; i++) {
            newLeads.add(new Lead(
                FirstName = 'New' + i,
                LastName = 'Lead' + i,
                Company = 'NewCompany' + i,
                Status = 'Working - Contacted',
                Email = 'new' + i + '@test.com'
            ));
        }
        insert newLeads;
        
        List<LeadMergeService.MergeRequest> requests = new List<LeadMergeService.MergeRequest>();
        for (Integer i = 0; i < 3; i++) {
            requests.add(new LeadMergeService.MergeRequest(newLeads[i], oldLeads[i]));
        }
        
        Test.startTest();
        LeadMergeService.mergeLeadsWithNote(requests);
        Test.stopTest();
        
        List<ContentNote> notes = [SELECT Id FROM ContentNote];
        System.assertEquals(6, notes.size());
        
        Set<Id> leadIds = new Set<Id>();
        for (Lead l : newLeads) {
            leadIds.add(l.Id);
        }
        
        List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId IN :leadIds];
        System.assertEquals(3, links.size());
    }*/
    
    @isTest
    static void testCopyLeadForMerge_NewValuePriority() {
        Lead oldLead = new Lead(
            FirstName = 'Sarah',
            LastName = 'Johnson',
            Company = 'Old Corp',
            Email = 'old@test.com',
            Status = 'New',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert oldLead;
        
        Lead newLead = new Lead(
            FirstName = 'Sarah',
            LastName = 'Johnson',
            Company = 'New Corp',
            Status = 'New',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert newLead;
        
        LeadMergeService.MergeRequest mr = new LeadMergeService.MergeRequest(newLead, oldLead);
        
        Test.startTest();
        LeadMergeService.mergeLeadsWithNote(new List<LeadMergeService.MergeRequest>{ mr });
        Test.stopTest();
        
        Lead result = [SELECT FirstName, Company, Email FROM Lead WHERE Id = :newLead.Id];
        System.assertEquals('Sarah', result.FirstName);
        System.assertEquals('New Corp', result.Company);
        System.assertEquals('old@test.com', result.Email);
    }
    
    @isTest
    static void testCopyLeadForMerge_AllCustomFields() {
        Lead oldLead = new Lead(
            FirstName = 'Robert',
            LastName = 'Williams',
            Company = 'Test Company',
            Status = 'Open - Not Contacted',
            Tax_Id__c = '123456789',
            Is_Franchise__c = true,
            Resale_Number__c = 'RN123',
            Facebook__c = 'fb.com/old',
            Instagram__c = 'ig.com/old',
            Has_Physical_Store__c = true,
            Is_Tax_Exempt__c = false,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert oldLead;
        
        Lead newLead = new Lead(
            FirstName = 'Robert',
            LastName = 'Williams',
            Company = 'New Company',
            Status = 'Working - Contacted',
            Website = 'newsite.com',
            Twitter__c = 'twitter.com/new',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert newLead;
        
        LeadMergeService.MergeRequest mr = new LeadMergeService.MergeRequest(newLead, oldLead);
        
        Test.startTest();
        LeadMergeService.mergeLeadsWithNote(new List<LeadMergeService.MergeRequest>{ mr });
        Test.stopTest();
        
        Lead result = [SELECT Tax_Id__c, Is_Franchise__c, Website, Twitter__c, Has_Physical_Store__c 
                      FROM Lead WHERE Id = :newLead.Id];
        System.assertEquals('123456789', result.Tax_Id__c);
        System.assertEquals(true, result.Is_Franchise__c);
        System.assertEquals('newsite.com', result.Website);
        System.assertEquals('twitter.com/new', result.Twitter__c);
        System.assertEquals(true, result.Has_Physical_Store__c);
    }
    
    @isTest
    static void testMergeRequest_Constructor() {
        Lead lead1 = new Lead(
            FirstName = 'Test1', 
            LastName = 'Lead1', 
            Company = 'Company1', 
            Status = 'Open - Not Contacted', 
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        Lead lead2 = new Lead(
            FirstName = 'Test2', 
            LastName = 'Lead2', 
            Company = 'Company2', 
            Status = 'Open - Not Contacted', 
            Has_Physical_Store__c = true, 
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert new List<Lead>{ lead1, lead2 };
        
        Test.startTest();
        LeadMergeService.MergeRequest mr = new LeadMergeService.MergeRequest(lead1, lead2);
        Test.stopTest();
        
        System.assertEquals(lead1.Id, mr.newLead.Id);
        System.assertEquals(lead2.Id, mr.oldLead.Id);
    }
    
    @isTest
    static void testMergeLeadsWithNote_NullFields() {
        Lead oldLead = new Lead(
            FirstName = 'James',
            LastName = 'Brown',
            Company = 'Brown Inc',
            Status = 'New',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert oldLead;
        
        Lead newLead = new Lead(
            FirstName = 'James',
            LastName = 'Brown',
            Company = 'Brown LLC',
            Status = 'New',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert newLead;
        
        LeadMergeService.MergeRequest mr = new LeadMergeService.MergeRequest(newLead, oldLead);
        
        Test.startTest();
        LeadMergeService.mergeLeadsWithNote(new List<LeadMergeService.MergeRequest>{ mr });
        Test.stopTest();
        
        Lead result = [SELECT Id, Company FROM Lead WHERE Id = :newLead.Id];
        System.assertEquals('Brown LLC', result.Company);
    }
    
    @isTest
    static void testMergeLeadsWithNote_WithAllFields() {
        Lead oldLead = new Lead(
            FirstName = 'David',
            LastName = 'Miller',
            Company = 'Miller Corp',
            Email = 'david@old.com',
            Phone = '5559876543',
            Status = 'New',
            LeadSource = 'Web',
            Title = 'Manager',
            Tax_Id__c = '123456789',
            Is_Franchise__c = false,
            Resale_Number__c = 'RSL999',
            Website = 'oldsite.com',
            Facebook__c = 'fb.com/david',
            Instagram__c = 'ig.com/david',
            Twitter__c = 'twitter.com/david',
            Has_Physical_Store__c = true,
            Is_Tax_Exempt__c = true,
            Store_Square_Footage__c = 1000,
            Affinity_Brands__c = 'Brand A',
            Retailer_Communication_Opt_In__c = true,
            Terms_of_Service_Agreement__c = 'Yes',
            Final_Comments__c = 'Old comments',
            Resale_Certificate_Status__c = 'Yes, I do.'
        );
        insert oldLead;
        
        Lead newLead = new Lead(
            FirstName = 'David',
            LastName = 'Miller',
            Company = 'Miller LLC',
            Email = 'david@new.com',
            Status = 'Working - Contacted',
            LeadSource = 'Referral',
            Website = 'newsite.com',
            Final_Comments__c = 'New comments',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert newLead;
        
        LeadMergeService.MergeRequest mr = new LeadMergeService.MergeRequest(newLead, oldLead);
        
        Test.startTest();
        LeadMergeService.mergeLeadsWithNote(new List<LeadMergeService.MergeRequest>{ mr });
        Test.stopTest();
        
        Lead result = [SELECT Email, Website, Phone, LeadSource, Tax_Id__c, Title, Final_Comments__c 
                      FROM Lead WHERE Id = :newLead.Id];
        System.assertEquals('david@new.com', result.Email);
        System.assertEquals('newsite.com', result.Website);
        System.assertEquals('5559876543', result.Phone);
        System.assertEquals('Referral', result.LeadSource);
        System.assertEquals('123456789', result.Tax_Id__c);
        System.assertEquals('Manager', result.Title);
        System.assertEquals('New comments', result.Final_Comments__c);
    }
}