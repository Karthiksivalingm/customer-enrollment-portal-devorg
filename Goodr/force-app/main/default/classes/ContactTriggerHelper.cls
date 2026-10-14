public inherited sharing class ContactTriggerHelper
 {

    public static void assignContactToCompany(List<Contact> newContacts) {
        List<String> taxIds = new List<String>();
        for (Contact con : newContacts) {
            if (String.isNotBlank(con.Tax_Id__c) && con.AccountId == null) {
                taxIds.add(con.Tax_Id__c);
            }
        }
    
        if (taxIds.isEmpty()) {
            return;
        }
        Map<String, Account> taxIdToAccountMap = new Map<String, Account>();
        for (Account acc : [
            SELECT Id, Tax_Id__c 
            FROM Account 
            WHERE Tax_Id__c IN :taxIds AND RecordType.DeveloperName = 'Company'
        ]) {
            if (String.isNotBlank(acc.Tax_Id__c)) {
                taxIdToAccountMap.put(acc.Tax_Id__c, acc);
            }
        }
        
        List<Contact> contactsToUpdate = new List<Contact>();
        List<Contact> contactsToDelete = new List<Contact>();
        // ── CHANGE: Case creation disabled — replaced with Api_Log__c below ──
        // List<Case> rejectionCases = new List<Case>();
        // ── NEW: Api_Log__c list replacing rejectionCases above ──
        List<Api_Log__c> rejectionLogs = new List<Api_Log__c>();
    
        for (Contact con : newContacts) {
            if (String.isNotBlank(con.Tax_Id__c) && con.AccountId == null) {
                Account matchedAcc = taxIdToAccountMap.get(con.Tax_Id__c);
    
                if (matchedAcc != null) {
                    String emailToUse = String.isNotBlank(con.Email) ? con.Email : con.New_User_Email__c;

                    Contact conCopyToUpdate = new Contact(
                        Id = con.Id,
                        AccountId = matchedAcc.Id,
                        Email = emailToUse
                    );
                    contactsToUpdate.add(conCopyToUpdate);
                } else {
                    String emailToUse = String.isNotBlank(con.Email) ? con.Email : con.New_User_Email__c;
                    // ── CHANGE: Case creation disabled — replaced with Api_Log__c below ──
                    // Case rejectionCase = new Case(
                    //     Subject = 'Company Not Found',
                    //     Status = 'New',
                    //     Origin = 'Web',
                    //     Reason = 'Account Not Found',
                    //     Description = 'Submission rejected: no account with Tax ID ' + con.Tax_Id__c +
                    //     ' Name: ' + con.FirstName + ' ' + con.LastName +
                    //     (String.isNotBlank(emailToUse) ? ' | Email: ' + emailToUse : '') +
                    //     (String.isNotBlank(con.Phone) ? ' | Phone: ' + con.Phone : '')
                    // );
                    // rejectionCases.add(rejectionCase);

                    // ── NEW: Api_Log__c creation replacing the Case creation above ──
                    Api_Log__c rejectionLog = new Api_Log__c(
                        Context__c = 'Contact - Company Not Found',
                        Response_Message__c = 'Submission rejected: no account with Tax ID ' + con.Tax_Id__c +
                        ' Name: ' + con.FirstName + ' ' + con.LastName +
                        (String.isNotBlank(emailToUse) ? ' | Email: ' + emailToUse : '') +
                        (String.isNotBlank(con.Phone) ? ' | Phone: ' + con.Phone : ''),
                        Related_Record_Id__c = con.Id,
                        Log_Type__c = 'Match Failure'
                    );
                    rejectionLogs.add(rejectionLog);
                    contactsToDelete.add(new Contact(Id = con.Id));
                }
            }
        }
    
        // ── CHANGE: Case insert disabled — replaced with Api_Log__c insert below ──
        // if (!rejectionCases.isEmpty()) {
        //     insert rejectionCases;
        // }

        // ── NEW: Api_Log__c insert replacing the Case insert above ──
        if (!rejectionLogs.isEmpty()) {
            insert rejectionLogs;
        }
        if (!contactsToDelete.isEmpty()) {
            delete contactsToDelete;
        }
        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
    }
    
    public static List<Contact> validateAndCleanseNewContacts(List<Contact> newContacts) {
        Set<String> emailsToCheck = new Set<String>();
        for (Contact con : newContacts) {
            String emailToUse = String.isNotBlank(con.Email) ? con.Email : con.New_User_Email__c;
            if (String.isNotBlank(emailToUse)) {
                emailsToCheck.add(emailToUse.toLowerCase());
            }
        }
        Map<String, Contact> existingEmailMap = new Map<String, Contact>();
        if (!emailsToCheck.isEmpty()) {
            for (Contact existing : [
                SELECT Id, Email
                FROM Contact
                WHERE Email IN :emailsToCheck
                AND Id NOT IN :newContacts
            ]) {
                existingEmailMap.put(existing.Email.toLowerCase(), existing);
            }
        }
        // ── CHANGE: Case creation disabled — replaced with Api_Log__c below ──
        // List<Case> rejectionCases = new List<Case>();
        List<Contact> contactsToDelete = new List<Contact>();
        List<Contact> validContacts = new List<Contact>();
        // ── NEW: Api_Log__c list replacing rejectionCases above ──
        List<Api_Log__c> rejectionLogs = new List<Api_Log__c>();
    
        for (Contact con : newContacts) {
            String emailToUse = String.isNotBlank(con.Email) ? con.Email : con.New_User_Email__c;
            if (String.isNotBlank(emailToUse) && existingEmailMap.containsKey(emailToUse.toLowerCase())) {
                // ── CHANGE: Case creation disabled — replaced with Api_Log__c below ──
                // Case rejectionCase = new Case(
                //     Subject = 'Duplicate Contact Submission',
                //     Status = 'New',
                //     Origin = 'Web',
                //     Reason = 'Duplicate Contact',
                //     Description = 'Submission rejected: duplicate email ' + emailToUse +
                //                   'Name: ' + con.FirstName + ' ' + con.LastName +
                //                   (String.isNotBlank(con.Phone) ? ' | Phone: ' + con.Phone : ''),
                //     ContactId = existingEmailMap.get(emailToUse.toLowerCase()).Id
                // );
                // rejectionCases.add(rejectionCase);

                // ── NEW: Api_Log__c creation replacing the Case creation above ──
                Api_Log__c rejectionLog = new Api_Log__c(
                    Context__c = 'Duplicate Contact Submission',
                    Response_Message__c = 'Submission rejected: duplicate email ' + emailToUse +
                                  'Name: ' + con.FirstName + ' ' + con.LastName +
                                  (String.isNotBlank(con.Phone) ? ' | Phone: ' + con.Phone : '') +
                                  ' | Matched existing Contact Id: ' + existingEmailMap.get(emailToUse.toLowerCase()).Id,
                    Related_Record_Id__c = con.Id,
                    Log_Type__c = 'Duplicate Detection'
                );
                rejectionLogs.add(rejectionLog);
                contactsToDelete.add(new Contact(Id = con.Id));
            } else {
                validContacts.add(con);
            }
        }
    
        // ── CHANGE: Case insert disabled — replaced with Api_Log__c insert below ──
        // if (!rejectionCases.isEmpty()) {
        //     insert rejectionCases;
        // }

        // ── NEW: Api_Log__c insert replacing the Case insert above ──
        if (!rejectionLogs.isEmpty()) {
            insert rejectionLogs;
        }
    
        if (!contactsToDelete.isEmpty()) {
            delete contactsToDelete;
        }
    
        return validContacts;
    }

    public static void handleRejectedContacts(List<Contact> rejectedContacts) {
        // ── CHANGE: Case creation disabled — replaced with Api_Log__c below ──
        // List<Case> casesToInsert = new List<Case>();
        List<Contact> contactsCopyToDelete = new List<Contact>();
        // ── NEW: Api_Log__c list replacing casesToInsert above ──
        List<Api_Log__c> logsToInsert = new List<Api_Log__c>();

        for (Contact con : rejectedContacts) {
            // ── CHANGE: Case creation disabled — replaced with Api_Log__c below ──
            // Case c = new Case(
            //     Subject = 'Rejected Contact: ' + con.LastName,
            //     Status = 'New',
            //     Type = 'Manual Rejection',
            //     Origin = 'System',
            //     Description = 'Contact was manually rejected. ' +
            //         'Name: ' + con.FirstName + ' ' + con.LastName +
            //         (String.isNotBlank(con.Email) ? ' | Email: ' + con.Email : '') +
            //         (String.isNotBlank(con.Phone) ? ' | Phone: ' + con.Phone : '')
            // );
            // casesToInsert.add(c);

            // ── NEW: Api_Log__c creation replacing the Case creation above ──
            Api_Log__c log = new Api_Log__c(
                Context__c = 'Contact Manually Rejected',
                Response_Message__c = 'Contact was manually rejected. ' +
                    'Name: ' + con.FirstName + ' ' + con.LastName +
                    (String.isNotBlank(con.Email) ? ' | Email: ' + con.Email : '') +
                    (String.isNotBlank(con.Phone) ? ' | Phone: ' + con.Phone : ''),
                Related_Record_Id__c = con.Id,
                Log_Type__c = 'Manual Rejection'
            );
            logsToInsert.add(log);

            contactsCopyToDelete.add(new Contact(Id = con.Id));
        }

        // ── CHANGE: Case insert disabled — replaced with Api_Log__c insert below ──
        // if (!casesToInsert.isEmpty()) {
        //     insert casesToInsert;
        // }

        // ── NEW: Api_Log__c insert replacing the Case insert above ──
        if (!logsToInsert.isEmpty()) {
            insert logsToInsert;
        }

        delete contactsCopyToDelete;
    }

    public static void createStoreLocationNote(List<Contact> newContacts) {
        List<ContentNote> notesToInsert = new List<ContentNote>();
        List<Id> contactIds = new List<Id>();
        
        for (Contact con : newContacts) {
            if (String.isNotBlank(con.Store_Locations__c)) {
                String formattedBody = con.Store_Locations__c
                    .replaceAll('\r\n', '\n')
                    .replace('\n', '<br/>');
                
                notesToInsert.add(new ContentNote(
                    Title = 'Requested Store Locations',
                    Content = Blob.valueOf(formattedBody)
                ));
                contactIds.add(con.Id);
            }
        }
        
        if (!notesToInsert.isEmpty()) {
            insert notesToInsert;
            
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for (Integer i = 0; i < notesToInsert.size(); i++) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = notesToInsert[i].Id,
                    LinkedEntityId = contactIds[i],
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                ));
            }
            
            insert links;
        }
    }

    public static void removeSymbolsFromTaxId(List<Contact> newContacts) {
        for (Contact c : newContacts) {
            if (String.isNotBlank(c.Tax_Id__c)) {
                c.Tax_Id__c = c.Tax_Id__c.replaceAll('[^0-9]', '');
            }
        }
    }
}