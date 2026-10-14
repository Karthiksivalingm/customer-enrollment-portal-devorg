trigger CaseEmailResponseTrigger on EmailMessage (after insert) {

    Set<Id> caseIds = new Set<Id>();

    for (EmailMessage em : Trigger.new) {
        if (em.ParentId != null &&
            String.valueOf(em.ParentId).startsWith('500')) {

            // Only process outbound emails
            if (em.Incoming == false) {
                caseIds.add(em.ParentId);
            }
        }
    }

    if (caseIds.isEmpty()) return;

    Map<Id, Case> caseMap = new Map<Id, Case>(
        [SELECT Id,
                First_Response_Date__c,
                Next_Reply_Due_Date__c
         FROM Case
         WHERE Id IN :caseIds]
    );

    List<Case> casesToUpdate = new List<Case>();

    for (Id caseId : caseIds) {

        // Get ALL outbound emails in order
        List<EmailMessage> outboundEmails = [
            SELECT Id, MessageDate
            FROM EmailMessage
            WHERE ParentId = :caseId
            AND Incoming = false
            ORDER BY MessageDate ASC
        ];

        // Need at least 2 outbound emails
        // because first one is auto-response
        if (outboundEmails.size() < 2) continue;

        Case c = caseMap.get(caseId);
        Boolean changed = false;

        // Second outbound email = First agent reply
        Datetime firstReply = outboundEmails[1].MessageDate;

        if (c.First_Response_Date__c != firstReply) {
            c.First_Response_Date__c = firstReply;
            changed = true;
        }

        // Third outbound email = Next agent reply
        if (outboundEmails.size() >= 3) {
            Datetime secondReply = outboundEmails[2].MessageDate;

            if (c.Next_Reply_Due_Date__c != secondReply) {
                c.Next_Reply_Due_Date__c = secondReply;
                changed = true;
            }
        }

        if (changed) {
            casesToUpdate.add(c);
        }
    }

    if (!casesToUpdate.isEmpty()) {
        update casesToUpdate;
    }
}