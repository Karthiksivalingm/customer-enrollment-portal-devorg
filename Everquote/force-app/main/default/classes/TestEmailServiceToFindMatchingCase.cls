/**
    @Name               :	TestEmailServiceToFindMatchingCase
    @Date               :   05 Jan, 2016
    @Description        :   Test code for the class EmailServiceToFindMatchingCase
*/
@isTest
public class TestEmailServiceToFindMatchingCase implements HttpCalloutMock {

	static testMethod void myUnitTest() {
	    
	    /* Test to create a new case and send error email */
		// create a new email and envelope object
		Messaging.InboundEmail email = new Messaging.InboundEmail() ;
		Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
		
		// setup the data for the email
		email.subject = 'Email Delivery Issues Ticket 32514';
		email.fromAddress = 'someaddress@email.com';
		email.plainTextBody = 'email body';
		
		// add a Binary attachment
		Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
		attachment.body = blob.valueOf('my attachment text');
		attachment.fileName = 'textfileone.txt';
		attachment.mimeTypeSubType = 'text/plain';
		email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
		
		// add a Text atatchment
		Messaging.InboundEmail.TextAttachment attachmenttext = new Messaging.InboundEmail.TextAttachment();
		attachmenttext.body = 'my attachment text';
		attachmenttext.fileName = 'textfiletwo3.txt';
		attachmenttext.mimeTypeSubType = 'texttwo/plain';
		email.textAttachments =   new Messaging.inboundEmail.TextAttachment[] { attachmenttext };
		
		//Create an user
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
		
		User u = new User(Alias = 'trekSer', Email='testEmailService@testTrek.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
						  LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='testEmailService@testTrek.com'); 
		
		insert u;
		
		Test.startTest();
		
		// Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new TestEmailServiceToFindMatchingCase());
        
		Account objTestAcc = new Account(Name = 'Test Account');
		insert objTestAcc;
		
		Contact objContact = new Contact(AccountId = objTestAcc.Id, LastName = 'Test Contact', Email = 'someaddress@email.com');
		insert objContact;
		
		Test.stopTest();
		
		//Create custom setting record.
		Email_to_Case_Error_User__c cs = new Email_to_Case_Error_User__c();
		cs.Name = 'User ID';
		cs.User_ID_who_should_get_email__c = u.Id;
		insert cs;
		
		system.debug('---objTestAcc-----'+objTestAcc);
		system.debug('----objContact----'+objContact);
		
		// call the email service class and test it with the data in the testMethod
		EmailServiceToFindMatchingCase  testEmailService = new EmailServiceToFindMatchingCase();
		testEmailService.handleInboundEmail(email, env);
		
		List<Case> lstCases = [	SELECT Id, CaseNumber, Priority, AccountId, ContactId, (SELECT Subject, TextBody FROM EmailMessages) FROM Case];
		
		system.assertEquals(1, lstCases.size());
		
		Case objCase = lstCases[0];
		system.debug('----objCase----'+objCase);
		system.assertEquals('Medium', objCase.Priority);
		system.assertEquals(1, objCase.EmailMessages.size());
		system.assertEquals(objCase.AccountId, objTestAcc.Id);
		system.assertEquals(objCase.ContactId, objContact.Id);
		
		EmailMessage objEmailMessage = objCase.EmailMessages;
		
		system.assertEquals(objEmailMessage.subject, 'Email Delivery Issues Ticket 32514');
		system.assertEquals(objEmailMessage.TextBody, 'email body');
		/*----------------------------------------------------------------------------------------------------------------*/
		
		/*Test to find matching zendesk id*/
		system.debug('--------'+lstCases[0].CaseNumber);
		lstCases[0].Zendesk_ID__c = decimal.valueOf(lstCases[0].CaseNumber);
		update lstCases[0];
		
		// create a new email and envelope object
		Messaging.InboundEmail email5 = new Messaging.InboundEmail() ;
		Messaging.InboundEnvelope env5 = new Messaging.InboundEnvelope();
		
		// setup the data for the email
		email5.subject = 'Fwd: Email Delivery Issues Ticket '+lstCases[0].Zendesk_ID__c;
		email5.fromAddress = 'someaddress@email.com';
		email5.plainTextBody = 'email body';
		
		// call the email service class and test it with the data in the testMethod
		EmailServiceToFindMatchingCase  testEmailService5 = new EmailServiceToFindMatchingCase();
		testEmailService5.handleInboundEmail(email5, env5);
		
		List<Case> lstCases5 = [	SELECT Id, Priority, AccountId, ContactId, (SELECT Subject, TextBody FROM EmailMessages) FROM Case];
		
		system.assertEquals(1, lstCases5.size());
		
		Case objCase5 = lstCases5[0];
		system.assertEquals(2, objCase5.EmailMessages.size());
		
		/*----------------------------------------------------------------------------------------------------------------*/
		
		/* Test to match the ref id */
		
		// create a new email and envelope object
		Messaging.InboundEmail email2 = new Messaging.InboundEmail() ;
		Messaging.InboundEnvelope env2 = new Messaging.InboundEnvelope();
		
		// setup the data for the email
		email2.subject = 'Test [ ref:_'+ UserInfo.getOrganizationId().left(5)  + ''  + UserInfo.getOrganizationId().mid(11,4) +'._5007A1z123:ref ]';
		email2.fromAddress = 'someaddress@email.com';
		email2.plainTextBody = 'email body';
		
		// call the email service class and test it with the data in the testMethod
		EmailServiceToFindMatchingCase  testEmailService2 = new EmailServiceToFindMatchingCase();
		testEmailService2.handleInboundEmail(email2, env2);
		
		List<Case> lstCases2 = [	SELECT Id, Priority, AccountId, ContactId, (SELECT Subject, TextBody FROM EmailMessages) FROM Case WHERE Id != :lstCases[0].Id];
		
		system.assertEquals(1, lstCases2.size());
		
		Case objCase2 = lstCases2[0];
		system.assertEquals(1, objCase2.EmailMessages.size());
		
		/*----------------------------------------------------------------------------------------------------------------*/
		
		/* Test when there is no subject*/
		
		// create a new email and envelope object
		Messaging.InboundEmail email7 = new Messaging.InboundEmail() ;
		Messaging.InboundEnvelope env7 = new Messaging.InboundEnvelope();
		
		// setup the data for the email
		email7.fromAddress = 'someaddress@email.com';
		email7.plainTextBody = 'email body';
		
		// call the email service class and test it with the data in the testMethod
		EmailServiceToFindMatchingCase  testEmailService7 = new EmailServiceToFindMatchingCase();
		testEmailService7.handleInboundEmail(email7, env7);
		
		List<Case> lstCases7 = [	SELECT Id, Priority, AccountId, ContactId, (SELECT Subject, TextBody FROM EmailMessages) FROM Case WHERE Id != :lstCases[0].Id AND id != :lstCases2[0].Id];
		
		system.assertEquals(0, lstCases7.size());
	}
	
	public static HTTPResponse respond(HTTPRequest req) {
		
		// Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"commandId":"bar"}');
        res.setStatusCode(200);
        return res;
	}
}