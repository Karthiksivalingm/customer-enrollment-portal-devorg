global class FetchMeetingRecap implements Messaging.InboundEmailHandler {   
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email,Messaging.InboundEnvelope envelope) {        
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();           
        if(email.plainTextBody != Null && email.plainTextBody != ''){ 
            String acName;
            Meeting_Recap__c mem = new Meeting_Recap__c(); 
            
            List<String> emailCollectionTo = new List<String>();
            List<String> emailCollectionCc = new List<String>();
           
            List<Meeting_Recap__c> memb = new List<Meeting_Recap__c>();
            List<Attachment> attList = new List<Attachment>();
            

            emailCollectionTo = email.toAddresses;           
            emailCollectionCc = email.ccAddresses;
            
            String[] emailsub = email.subject.split('-');
            if(emailsub.size() >= 2){
                if(emailsub.size() >= 2){ acName = emailsub[1].trim(); }
                if(emailsub.size() >= 3){ acName += emailsub[2].trim(); }
                if(emailsub.size() >= 4){ acName += emailsub[3].trim(); }
                
			system.debug('From Apex: ' + acName);
                acName= acName.replaceAll( '\\s+', '');
			system.debug('From Apex: ' + acName);
                acName= acName.replaceAll( '-', '');
			system.debug('From Apex: ' + acName);
                acName= acName.replaceAll( '\\.+', '');
			system.debug('From Apex: ' + acName);
            }
            else{
                acName = 'No account';
            }
            
			system.debug('From Apex: ' + acName);
            List<Account> Acc=[Select id, Name from Account where Account_Name_Trimmed__c=:acName and Client_Type_Team_V__c = 'Active'];
                if(Acc.size() > 0){
                    mem.Dealership__c = Acc[0].id;                    
                }                
                else{
                    mem.Dealership__c = null;
                }
          	
			system.debug('From Apex: ' + mem.Dealership__c);
            string emailfromAddress = email.fromAddress;

            List<user> us = [SELECT Id, Email, Name FROM User where Email=:emailfromAddress]; 
                if(us.size() > 0){
                    mem.From__c = us[0].Id;  
                }
                else{
                    mem.From__c = null;
                }              
            
            
            string fullemail = email.plainTextBody;
            
            if(email.plainTextBody.indexOf('Campaign Deployments:') == -1){
            String invalidNumbers = '[^0-9, "."]'; 
                
            string MeetingDate = ''; 
            if(email.plainTextBody.substringBetween('Meeting Date:' ,'Meeting Location:') != Null){
                	MeetingDate = email.plainTextBody.substringBetween('Meeting Date:' ,'Meeting Location:').remove('*').trim();
            	}
            string MeetingLocation2 = '';
                if(email.plainTextBody.substringBetween('Meeting Location:','Attendees:') != Null){
                    MeetingLocation2 = email.plainTextBody.substringBetween('Meeting Location:','Attendees:').remove('*').trim();
                }
            string Attendees = '';
                if(email.plainTextBody.substringBetween('Attendees:', '\n') != Null){
                    Attendees = email.plainTextBody.substringBetween('Attendees:', '\n').remove('*').trim();
                } 
            //string MeetingLocation2  = email.plainTextBody.substringBetween('Meeting Location:', 'Attendees:').remove('*').trim();
            //string Attendees = email.plainTextBody.substringBetween('Attendees:', 'Tentative Meeting Date:').remove('*').trim();
            //string MetingDate = email.plainTextBody.substringBetween('Tentative Meeting Date:', '\n').remove('*').trim();
                       
            system.debug(MeetingLocation2);
            //system.debug(focus1);
            //system.debug(performaneSummary1);
            //system.debug(ProjectedNextMonthbudget1);
            
                
                //set the fields
            mem.Record_Type__c = 'Normal';
            mem.Subject__c = email.subject;
            mem.Meeting_Location__c = MeetingLocation2;
            //mem.Focus__c= focus1;
            //mem.Performance_Summary__c = performaneSummary1;
            //mem.Projected_Next_Month_budget__c = decimal.valueOf(ProjectedNextMonthbudget2);
            //mem.Projected_Next_Month_budget__c = ProjectedNextMonthbudget1;
            mem.Attendees__c = Attendees;
            mem.Tentative_Meeting_Date__c = MeetingDate; 
            
           	
            }
            else{
                //Start here
            string CampaignDeployments1 = '';
                if(email.plainTextBody.substringBetween('Campaign Deployments:', 'Sales Email:') != Null){
                    CampaignDeployments1 = email.plainTextBody.substringBetween('Campaign Deployments:', 'Sales Email:').remove('*').trim();
                }
            string SalesEmail1 =  '';
                if(email.plainTextBody.substringBetween('Sales Email:', 'Sales Mail:') != Null){
                    SalesEmail1 = email.plainTextBody.substringBetween('Sales Email:', 'Sales Mail:').remove('*').trim();
                }
            string SalesMail1 =  '';
                if(email.plainTextBody.substringBetween('Sales Mail:', 'Service Email:') != Null){
                    SalesMail1 = email.plainTextBody.substringBetween('Sales Mail:', 'Service Email:').remove('*').trim();
                }
            string ServiceEmail1 =  '';
                if(email.plainTextBody.substringBetween('Service Email:', 'Service Mail:') != Null){
                    ServiceEmail1 = email.plainTextBody.substringBetween('Service Email:', 'Service Mail:').remove('*').trim();
                }
            string ServiceMail1 =  '';
                if(email.plainTextBody.substringBetween('Service Mail:', 'Other Highlights:') != Null){
                    ServiceMail1 = email.plainTextBody.substringBetween('Service Mail:', 'Other Highlights:').remove('*').trim();    
                }
 	  		string OtherHighlights1 =  '';
                if(email.plainTextBody.substringBetween('Other Highlights:', 'Recommendations:') != Null){
                    OtherHighlights1 = email.plainTextBody.substringBetween('Other Highlights:', 'Recommendations:').remove('*').trim();   
                }
			string Recomendations1;
				if(email.plainTextBody.indexOf('*REMINDER*')>-1){
		    		Recomendations1 = email.plainTextBody.substringBetween('Recommendations:', '*REMINDER*').remove('*').trim();
			}

			else{

			Recomendations1 = email.plainTextBody.substringBetween('Recommendations:', 'Next Month Budget:').remove('*').trim();

			}

      		string ProjectedNextMonthbudget1 = email.plainTextBody.substringBetween('Next Month Budget:', 'Meeting Location:').remove('*').trim(); 
            string MeetingLocation2  = email.plainTextBody.substringBetween('Meeting Location:', 'Attendees:').remove('*').trim();
            string Attendees = email.plainTextBody.substringBetween('Attendees:', 'Tentative Meeting Date:').remove('*').trim();
            string TentativeMeetingDate = email.plainTextBody.substringBetween('Tentative Meeting Date:', '\n').remove('*').trim();
             
            mem.Record_Type__c = 'Ford Direct';    
            mem.Subject__c = email.subject;
            mem.Meeting_Location__c = MeetingLocation2;
            mem.Campaign_Deployments__c = CampaignDeployments1;    
            mem.Sales_Email__c = SalesEmail1;
            mem.Sales_Mail__c = SalesMail1;    
            mem.Service_Email__c = ServiceEmail1;
            mem.Service_Mail__c = ServiceMail1;    
            mem.Other_Highlights__c = OtherHighlights1;
            mem.Recommendations__c = Recomendations1;
            mem.Projected_Next_Month_budget__c = ProjectedNextMonthbudget1;
            mem.Attendees__c = Attendees;
            mem.Tentative_Meeting_Date__c = TentativeMeetingDate; 
                //End Here
            }   
                
            mem.Description__c = fullemail;
            
            if(emailCollectionTo != null){
                mem.To__c = string.join(emailCollectionTo, '; ');
                system.debug(mem.To__c);
            }
            if(emailCollectionCc != null){
                mem.CC__c = string.join(emailCollectionCc, '; ');
                system.debug(mem.CC__c);
            }
            
            memb.add(mem);
            insert memb;
            if(email.binaryAttachments!=null){
                for(Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) {                  
                    Attachment attachment = new Attachment();
                    attachment.ParentId = mem.Id;             
                    attachment.Name = bAttachment.fileName;
                    attachment.Body = bAttachment.body; 
                    attList.add(attachment);                   
                    System.debug('New member: '+ memb);                   
                } 
                if(attList.size()>0){
                    insert attList;     
                }
                else if(attList==null ){ 
                    insert memb;
                }  
            }
        }     
        
        result.success = true;
        return result;
    }
}