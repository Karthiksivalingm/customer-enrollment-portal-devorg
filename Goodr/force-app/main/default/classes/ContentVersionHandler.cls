public with sharing class ContentVersionHandler {

    public static void handleAfterUpdate(
        List<ContentVersion> newVersions,
        Map<Id, ContentVersion> oldMap
    ) {
        List<Id> addToPO = new List<Id>();
        //  Removed: removeFromPO list — we never delete the Account CDL

        for (ContentVersion cv : newVersions) {
            ContentVersion oldCv = oldMap.get(cv.Id);
            Boolean wasChecked   = oldCv.Document_Type__c == 'Purchase Order';
            Boolean isChecked    = cv.Document_Type__c    == 'Purchase Order';

            // Only create CDL when newly checked
            if (!wasChecked && isChecked) addToPO.add(cv.ContentDocumentId);

            //  When unchecked — do NOTHING to CDL
            // The Document_Type__c field being null/empty is enough
            // to hide it from the PO list (filter handles this in Apex controller)
        }

        if (!addToPO.isEmpty()) linkDocsToAccount(addToPO);
        // Removed: unlinkDocsFromAccount call
    }

    // ── Checked: create CDL on Account ───────────────────────────
    private static void linkDocsToAccount(List<Id> docIds) {
        Map<Id, Id> docToAccount = resolveAccountFromDocs(docIds);
        if (docToAccount.isEmpty()) return;

        Set<String> existingKeys = new Set<String>();
        for (ContentDocumentLink cdl : [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :docToAccount.keySet()
              AND LinkedEntityId IN :docToAccount.values()
            WITH USER_MODE
        ]) {
            existingKeys.add(cdl.ContentDocumentId + '_' + cdl.LinkedEntityId);
        }

        List<ContentDocumentLink> toInsert = new List<ContentDocumentLink>();
        for (Id docId : docToAccount.keySet()) {
            Id accountId = docToAccount.get(docId);
            if (!existingKeys.contains(docId + '_' + accountId)) {
                ContentDocumentLink link = new ContentDocumentLink();
                link.ContentDocumentId  = docId;
                link.LinkedEntityId     = accountId;
                link.ShareType          = 'V';
                link.Visibility         = 'AllUsers';
                toInsert.add(link);
            }
        }
        if (!toInsert.isEmpty()) insert toInsert;
    }

    //  Removed: unlinkDocsFromAccount method entirely

    // ── Resolve docId → accountId via EmailMessage ────────────────
    private static Map<Id, Id> resolveAccountFromDocs(List<Id> docIds) {
        Map<Id, Id> docToAccount = new Map<Id, Id>();

        Map<Id, Id> docToEmailId = new Map<Id, Id>();
        for (ContentDocumentLink cdl : [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :docIds
            WITH USER_MODE
        ]) {
            if (String.valueOf(cdl.LinkedEntityId).startsWith('02s')) {
                docToEmailId.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
            }
        }
        if (docToEmailId.isEmpty()) return docToAccount;

        Map<Id, Id> emailToAccount = new Map<Id, Id>();
        Set<Id>     taskIds        = new Set<Id>();

        for (EmailMessage em : [
            SELECT Id, RelatedToId, ActivityId
            FROM EmailMessage
            WHERE Id IN :docToEmailId.values()
            WITH USER_MODE
        ]) {
            if (em.RelatedToId != null &&
                String.valueOf(em.RelatedToId).startsWith('001')) {
                emailToAccount.put(em.Id, em.RelatedToId);
            } else if (em.ActivityId != null) {
                emailToAccount.put(em.Id, em.ActivityId);
                taskIds.add(em.ActivityId);
            }
        }

        if (!taskIds.isEmpty()) {
            for (Task t : [
                SELECT Id, WhatId FROM Task
                WHERE Id IN :taskIds AND WhatId != null
                WITH USER_MODE
            ]) {
                if (String.valueOf(t.WhatId).startsWith('001')) {
                    for (Id emailId : emailToAccount.keySet()) {
                        if (emailToAccount.get(emailId) == t.Id) {
                            emailToAccount.put(emailId, t.WhatId);
                        }
                    }
                }
            }
        }

        for (Id docId : docToEmailId.keySet()) {
            Id emailId   = docToEmailId.get(docId);
            Id accountId = emailToAccount.get(emailId);
            if (accountId != null &&
                String.valueOf(accountId).startsWith('001')) {
                docToAccount.put(docId, accountId);
            }
        }
        return docToAccount;
    }
}