global class EmailToCaseReply implements Messaging.InboundEmailHandler {   
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email,Messaging.InboundEnvelope envelope) {        
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
		
        if((email.plainTextBody != Null && email.plainTextBody != '')){
            
        	//Log
        	EmailMessage newEmailMessage = new EmailMessage();
            
            String caseID;
            String caseID2;
            if(email.plainTextBody.substringBetween('|::', '::|')!=null){
                caseID = email.plainTextBody.substringBetween('|::', '::|').remove('*').trim();
            }
            else if(email.subject.substringBetween('|::', '::|')!=null){
                caseID = email.subject.substringBetween('|::', '::|').remove('*').trim();
            }
            else{  caseID = ''; }
            
            if(email.plainTextBody.substringBetween('|:|', '|:|')!=null){
                caseID2 = email.plainTextBody.substringBetween('|:|', '|:|').remove('*').trim();
            }
            else if(email.subject.substringBetween('|:|', '|:|')!=null){
                caseID2 = email.subject.substringBetween('|:|', '|:|').remove('*').trim();
            }
            else{ caseID2 = '';}
            
            if(caseID==''){caseID=caseID2;}
            
            //If no id found create case
            if(caseID=='' && email.fromName != 'dataandfortelliscases@cdk.com'){
                Case e2c = new Case();
                e2c.Case_Category__c = 'General Support';
                e2c.Description = email.plainTextBody;
                e2c.Description_Original__c = email.plainTextBody;
                e2c.Origin = 'Email';
                e2c.RecordTypeId = '0125f000000moYNAAY';
                e2c.Subject = email.subject;
                e2c.Subject_Original__c = email.subject;
                e2c.SuppliedEmail = email.fromAddress;
                e2c.SuppliedName = email.fromName;
                
                insert(e2c);
                
                List<Attachment> attList = new List<Attachment>();
                if(email.binaryAttachments!=null){
                    for(Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) {                  
                        Attachment attachment = new Attachment();
                        attachment.ParentId = e2c.Id;             
                        attachment.Name = bAttachment.fileName;
                        attachment.Body = bAttachment.body; 
                        attList.add(attachment);                                
                    }
                    if(attList.size()>0){
                        insert attList;     
                    }
                }
                newEmailMessage.CcAddress = email.ccAddresses.toString().replace('(', '').replace(')', '');
                newEmailMessage.FromAddress = email.fromAddress;
                newEmailMessage.FromName = email.fromName;
                newEmailMessage.Subject = email.subject;
                newEmailMessage.TextBody = email.plainTextBody;
                newEmailMessage.toAddress = email.toAddresses.toString().replace('(', '').replace(')', '');
                newEmailMessage.HtmlBody = email.htmlBody;
                newEmailMessage.ParentId = e2c.id;
                newEmailMessage.RelatedToId = e2c.id;
                
                insert newEmailMessage;
            }
            //Case ID found, attach this guy
            else{
                Internal_External_Note__c note = new Internal_External_Note__c(); 
                
                String emailFrom;
                List<String> emailCollectionCc = new List<String>();
               
                List<Internal_External_Note__c> noteb = new List<Internal_External_Note__c>();
                List<Attachment> attList = new List<Attachment>();
                
                emailFrom = email.FromAddress;           
                emailCollectionCc = email.ccAddresses;
                
                
                List<Case> CS=[Select id from Case where Case_18_ID__c=:caseID];
                    if(CS.size() > 0){
                        note.Case__c = CS[0].id;
                        newEmailMessage.ParentId = CS[0].id;
                        newEmailMessage.RelatedToId = CS[0].id;
                    }                
                    else{
                        note.Case__c = null;
                    }
                
                string comment = email.plainTextBody.substringBefore('|::').remove('*').trim();
                if(comment.contains('From: tvmsupport@salesforce.teamvelocitymarketing.com')){comment = comment.substringBefore('From: tvmsupport@salesforce.teamvelocitymarketing.com').remove('*').trim();}
                if(comment.contains('tvmsupport@salesforce.teamvelocitymarketing.com')){comment = comment.substringBefore('tvmsupport@salesforce.teamvelocitymarketing.com').remove('*').trim();}
    
                note.Note__c = comment;    
                note.External_Comment__c = true;
                
                if(emailFrom!=null){note.From_Email_Address__c = emailFrom;}
                if(emailCollectionCC!=null){note.CC_Email_Address__c = string.join(emailCollectionCc, '; ');}
                
                noteb.add(note);
                insert noteb;
                
                if(email.binaryAttachments!=null){
                    for(Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) {                  
                        Attachment attachment = new Attachment();
                        attachment.ParentId = note.Id;             
                        attachment.Name = bAttachment.fileName;
                        attachment.Body = bAttachment.body; 
                        attList.add(attachment);                   
                        System.debug('New member: '+ noteb);                   
                    } 
                    if(attList.size()>0){
                        insert attList;     
                    }
                    else if(attList==null ){ 
                        insert noteb;
                    }  
                }
                newEmailMessage.CcAddress = email.ccAddresses.toString();
                newEmailMessage.FromAddress = email.fromAddress;
                newEmailMessage.FromName = email.fromName;
                newEmailMessage.Subject = email.subject;
                newEmailMessage.TextBody = email.plainTextBody;
                newEmailMessage.toAddress = email.toAddresses.toString();
                newEmailMessage.HtmlBody = email.htmlBody;
                newEmailMessage.Internal_External_Note__c = note.Id;
                insert newEmailMessage;
            }
        }
        
		
        
        result.success = true;
        return result;
    }
}