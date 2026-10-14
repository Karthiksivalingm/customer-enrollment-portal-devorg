@istest
public class TESTEmailToCaseReply {   
    static testMethod void TestinBoundEmail() {
    	Test.setMock(HttpCalloutMock.class, new RestMock());   
       
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();  
        
        Messaging.InboundEmail email2 = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env2 = new Messaging.InboundEnvelope();  
        
        Messaging.InboundEmail email3 = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env3 = new Messaging.InboundEnvelope();  
        
        Messaging.InboundEmail email4 = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env4 = new Messaging.InboundEnvelope();  
        
        Messaging.InboundEmail email5 = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env5 = new Messaging.InboundEnvelope();  
        
        String acName;         
        String emailFrom = 'dchen@teamvelocitymarketing.com';
        List<String> emailCollectionCc = new List<String>{'dchen@teamvelocitymarketing.com'};       
        List<String> emailCollectionTo = new List<String>{'tvmsupport@teamvelocitymarketing.com'};       
            
        List<Internal_External_Note__c> noteb = new List<Internal_External_Note__c>();  
        List<Internal_External_Note__c> noteb2 = new List<Internal_External_Note__c>();  
        
        List<Attachment> attList = new List<Attachment>();          
        Case case1 = new Case();
        //case1.Name__c ='TESTFetchMeetingRecap';
        insert case1;             
        Internal_External_Note__c note = new Internal_External_Note__c();  
        Internal_External_Note__c note2 = new Internal_External_Note__c();  
        
        email.subject='Something Case Related';
        email2.subject='Something Case Related';
        email3.subject='Something Case Related';
        email4.subject='Something Case Related |::'+case1.Id+'::|';
        email5.subject='Something Case Related |:|'+case1.Id+'|:|';
        
        email.plainTextBody = 'Test Body |::'+case1.Id+'::|'; 
        email2.plainTextBody = 'Test Body |:|'+case1.Id+'|:|'; 
        email3.plainTextBody = 'Test Body'; 
        email4.plainTextBody = 'Test Body'; 
        email5.plainTextBody = 'Test Body'; 
        
        email.ccAddresses = emailCollectionCc; 
        email2.ccAddresses = emailCollectionCc;
        email3.ccAddresses = emailCollectionCc;
        email4.ccAddresses = emailCollectionCc;
        email5.ccAddresses = emailCollectionCc;
        
        email.toAddresses = emailCollectionTo; 
        email2.toAddresses = emailCollectionTo;
        email3.toAddresses = emailCollectionTo;
        email4.toAddresses = emailCollectionTo;
        email5.toAddresses = emailCollectionTo;
        
        note.Case__c = case1.Id;
        note2.Case__c = case1.Id;
 		
        string comment = email.plainTextBody.substringBefore('|::').remove('*').trim();
        if(comment.contains('From:tvmsupport@salesforce.teamvelocitymarketing.com')){comment = comment.substringBefore('From:tvmsupport@salesforce.teamvelocitymarketing.com').remove('*').trim();}
        if(comment.contains('tvmsupport@salesforce.teamvelocitymarketing.com')){comment = comment.substringBefore('tvmsupport@salesforce.teamvelocitymarketing.com').remove('*').trim();}

        string comment2 = email2.plainTextBody.substringBefore('|:|').remove('*').trim();
        
        note.Note__c = comment; 
        note.External_Comment__c = true;
        note.From_Email_Address__c = emailFrom;
        note.CC_Email_Address__c = string.join(emailCollectionCc, '; ');
            
        noteb.add(note);        
        
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfileone.txt';
        attachment.mimeTypeSubType = 'text/plain';  
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };             
            if(attachment ==null){
                insert noteb; 
            }
        insert noteb;
        
        
        note2.Note__c = comment; 
        note2.External_Comment__c = true;
        note2.From_Email_Address__c = emailFrom;
        note2.CC_Email_Address__c = string.join(emailCollectionCc, '; ');
            
        noteb2.add(note2);        
        
        insert noteb2;
        
        Test.startTest();
        EmailToCaseReply testbound = new EmailToCaseReply();
        testbound.handleInboundEmail(email,env);
        
        EmailToCaseReply testbound2 = new EmailToCaseReply();
        testbound2.handleInboundEmail(email2,env2);
        
        EmailToCaseReply testbound3 = new EmailToCaseReply();
        testbound3.handleInboundEmail(email3,env3);
        
        EmailToCaseReply testbound4 = new EmailToCaseReply();
        testbound4.handleInboundEmail(email4,env4);
        
        EmailToCaseReply testbound5 = new EmailToCaseReply();
        testbound5.handleInboundEmail(email5,env5);
        
        Test.stopTest();
    }
    private class RestMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            String fullJson = 'your Json Response';

            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        }
    }
}