public inherited sharing class LeadTriggerHandler {
    
    private static final Set<String> LEAD_FORM_SOURCES = new Set<String>{
        'Googled It',
        'PGA Show 2025',
        'Other Trade Show',
        'Surf Expo 2025',
        'Sporting Event',
        'Customer Referral',
        'Retailer Referral',
        'TRE 2025',
        'Back River Referral',
        'Other'
    };
    
    private static final String CONTACT_FORM_SOURCE = 'Contact Form';
    private static final String STATUS_DUPLICATED = 'Duplicate Entry';
    private static final String STATUS_ACCOUNT_EXIST = 'Account Already Exist';
    private static final String STATUS_NEW = 'New';
    private static final String STATUS_WORKING = 'Working';
    private static final String STATUS_REJECTION = 'Manual Rejection';
    private static final String COMPANY_RECORD_TYPE = 'Company';

    private static List<LeadMergeService.MergeRequest> leadsToMerge = new List<LeadMergeService.MergeRequest>();

    // ── ORIGINAL single-param method — now a no-op ───────────────────────────
    // Kept so any existing references compile without error.
    // Validation logic has moved to the 2-param overload below.
    public static void checkIfEarlyStagesFilled(List<Lead> newLeads) {
        // No-op — validation moved to before update (Status → Qualified)
    }

    // FIX: New 2-param method — fires only when Status changes to Qualified
    // Same 3 field checks as before — consolidated into one clear error message
    public static void checkIfEarlyStagesFilled(List<Lead> newLeads, Map<Id, Lead> oldMap) {
        for (Lead lead : newLeads) {

            Lead oldLead = oldMap.get(lead.Id);

            // Only validate when Status is being changed TO Qualified
            if (lead.Status != 'Qualified' || oldLead.Status == 'Qualified') {
                continue;
            }

            List<String> missingFields = new List<String>();

            if (String.isBlank(lead.Terms_of_Service_Agreement__c)) {
                missingFields.add('"Terms of Service Agreement" must be filled in');
            }

            if (lead.Has_Physical_Store__c == false) {
                missingFields.add('"Has Physical Store" must be set to Yes');
            }

            if (lead.Resale_Certificate_Status__c == 'No, I don\'t.') {
                missingFields.add('"Resale Certificate Status" cannot be "No, I don\'t."');
            }

            if (!missingFields.isEmpty()) {
                lead.addError(
                    'This Lead cannot be set to Qualified. '
                    + 'Please fix the following before qualifying: '
                    + String.join(missingFields, ' | ')
                );
            }
        }
    }

    // ── ALL METHODS BELOW ARE COMPLETELY UNCHANGED ────────────────────────────

    public static void setLeadSources(List<Lead> newLeads) {
        if (newLeads == null || newLeads.isEmpty()) {
            return;
        }
    
        for (Lead lead : newLeads) {
            if (String.isNotBlank(lead.LeadSource)) {
                if (LEAD_FORM_SOURCES.contains(lead.LeadSource)) {
                    lead.Source__c = 'Lead Form';
                } else {
                    lead.Source__c = 'Contact Form';
                }
            }
        }
    }

    public static void setStateToStateCode(List<Lead> newLeads) {
        for (Lead lead : newLeads) {
            if (String.isNotBlank(lead.Billing_Address_State__c)) {
                lead.Billing_Address__StateCode__s = StateToStateCodeHelper.getStateCode(lead.Billing_Address_State__c);
            }
        }
    }

    public static void removeSymbolsFromTaxId(List<Lead> newLeads) {
        for (Lead l : newLeads) {
            if (String.isNotBlank(l.Tax_Id__c)) {
                l.Tax_Id__c = l.Tax_Id__c.replaceAll('[^0-9]', '');
            }
        }
    }

    public static void handleBeforeUpdate(List<Lead> updatedLeads) {
        removeSymbolsFromTaxId(updatedLeads);
    }

    public static void handleAfterInsert(List<Lead> newLeads) {
        if (newLeads == null || newLeads.isEmpty()) {
            return;
    	}
        
        if (!Schema.sObjectType.Lead.fields.Tax_Id__c.isAccessible() ||
            !Schema.sObjectType.Lead.fields.LeadSource.isAccessible() ||
            !Schema.sObjectType.Lead.fields.Status.isUpdateable()) {
            return;
        }
        
        List<Lead> leadFormLeads = new List<Lead>();
        List<Lead> contactFormLeads = new List<Lead>();
        Set<String> allTaxIds = new Set<String>();
        Set<String> allEmails = new Set<String>();
        
        for (Lead lead : newLeads) {
            if (LEAD_FORM_SOURCES.contains(lead.LeadSource)) {
                leadFormLeads.add(lead);
                if (String.isNotBlank(lead.Tax_Id__c)) {
                    allTaxIds.add(lead.Tax_Id__c);
                }
                if (String.isNotBlank(lead.Email)) {
                    allEmails.add(lead.Email);
                }
            } else {
                contactFormLeads.add(lead);
                if (String.isNotBlank(lead.Tax_Id__c)) {
                    allTaxIds.add(lead.Tax_Id__c);
                }
                if (String.isNotBlank(lead.Email)) {
                    allEmails.add(lead.Email);
                }
            }
        }
        
        if (leadFormLeads.isEmpty() && contactFormLeads.isEmpty()) {
            return;
        }
        
        Map<String, List<Lead>> existingLeadsByTaxId = new Map<String, List<Lead>>();
        Map<String, List<Lead>> existingLeadsByEmail = new Map<String, List<Lead>>();
        Map<String, Account> companyAccountsByTaxId = new Map<String, Account>();
        
        if (!leadFormLeads.isEmpty()) {
            Set<Id> newLeadIds = new Set<Id>();
            for (Lead lead : newLeads) {
                newLeadIds.add(lead.Id);
            }
            existingLeadsByTaxId = getExistingLeadsByTaxId(allTaxIds, newLeadIds);
            existingLeadsByEmail = getExistingLeadsByEmail(allEmails, newLeadIds);
            companyAccountsByTaxId = getCompanyAccountsByTaxId(allTaxIds);
        }
        
        if (!contactFormLeads.isEmpty() && companyAccountsByTaxId.isEmpty()) {
            companyAccountsByTaxId = getCompanyAccountsByTaxId(allTaxIds);
        }
        
        List<Lead> leadsToUpdate = new List<Lead>();
        
        leadsToUpdate.addAll(processLeadFormLeads(leadFormLeads, existingLeadsByTaxId, existingLeadsByEmail, companyAccountsByTaxId));
                
        if (!leadsToUpdate.isEmpty()) {
            try {
                update leadsToUpdate;
            } catch (Exception e) {
                System.debug('Error updating lead statuses: ' + e.getMessage());
            }
        }

        if (!leadsToMerge.isEmpty()) {
            LeadMergeService.mergeLeadsWithNote(leadsToMerge);
        }
    }
    
    public static void handleAfterUpdate(List<Lead> updatedLeads, Map<Id, Lead> oldMap) {
        if (updatedLeads == null || updatedLeads.isEmpty()) return;
    
        List<Lead> leadsWithChangedTaxId = new List<Lead>();
    
        for (Lead lead : updatedLeads) {
            Lead oldLead = oldMap.get(lead.Id);
            if (lead.Tax_Id__c != oldLead.Tax_Id__c && String.isNotBlank(lead.Tax_Id__c)) {
                leadsWithChangedTaxId.add(lead);
            }
        }

        handleLeadsConvertedToAccountExist(updatedLeads, oldMap);
        createCasesForManuallyRejectedLeads(updatedLeads, oldMap);
    }
    
    private static Map<String, List<Lead>> getExistingLeadsByTaxId(Set<String> taxIds, Set<Id> newLeadIds) {
        Map<String, List<Lead>> leadsByTaxId = new Map<String, List<Lead>>();
        
        try {
            List<Lead> existingLeads = [
                SELECT Id, Tax_Id__c, Status, Is_Franchise__c, Company, FirstName, LastName, Email, Phone, Resale_Number__c, 
                LeadSource, Website, Facebook__c, Instagram__c, Twitter__c, Has_Physical_Store__c, Is_Tax_Exempt__c, Title,
                Store_Square_Footage__c, Affinity_Brands__c, Goodr_Visual_Merchandising__c, Retailer_Communication_Opt_In__c,
                Terms_of_Service_Agreement__c, Final_Comments__c
                FROM Lead 
                WHERE Tax_Id__c IN :taxIds 
                AND Status IN (:STATUS_NEW, :STATUS_WORKING, :STATUS_REJECTION)
                AND Id NOT IN :newLeadIds
                LIMIT 10000
            ];
            
            for (Lead lead : existingLeads) {
                if (!leadsByTaxId.containsKey(lead.Tax_Id__c)) {
                    leadsByTaxId.put(lead.Tax_Id__c, new List<Lead>());
                }
                leadsByTaxId.get(lead.Tax_Id__c).add(lead);
            }
        } catch (Exception e) {
            System.debug('Error querying existing leads: ' + e.getMessage());
        }
        
        return leadsByTaxId;
    }
    
    private static Map<String, List<Lead>> getExistingLeadsByEmail(Set<String> emails, Set<Id> newLeadIds) {
        Map<String, List<Lead>> leadsByEmail = new Map<String, List<Lead>>();
        
        if (emails.isEmpty()) {
            return leadsByEmail;
        }
        
        try {
            List<Lead> existingLeads = [
                SELECT Id, Tax_Id__c, Status, Is_Franchise__c, Company, FirstName, LastName, Email, Phone, Resale_Number__c
                FROM Lead 
                WHERE Email IN :emails 
                AND Status IN (:STATUS_NEW, :STATUS_WORKING, :STATUS_REJECTION)
                AND Id NOT IN :newLeadIds
                LIMIT 10000
            ];
            
            for (Lead lead : existingLeads) {
                if (String.isNotBlank(lead.Email)) {
                    if (!leadsByEmail.containsKey(lead.Email)) {
                        leadsByEmail.put(lead.Email, new List<Lead>());
                    }
                    leadsByEmail.get(lead.Email).add(lead);
                }
            }
        } catch (Exception e) {
            System.debug('Error querying existing leads by email: ' + e.getMessage());
        }
        
        return leadsByEmail;
    }
    
    private static Map<String, Account> getCompanyAccountsByTaxId(Set<String> taxIds) {
        Map<String, Account> accountsByTaxId = new Map<String, Account>();
        
        try {
            Id companyRecordTypeId = getCompanyRecordTypeId();
            
            if (companyRecordTypeId != null) {
                List<Account> companyAccounts = [
                    SELECT Id, Tax_Id__c, RecordTypeId 
                    FROM Account 
                    WHERE Tax_Id__c IN :taxIds 
                    AND RecordTypeId = :companyRecordTypeId
                ];
                
                for (Account acc : companyAccounts) {
                    accountsByTaxId.put(acc.Tax_Id__c, acc);
                }
            }
        } catch (Exception e) {
            System.debug('Error querying company accounts: ' + e.getMessage());
        }
        
        return accountsByTaxId;
    }
    
    private static Id getCompanyRecordTypeId() {
        try {
            RecordType companyRecordType = [
                SELECT Id 
                FROM RecordType 
                WHERE SObjectType = 'Account' 
                AND DeveloperName = :COMPANY_RECORD_TYPE 
                LIMIT 1
            ];
            return companyRecordType.Id;
        } catch (Exception e) {
            System.debug('Error getting Company RecordType: ' + e.getMessage());
            return null;
        }
    }
    
    private static List<Lead> processLeadFormLeads(List<Lead> leadFormLeads, 
                                                 Map<String, List<Lead>> existingLeadsByTaxId,
                                                 Map<String, List<Lead>> existingLeadsByEmail,
                                                 Map<String, Account> companyAccountsByTaxId) {
        List<Lead> leadsToUpdate = new List<Lead>();
        
        for (Lead lead : leadFormLeads) {
            String newStatus = null;

            if (companyAccountsByTaxId.containsKey(lead.Tax_Id__c)) {
                newStatus = STATUS_ACCOUNT_EXIST;
            } else if (existingLeadsByTaxId.containsKey(lead.Tax_Id__c)) {
                List<Lead> existing = existingLeadsByTaxId.get(lead.Tax_Id__c);
                Lead rejectedLead = null;

                for (Lead oldLead : existing) {
                    if (oldLead.Status == STATUS_REJECTION) {
                        rejectedLead = oldLead;
                        break;
                    }
                }

                if (rejectedLead != null) {
                    leadsToMerge.add(new LeadMergeService.MergeRequest(lead, rejectedLead));
                    continue;
                } else {
                    newStatus = STATUS_DUPLICATED;
                }
            } else if (String.isNotBlank(lead.Email) && existingLeadsByEmail.containsKey(lead.Email)) {
                newStatus = STATUS_DUPLICATED;
            }

            if (String.isNotBlank(newStatus) && !newStatus.equals(lead.Status)) {
                leadsToUpdate.add(new Lead(
                    Id = lead.Id,
                    Status = newStatus
                ));
            }
        }
        
        return leadsToUpdate;
    }

    private static void handleLeadsConvertedToAccountExist(List<Lead> updatedLeads, Map<Id, Lead> oldMap) {
        // ── CHANGE: Case creation disabled — replaced with Api_Log__c below ──
        // List<Case> casesToInsert = new List<Case>();
        // for (Lead lead : updatedLeads) {
        //     Lead oldLead = oldMap.get(lead.Id);
        //     if (lead.Status == STATUS_ACCOUNT_EXIST && oldLead.Status != STATUS_ACCOUNT_EXIST) {
        //         casesToInsert.add(new Case(
        //             Subject = 'New Lead rejected due to existing Account',
        //             Description = 'Lead with ID ' + lead.Id + 
        //                         ' and Tax ID ' + lead.Tax_Id__c + 
        //                         ' was rejected and marked as Account Already Exist.' +
        //                         ' Name: ' + lead.FirstName + ' ' + lead.LastName +
        //                         (String.isNotBlank(lead.Company) ? ' | Company: ' + lead.Company : '') +
        //                         (String.isNotBlank(lead.Email) ? ' | Email: ' + lead.Email : '') +
        //                         (String.isNotBlank(lead.Phone) ? ' | Phone: ' + lead.Phone : ''),
        //             Origin = 'Lead',
        //             Status = 'New',
        //             Priority = 'Medium'
        //         ));
        //     }
        // }
        //
        // if (!casesToInsert.isEmpty()) {
        //     try {
        //         insert casesToInsert;
        //     } catch (Exception e) {
        //         System.debug('Error inserting cases: ' + e.getMessage());
        //     }
        // }

        // ── NEW: Api_Log__c creation replacing the Case creation above ──
        List<Api_Log__c> logsToInsert = new List<Api_Log__c>();
        for (Lead lead : updatedLeads) {
            Lead oldLead = oldMap.get(lead.Id);
            if (lead.Status == STATUS_ACCOUNT_EXIST && oldLead.Status != STATUS_ACCOUNT_EXIST) {
                logsToInsert.add(new Api_Log__c(
                    Context__c = 'Lead Rejected - Account Already Exists',
                    Response_Message__c = 'Lead with ID ' + lead.Id + 
                                ' and Tax ID ' + lead.Tax_Id__c + 
                                ' was rejected and marked as Account Already Exist.' +
                                ' Name: ' + lead.FirstName + ' ' + lead.LastName +
                                (String.isNotBlank(lead.Company) ? ' | Company: ' + lead.Company : '') +
                                (String.isNotBlank(lead.Email) ? ' | Email: ' + lead.Email : '') +
                                (String.isNotBlank(lead.Phone) ? ' | Phone: ' + lead.Phone : ''),
                    Related_Record_Id__c = lead.Id,
                    Log_Type__c = 'Lead Duplicate'
                ));
            }
        }

        if (!logsToInsert.isEmpty()) {
            try {
                insert logsToInsert;
            } catch (Exception e) {
                System.debug('Error inserting Api_Log__c records: ' + e.getMessage());
            }
        }
    }

    private static void createCasesForManuallyRejectedLeads(List<Lead> updatedLeads, Map<Id, Lead> oldMap) {
        // ── CHANGE: Case creation disabled — replaced with Api_Log__c below ──
        // List<Case> casesToInsert = new List<Case>();
        //
        // for (Lead lead : updatedLeads) {
        //     Lead oldLead = oldMap.get(lead.Id);
        //
        //     if (lead.Status == STATUS_REJECTION && oldLead.Status != STATUS_REJECTION) {
        //         Case c = new Case(
        //             Subject = 'Rejected Lead: ' + lead.FirstName + ' ' + lead.LastName,
        //             Status = 'New',
        //             Type = 'Manual Rejection',
        //             Origin = 'System',
        //             Description = 'Lead was manually rejected. ' +
        //                 'Name: ' + lead.FirstName + ' ' + lead.LastName +
        //                 (String.isNotBlank(lead.Company) ? ' | Company: ' + lead.Company : '') +
        //                 (String.isNotBlank(lead.Email) ? ' | Email: ' + lead.Email : '') +
        //                 (String.isNotBlank(lead.Phone) ? ' | Phone: ' + lead.Phone : '') +
        //                 (String.isNotBlank(lead.Tax_Id__c) ? ' | Tax ID: ' + lead.Tax_Id__c : '') +
        //                 ' | Lead Id: ' + lead.Id
        //         );
        //         casesToInsert.add(c);
        //     }
        // }
        //
        // if (!casesToInsert.isEmpty()) {
        //     try {
        //         insert casesToInsert;
        //     } catch (Exception e) {
        //         System.debug('Error inserting follow-up Cases: ' + e.getMessage());
        //     }
        // }

        // ── NEW: Api_Log__c creation replacing the Case creation above ──
        List<Api_Log__c> logsToInsert = new List<Api_Log__c>();

        for (Lead lead : updatedLeads) {
            Lead oldLead = oldMap.get(lead.Id);

            if (lead.Status == STATUS_REJECTION && oldLead.Status != STATUS_REJECTION) {
                Api_Log__c log = new Api_Log__c(
                    Context__c = 'Lead Manually Rejected',
                    Response_Message__c = 'Lead was manually rejected. ' +
                        'Name: ' + lead.FirstName + ' ' + lead.LastName +
                        (String.isNotBlank(lead.Company) ? ' | Company: ' + lead.Company : '') +
                        (String.isNotBlank(lead.Email) ? ' | Email: ' + lead.Email : '') +
                        (String.isNotBlank(lead.Phone) ? ' | Phone: ' + lead.Phone : '') +
                        (String.isNotBlank(lead.Tax_Id__c) ? ' | Tax ID: ' + lead.Tax_Id__c : '') +
                        ' | Lead Id: ' + lead.Id,
                    Related_Record_Id__c = lead.Id,
                    Log_Type__c = 'Manual Rejection'
                );
                logsToInsert.add(log);
            }
        }

        if (!logsToInsert.isEmpty()) {
            try {
                insert logsToInsert;
            } catch (Exception e) {
                System.debug('Error inserting follow-up Api_Log__c records: ' + e.getMessage());
            }
        }
    }
}