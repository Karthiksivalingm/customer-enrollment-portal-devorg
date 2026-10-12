public with sharing class ContentDocumentLinkHandler {

    /**
     * EAC DATA MODEL (what your screenshot shows):
     *
     *   Gmail attachment
     *       → EAC syncs → EmailMessage (SObject, prefix 02s)
     *       → ContentDocumentLink: LinkedEntityId = EmailMessage.Id
     *
     * EmailMessage has a field called `ActivityId` which points to a Task.
     * That Task has `WhatId` pointing to the Account.
     *
     * BUT — with EAC specifically, EmailMessage may also have a direct
     * `RelatedToId` field that points to the Account. We check BOTH paths.
     */
    public static void handleAfterInsert(List<ContentDocumentLink> newLinks) {

        // Step 1: isolate only links where LinkedEntityId is an EmailMessage
        // EmailMessage object key prefix = '02s'
        List<ContentDocumentLink> emailLinks = new List<ContentDocumentLink>();
        Set<Id> emailMessageIds = new Set<Id>();

        for (ContentDocumentLink cdl : newLinks) {
            if (cdl.LinkedEntityId != null &&
                String.valueOf(cdl.LinkedEntityId).startsWith('02s')) {
                emailLinks.add(cdl);
                emailMessageIds.add(cdl.LinkedEntityId);
            }
        }

        if (emailLinks.isEmpty()) return;

        // Step 2: query EmailMessage for both RelatedToId (direct) and ActivityId (via Task)
        Map<Id, Id> emailToAccountId = new Map<Id, Id>();

        for (EmailMessage em : [
            SELECT Id, RelatedToId, ActivityId
            FROM EmailMessage
            WHERE Id IN :emailMessageIds
            WITH USER_MODE
        ]) {
            // Path A: RelatedToId directly points to Account (most common with EAC)
            if (em.RelatedToId != null &&
                String.valueOf(em.RelatedToId).startsWith('001')) {
                emailToAccountId.put(em.Id, em.RelatedToId);
            }
            // Path B: via ActivityId → Task.WhatId (fallback)
            else if (em.ActivityId != null) {
                emailToAccountId.put(em.Id, em.ActivityId); // store TaskId temporarily
            }
        }

        // Step 3: resolve any Task-based entries to Account WhatId
        Set<Id> taskIds = new Set<Id>();
        for (Id emailId : emailToAccountId.keySet()) {
            Id val = emailToAccountId.get(emailId);
            if (val != null && String.valueOf(val).startsWith('00T')) {
                taskIds.add(val); // it's a Task Id
            }
        }

        if (!taskIds.isEmpty()) {
            for (Task t : [
                SELECT Id, WhatId
                FROM Task
                WHERE Id IN :taskIds
                  AND WhatId != null
                WITH USER_MODE
            ]) {
                // Only keep if WhatId is an Account
                if (String.valueOf(t.WhatId).startsWith('001')) {
                    // Replace TaskId with AccountId in the map
                    for (Id emailId : emailToAccountId.keySet()) {
                        if (emailToAccountId.get(emailId) == t.Id) {
                            emailToAccountId.put(emailId, t.WhatId);
                        }
                    }
                }
            }
        }

        // Remove any entries where we still have a Task Id (couldn't resolve)
        Map<Id, Id> resolvedEmailToAccount = new Map<Id, Id>();
        for (Id emailId : emailToAccountId.keySet()) {
            Id val = emailToAccountId.get(emailId);
            if (val != null && String.valueOf(val).startsWith('001')) {
                resolvedEmailToAccount.put(emailId, val);
            }
        }

        if (resolvedEmailToAccount.isEmpty()) return;

        // Step 4: build map ContentDocumentId → AccountId
        Map<Id, Id> docIdToAccountId = new Map<Id, Id>();
        for (ContentDocumentLink cdl : emailLinks) {
            Id accountId = resolvedEmailToAccount.get(cdl.LinkedEntityId);
            if (accountId != null) {
                docIdToAccountId.put(cdl.ContentDocumentId, accountId);
            }
        }

        if (docIdToAccountId.isEmpty()) return;

        // Step 5: skip documents already linked to this Account (avoid duplicates)
        Set<String> existingKeys = new Set<String>();
        for (ContentDocumentLink existing : [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :docIdToAccountId.keySet()
              AND LinkedEntityId IN :docIdToAccountId.values()
            WITH USER_MODE
        ]) {
            existingKeys.add(existing.ContentDocumentId + '_' + existing.LinkedEntityId);
        }

        // Step 6: create new ContentDocumentLinks on the Account
        List<ContentDocumentLink> toInsert = new List<ContentDocumentLink>();
        List<Id> docsToTag = new List<Id>();

        for (Id docId : docIdToAccountId.keySet()) {
            Id accountId = docIdToAccountId.get(docId);
            String key = docId + '_' + accountId;
            if (!existingKeys.contains(key)) {
                ContentDocumentLink link = new ContentDocumentLink();
                link.ContentDocumentId = docId;
                link.LinkedEntityId    = accountId;
                link.ShareType         = 'V';
                link.Visibility        = 'AllUsers';
                toInsert.add(link);
                docsToTag.add(docId);
            }
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }

        // Step 7: tag the ContentVersion as Purchase Order
        if (!docsToTag.isEmpty()) {
            List<ContentVersion> versions = [
                SELECT Id, Document_Type__c
                FROM ContentVersion
                WHERE ContentDocumentId IN :docsToTag
                  AND IsLatest = true
                WITH USER_MODE
            ];
            for (ContentVersion cv : versions) {
                cv.Document_Type__c = 'Purchase Order';
            }
            if (!versions.isEmpty()) {
                update versions;
            }
        }
    }
}