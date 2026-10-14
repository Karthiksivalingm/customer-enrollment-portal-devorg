public inherited sharing class EmailMessageTriggerHelper {

    public static void processNewEmailMessages(List<EmailMessage> newEmailMessages) {
        List<EmailMessage> caseEmails = new List<EmailMessage>();
        List<EmailMessage> leadEmails = new List<EmailMessage>();
        
        for (EmailMessage email : newEmailMessages) {
            if (isCaseEmail(email)) {
                caseEmails.add(email);
            } else {
                leadEmails.add(email);
            }
        }
        
        if (!caseEmails.isEmpty()) {
            processCaseEmails(caseEmails);
        }
        
        if (!leadEmails.isEmpty()) {
            processLeadEmails(leadEmails);
        }
    }

    private static Boolean isCaseEmail(EmailMessage email) {
        return email.ParentId != null && email.ParentId.getSObjectType() == Case.SObjectType;
    }

    private static void processCaseEmails(List<EmailMessage> emails) {
        Set<Id> caseIds = new Set<Id>();
        Map<Id, List<EmailMessage>> caseIdToEmails = new Map<Id, List<EmailMessage>>();
        
        for (EmailMessage email : emails) {
            caseIds.add(email.ParentId);
            
            if (!caseIdToEmails.containsKey(email.ParentId)) {
                caseIdToEmails.put(email.ParentId, new List<EmailMessage>());
            }
            caseIdToEmails.get(email.ParentId).add(email);
        }
        
        if (caseIds.isEmpty()) {
            return;
        }
        
        List<Case> cases = [
            SELECT Id, Email_Reply_Received__c, Email_Sent__c 
            FROM Case 
            WHERE Id IN :caseIds
        ];
        
        List<Case> casesToUpdate = new List<Case>();
        
        for (Case c : cases) {
            if (caseIdToEmails.containsKey(c.Id)) {
                Boolean wasUpdated = false;
                
                for (EmailMessage email : caseIdToEmails.get(c.Id)) {
                    if (email.Incoming == true) {
                        c.Email_Reply_Received__c = System.now();
                        wasUpdated = true;
                    } else {
                        c.Email_Sent__c = System.now();
                        wasUpdated = true;
                    }
                }
                
                if (wasUpdated) {
                    casesToUpdate.add(c);
                }
            }
        }
        
        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
    }

    private static void processLeadEmails(List<EmailMessage> emails) {
        Set<String> emailAddresses = new Set<String>();
        Map<String, List<EmailMessage>> emailToMessages = new Map<String, List<EmailMessage>>();
        
        for (EmailMessage email : emails) {
            String fromAddress = extractEmailAddress(email);
            
            if (fromAddress != null) {
                emailAddresses.add(fromAddress);
                
                if (!emailToMessages.containsKey(fromAddress)) {
                    emailToMessages.put(fromAddress, new List<EmailMessage>());
                }
                emailToMessages.get(fromAddress).add(email);
            }
        }
        
        if (emailAddresses.isEmpty()) {
            return;
        }
        
        Map<String, Lead> emailToLead = findLeadsByEmail(emailAddresses);
        
        List<Lead> leadsToUpdate = updateLeadFields(emailToLead, emailToMessages);
        
        //  UPDATED PART (Safe DML - prevents failure)
        if (!leadsToUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(leadsToUpdate, false);
            
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for (Database.Error err : results[i].getErrors()) {
                        System.debug('Lead Update Failed for Id: ' + leadsToUpdate[i].Id + 
                                     ' Error: ' + err.getMessage());
                    }
                }
            }
        }
    }
    
    private static String extractEmailAddress(EmailMessage email) {
        String address = null;
        if (email.Incoming == true && String.isNotBlank(email.FromAddress)) {
            address = email.FromAddress.toLowerCase();
        } else if (email.Incoming == false && String.isNotBlank(email.ToAddress)) {
            address = email.ToAddress.toLowerCase();
        }
        
        return address;
    }
    
    private static Map<String, Lead> findLeadsByEmail(Set<String> emailAddresses) {
        List<Lead> allLeads = [
            SELECT Id, Email, Status, Email_Reply_Received__c, Email_Sent__c 
            FROM Lead 
            WHERE Email IN :emailAddresses
        ];
        
        Map<String, Lead> emailToLead = new Map<String, Lead>();
        
        for (Lead lead : allLeads) {
            String leadEmail = lead.Email.toLowerCase();
            
            if (lead.Status != 'Duplicate Entry') {
                emailToLead.put(leadEmail, lead);
            } else if (!emailToLead.containsKey(leadEmail)) {
                emailToLead.put(leadEmail, lead);
            }
        }
        
        return emailToLead;
    }
    
    private static List<Lead> updateLeadFields(Map<String, Lead> emailToLead, Map<String, List<EmailMessage>> emailToMessages) {
        List<Lead> leadsToUpdate = new List<Lead>();
        
        for (String emailAddress : emailToLead.keySet()) {
            Lead lead = emailToLead.get(emailAddress);
            
            if (emailToMessages.containsKey(emailAddress)) {
                Boolean wasUpdated = false;
                
                for (EmailMessage email : emailToMessages.get(emailAddress)) {
                    if (email.Incoming == true) {
                        lead.Email_Reply_Received__c = System.now();
                        wasUpdated = true;
                    } else {
                        lead.Email_Sent__c = System.now();
                        wasUpdated = true;
                    }
                }
                
                if (wasUpdated) {
                    leadsToUpdate.add(lead);
                }
            }
        }
        
        return leadsToUpdate;
    }
}