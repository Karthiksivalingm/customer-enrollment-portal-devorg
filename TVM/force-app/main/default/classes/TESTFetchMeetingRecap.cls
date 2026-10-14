@istest
public class TESTFetchMeetingRecap {   
    static testMethod void TestinBoundEmail() {
        
        
    	Test.setMock(HttpCalloutMock.class, new RestMock());   
       
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();  
        Messaging.InboundEmail email2 = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env2 = new Messaging.InboundEnvelope();
          String acName;         
        List<String> emailCollectionTo = new List<String>{'sandip@unitedtechno.com,rhariharan955@gmail.com'};
        List<String> emailCollectionCc = new List<String>{'sandip@unitedtechno.com,rhariharan955@gmail.com ,rhari45@gmail.com'};        
            emailCollectionTo = email.toAddresses;           
            emailCollectionCc = email.ccAddresses;        
        List<Meeting_Recap__c> memb = new List<Meeting_Recap__c>();  
        List<Meeting_Recap__c> memb2 = new List<Meeting_Recap__c>();
        List<Attachment> attList = new List<Attachment>();          
        Account acc1 = new Account();
        acc1.name ='TESTFetchMeetingRecap';
        insert acc1;             
        Meeting_Recap__c mem = new Meeting_Recap__c();  
        Meeting_Recap__c mem2 = new Meeting_Recap__c();  
        email.subject='MAY2023 Meeting Recap - Jeff-Wyler CDJR of Columbus';
        email2.subject='MAY2023 Meeting Recap - Jeff-Wyler CDJR of Columbus';
        mem.Subject__c=email.subject;        
        mem2.Subject__c=email2.subject; 
        User usr = [SELECT Id FROM User WHERE Email = 'sknox@teamvelocitymarketing.com' LIMIT 1]; 
        
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
        
        system.debug(usr);       
            String[] emailsub2 = email2.subject.split('-');
            if(emailsub2.size() >= 2){
                acName = emailsub2[1].trim();
                system.debug('SL Account Name: '+acName);
            }
            else{
                acName = 'No account';
                system.debug('No Account: '+email2.subject.split('-'));
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
                    mem2.From__c = us[0].Id;
                    system.debug(us);
                }
                else{
                    mem.From__c = null;
                    mem2.From__c = null;
                }    
        email2.plainTextBody = 'Thank you and your team for taking the time to meet. I have outlined a brief meeting summary for your review and any action items. Campaign Deployments: Sales Email: XX Emails Sent XXX emails were opened (XX.XX% email open rate) XX clicked (X.XX% engaged) Sales Mail: XXX Targeted Households X Sales | X Trades | XX Service Ros Service Email:  XXXX Emails SentXXX emails were opened (XX.XX% email open rate)XXX clicked (X.XX% engaged)Service Mail: XXX Targeted Households X Sales | X Trades | XX Service ROs Other Highlights:   •  (Replace with Bullets or Text or Combination of both) • (Replace with Bullets or Text or Combination of both) Recommendations: •              (Replace with Bullets or Text or Combination of both) •              (Replace with Bullets or Text or Combination of both)*REMINDER* There are weekly Apollo training sessions, on Tuesday {2pm EST}, Wednesday {5pm EST} and Thursday {2pm EST}. We recommend signing up for at least one session to garner basic knowledge of the Apollo dashboard. If you’d like to schedule a training session for yourself and/or your team you can do so here: https://calendly.com/apollouniversity/101 Next Month Budget: •              (Replace with Bullets or Text or Combination of both) •              (Replace with Bullets or Text or Combination of both)  Meeting Location: You must type the word "In-person" or "Virtual" in this slot Attendees: (Person 1, Person 2, Person 3) Tentative Meeting Date: (EX: June 18, 2023).\n'; 
          
        if(email2.plainTextBody!=null){

            string CampaignDeployments1 = email2.plainTextBody.substringBetween('Campaign Deployments:', 'Sales Email:').remove('*').trim();
            string SalesEmail1 = email2.plainTextBody.substringBetween('Sales Email:', 'Sales Mail:').remove('*').trim();
            //string SalesMail1 = email2.plainTextBody.substringBetween('Sales Mail:', 'Service Email:').remove('*').trim();
            string ServiceEmail1 = email2.plainTextBody.substringBetween('Service Email:', 'Service Mail:').remove('*').trim();
            string ServiceMail1 = email2.plainTextBody.substringBetween('Service Mail:', 'Other Highlights:').remove('*').trim();    
            string OtherHighlights1 = email2.plainTextBody.substringBetween('Other Highlights:', 'Recommendations:').remove('*').trim();    
            string Recomendations1 = email2.plainTextBody.substringBetween('Recommendations:', '*REMINDER*').remove('*').trim();
            string ProjectedNextMonthbudget12 = email2.plainTextBody.substringBetween('Next Month Budget:', 'Meeting Location:').remove('*').trim(); 
            string MeetingLocation22  = email2.plainTextBody.substringBetween('Meeting Location:', 'Attendees:').remove('*').trim();
            string Attendees2 = email2.plainTextBody.substringBetween('Attendees:', 'Tentative Meeting Date:').remove('*').trim();
            string TentativeMeetingDate2 = email2.plainTextBody.substringBetween('Tentative Meeting Date:', '\n').remove('*').trim();
            
      
                mem.Record_Type__c = 'Ford Direct';    
            mem2.Subject__c = email.subject;
            mem2.Meeting_Location__c = MeetingLocation22;
            mem2.Campaign_Deployments__c = CampaignDeployments1;    
            mem2.Sales_Email__c = SalesEmail1;
            //mem2.Sales_Mail__c = SalesMail1;    
            mem2.Service_Email__c = ServiceEmail1;
            mem2.Service_Mail__c = ServiceMail1;    
            mem2.Other_Highlights__c = OtherHighlights1;
            mem2.Recommendations__c = Recomendations1;
            mem2.Projected_Next_Month_budget__c = ProjectedNextMonthbudget12;
            mem2.Attendees__c = Attendees2;
            mem2.Tentative_Meeting_Date__c = TentativeMeetingDate2;
            
         if(emailCollectionTo != null){
                mem2.To__c = string.join(emailCollectionTo, '; ');
                system.debug(mem.To__c);
            }
            if(emailCollectionCc != null){
                mem2.CC__c = string.join(emailCollectionCc, '; ');
                system.debug(mem.CC__c);
            }                       
        memb2.add(mem2);          
        Messaging.InboundEmail.BinaryAttachment attachment2 = new Messaging.InboundEmail.BinaryAttachment();
        attachment2.body = blob.valueOf('my attachment text');
        attachment2.fileName = 'textfileone.txt';
        attachment2.mimeTypeSubType = 'text/plain';  
        email2.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment2 };             
            if(attachment2 ==null){
                insert memb2; 
            }
        insert memb2;
              
        
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
        FetchMeetingRecap testbound2 = new FetchMeetingRecap();
        testbound2.handleInboundEmail(email2,env2);
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