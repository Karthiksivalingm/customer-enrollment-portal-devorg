@istest
public class TESTFetchCoreVital {   
    static testMethod void TestinBoundEmail() {
        
        
    	Test.setMock(HttpCalloutMock.class, new RestMock());   
       
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();  
        
          String acName;         
        List<String> emailCollectionTo = new List<String>{'dchen@teamvelocitymarketing.com'};    
        List<String> emailCollectionCc = new List<String>{'dchen@teamvelocitymarketing.com,sknox@teamvelocitymarketing.com'};    
            email.toAddresses = emailCollectionTo;           
            email.ccAddresses = emailCollectionCc;        
        List<Core_Vitals__c> memb = new List<Core_Vitals__c>();  
        List<Attachment> attList = new List<Attachment>();          
        Account acc1 = new Account();
        acc1.name ='TESTFetchCoreVital';
        insert acc1;             
        Core_Vitals__c mem = new Core_Vitals__c();  
        
        email.subject='MAY2023 Meeting Recap - Jeff-Wyler CDJR of Columbus';   
        
        User usr = [SELECT Id FROM User WHERE Email = 'sknox@teamvelocitymarketing.com' LIMIT 1]; 
        
            List<Account> Acc=[Select id, Name from Account where Name=:acName];
        system.debug(Acc);
                if(Acc.size() > 0){
                    mem.Dealership__c = Acc[0].id;                    
                }                
                else{
                    mem.Dealership__c = null;
                }          
            string emailfromAddress = 'sandipp@unitedtechno.com';

            List<user> us = [SELECT Id, Email, Name FROM User where Email=:emailfromAddress]; 
                if(us.size() > 0){
                    mem.From__c = us[0].Id; 
                    system.debug(us);
                }
                else{
                    mem.From__c = null;
                }    
        email.plainTextBody = 'Greetings {{{Recipient.FirstName}}}, I’m excited for another great month. I’ve looked over a few key areas of your website to ensure your site is set and ready to go for the month. Below are the areas I looked at this month. Looking forward to reporting out on results during our monthly reporting meeting. Website URL for Review: xkcd.com'; 
          
       	if(email.plainTextBody!=null){

 			string fullemail = email.plainTextBody;
                            
            string WebURL4Review = ''; 
            if(email.plainTextBody.substringBetween('Website URL for Review:' ,'.com') != Null){
                	WebURL4Review = email.plainTextBody.substringBetween('Website URL for Review:' ,'.com').remove('*').trim();
            	}
                                      
            system.debug(WebURL4Review);              
            
			mem.Website_URL_for_Review__c = WebURL4Review;
                
             if(emailCollectionTo != null){
                    mem.To__c = string.join(emailCollectionTo, '; ');
                    system.debug(mem.To__c);
                }
                if(emailCollectionCc != null){
                    mem.CC__c = string.join(emailCollectionCc, '; ');
                    system.debug(mem.CC__c);
                }                       
        
                memb.add(mem);          
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfileone.txt';
        attachment.mimeTypeSubType = 'text/plain';  
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };             
            if(attachment ==null){
                insert memb; 
            }
        insert memb;
        Test.startTest();
        FetchCoreVital testbound = new FetchCoreVital();
        testbound.handleInboundEmail(email,env);
        Test.stopTest();
    }
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