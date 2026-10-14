@istest
public class inboundemailattachmentTest {   
    static testMethod void TestinBoundEmail() {
        
        
    	Test.setMock(HttpCalloutMock.class, new RestMock());   
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();       
          String acName;         
        List<String> emailCollectionTo = new List<String>{'sandip@unitedtechno.com,rhariharan955@gmail.com'};
        List<String> emailCollectionCc = new List<String>{'sandip@unitedtechno.com,rhariharan955@gmail.com ,rhari45@gmail.com'};        
            emailCollectionTo = email.toAddresses;           
            emailCollectionCc = email.ccAddresses;        
        List<Meeting_Recap__c> memb = new List<Meeting_Recap__c>();              
        List<Attachment> attList = new List<Attachment>();          
        Account acc1 = new Account();
        acc1.name ='inboundemailattachmentTest';
        insert acc1;             
        Meeting_Recap__c mem = new Meeting_Recap__c();         
        email.subject='MAY2023 Meeting Recap - Jeff-Wyler CDJR of Columbus';
        mem.Subject__c=email.subject;             
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];         
        User usr = new User(LastName = 'sandip',FirstName='sandip', Alias = 'sandip',Email = 'sandip@unitedtechno.com',Username = 'sandip@unitedtechno.com',ProfileId = profileId.id,     
                            TimeZoneSidKey = 'America/Los_Angeles',
                            EmailEncodingKey = 'UTF-8',
                            LanguageLocaleKey = 'en_US',
                            LocaleSidKey = 'en_US');
        insert usr;
        system.debug(usr);       
            String[] emailsub = email.subject.split('-');
            if(emailsub.size() >= 2){
                acName = emailsub[1].trim();
                system.debug('SL Account Name: '+acName);
            }
            else{
                acName = 'No account';
                system.debug('No Account: '+email.subject.split('-'));
            }            
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
          //email.plainTextBody = 'Action Items:Acquire more used vehicles & improve service business * Acquire more used vehicles & improve service business.Acquire more used vehicles & improve service business.Meeting Summary: Nissan New Port*Riche and Crystal Acquire more used vehicles & improve service business.Acquire more used vehicles * improve service business.Next Month Budget:$ 6857.005 Meeting Location:*In-person Attendees:abc Tentative Meeting Date: 12th Dec \n Thank You! And this has hopefully been a successful test.';        
          email.plainTextBody = 'Action Items: 	JR to get with digital team to see what is happening with disapproved Shopping adsCurrent Service offers attached.  Please let me know if we have any updates that are required due to fluctuations in pricing.   Please note, we can change prices for customers who are LOST or CONQUEST customersIncrease budgeted amount to $400 for shopping ads from the USED car total budget ($800).  Revise/expand geography once we finalize disapproved shopping ad issue.Meeting Summary: Shopping ads are performing well, but Nissan New Port*Riche and Crystal Acquire more used vehicles & improve service business.Acquire more used vehicles * improve service business.Next Month Budget:$ 6857.005 Meeting Location:*In-person Attendees:abc Tentative Meeting Date: 12th Dec \n Thank You! And this has hopefully been a successful test.';        
        if(email.plainTextBody!=null){

            string performaneSummary1 = email.plainTextBody.substringBetween('Action Items:' ,'Meeting Summary:').remove('*').trim();
            string focus1 = email.plainTextBody.substringBetween('Meeting Summary:','Next Month Budget:').remove('*').trim();
            //string ProjectedNextMonthbudget1 = email.plainTextBody.substringBetween('Next Month Budget:', 'Meeting Location:').remove('$').remove('*').remove(',').trim(); 
            string ProjectedNextMonthbudget1 = email.plainTextBody.substringBetween('Next Month Budget:', 'Meeting Location:').remove('*').trim(); 
            string MeetingLocation2  = email.plainTextBody.substringBetween('Meeting Location:', 'Attendees:').remove('*').trim();
            string Attendees = email.plainTextBody.substringBetween('Attendees:', 'Tentative Meeting Date:').remove('*').trim();
            string TentativeMeetingDate = email.plainTextBody.substringBetween('Tentative Meeting Date:', '\n').remove('*').trim();
                                      
                system.debug(MeetingLocation2);
                system.debug(focus1);
                system.debug(performaneSummary1);
                system.debug(ProjectedNextMonthbudget1);              
                mem.Meeting_Location__c = MeetingLocation2;
                mem.Focus__c= focus1;
                mem.Performance_Summary__c = performaneSummary1;
                //mem.Projected_Next_Month_budget__c = decimal.valueOf(ProjectedNextMonthbudget1);
                mem.Projected_Next_Month_budget__c = ProjectedNextMonthbudget1;
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
        FetchMeetingRecap testbound = new FetchMeetingRecap();
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