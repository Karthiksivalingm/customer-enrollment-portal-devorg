@isTest
public class EmailMessageTriggerHelperTest {
    
    @TestSetup
    static void setupTestData() {
        List<Lead> leads = new List<Lead>();
        
        leads.add(new Lead(
            FirstName = 'Test',
            LastName = 'Lead One',
            Company = 'Test Company 1',
            Email = 'testlead1@example.com',
            Status = 'New',
            Tax_ID__c = '123456789',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        ));
        
        insert leads;

        List<Case> cases = new List<Case>();
        
        cases.add(new Case(
            Subject = 'Test Case One',
            Status = 'New',
            Origin = 'Email'
        ));
        
        cases.add(new Case(
            Subject = 'Test Case Two',
            Status = 'Working',
            Origin = 'Email'
        ));
        
        insert cases;
    }

    @isTest
    static void testIncomingEmailUpdatesReplyReceived() {
        Lead testLead = [SELECT Id, Email, Email_Reply_Received__c FROM Lead WHERE Email = 'testlead1@example.com' LIMIT 1];
        
        EmailMessage incomingEmail = new EmailMessage(
            FromAddress = 'testlead1@example.com',
            ToAddress = 'company@example.com',
            Subject = 'Test Reply',
            TextBody = 'This is a test reply',
            Incoming = true
        );
        
        Test.startTest();
        insert incomingEmail;
        Test.stopTest();
        
        Lead updatedLead = [SELECT Id, Email_Reply_Received__c, Email_Sent__c FROM Lead WHERE Id = :testLead.Id];
        
        System.assertNotEquals(null, updatedLead.Email_Reply_Received__c, 'Email_Reply_Received__c should be updated');
        System.assertEquals(null, updatedLead.Email_Sent__c, 'Email_Sent__c should remain null');
    }
    
    @isTest
    static void testOutgoingEmailUpdatesEmailSent() {
        Lead testLead = [SELECT Id, Email, Email_Sent__c FROM Lead WHERE Email = 'testlead1@example.com' LIMIT 1];
        
        EmailMessage outgoingEmail = new EmailMessage(
            FromAddress = 'company@example.com',
            ToAddress = 'testlead1@example.com',
            Subject = 'Test Outgoing',
            TextBody = 'This is a test outgoing email',
            Incoming = false
        );
        
        Test.startTest();
        insert outgoingEmail;
        Test.stopTest();
        
        Lead updatedLead = [SELECT Id, Email_Reply_Received__c, Email_Sent__c FROM Lead WHERE Id = :testLead.Id];
        
        System.assertEquals(null, updatedLead.Email_Reply_Received__c, 'Email_Reply_Received__c should remain null');
        System.assertNotEquals(null, updatedLead.Email_Sent__c, 'Email_Sent__c should be updated');
    }

    @isTest
    static void testCaseIncomingEmailUpdatesReplyReceived() {
        Case testCase = [SELECT Id, Email_Reply_Received__c, Email_Sent__c FROM Case WHERE Subject = 'Test Case One' LIMIT 1];
        
        EmailMessage incomingEmail = new EmailMessage(
            ParentId = testCase.Id,
            FromAddress = 'client@example.com',
            ToAddress = 'company@example.com',
            Subject = 'Re: Test Case One',
            TextBody = 'This is a client reply',
            Incoming = true
        );
        
        Test.startTest();
        insert incomingEmail;
        Test.stopTest();
        
        Case updatedCase = [SELECT Id, Email_Reply_Received__c, Email_Sent__c FROM Case WHERE Id = :testCase.Id];
        
        System.assertNotEquals(null, updatedCase.Email_Reply_Received__c, 'Case Email_Reply_Received__c should be updated');
        System.assertEquals(null, updatedCase.Email_Sent__c, 'Case Email_Sent__c should remain null');
    }
    
    @isTest
    static void testCaseOutgoingEmailUpdatesEmailSent() {
        Case testCase = [SELECT Id, Email_Reply_Received__c, Email_Sent__c FROM Case WHERE Subject = 'Test Case Two' LIMIT 1];
        
        EmailMessage outgoingEmail = new EmailMessage(
            ParentId = testCase.Id,
            FromAddress = 'company@example.com',
            ToAddress = 'client@example.com',
            Subject = 'Re: Test Case Two',
            TextBody = 'This is our response',
            Incoming = false
        );
        
        Test.startTest();
        insert outgoingEmail;
        Test.stopTest();
        
        Case updatedCase = [SELECT Id, Email_Reply_Received__c, Email_Sent__c FROM Case WHERE Id = :testCase.Id];
        
        System.assertEquals(null, updatedCase.Email_Reply_Received__c, 'Case Email_Reply_Received__c should remain null');
        System.assertNotEquals(null, updatedCase.Email_Sent__c, 'Case Email_Sent__c should be updated');
    }
}