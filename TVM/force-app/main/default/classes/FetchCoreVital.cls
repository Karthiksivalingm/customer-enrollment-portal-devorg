global class FetchCoreVital implements Messaging.InboundEmailHandler {   
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email,Messaging.InboundEnvelope envelope) {        
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();           
        if(email.plainTextBody != Null && email.plainTextBody != ''){ 
            String acName;
            Core_Vitals__c mem = new Core_Vitals__c(); 
            
            List<String> emailCollectionTo = new List<String>();
            List<String> emailCollectionCc = new List<String>();
           
            List<Core_Vitals__c> memb = new List<Core_Vitals__c>();
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
                
            string WebURL4Review = ''; 
            if(email.plainTextBody.substringBetween('Website URL for Review:' ,'.com') != Null){
                	WebURL4Review = email.plainTextBody.substringBetween('Website URL for Review:' ,'.com').remove('*').trim() + '.com';
            	}
            
                
                //set the fields
            mem.Website_URL_for_Review__c = WebURL4Review;
            mem.Subject__c = email.subject;
            
           	
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