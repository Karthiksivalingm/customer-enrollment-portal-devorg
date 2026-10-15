public with sharing class ContactDeletionApprovalCtrl {

    @AuraEnabled(cacheable=true)
    public static List<ContactApprovalWrapper> getPendingApprovals() {
        List<ContactApprovalWrapper> results = new List<ContactApprovalWrapper>();

        List<ProcessInstanceWorkitem> workItems = [
            SELECT Id,
                   ProcessInstanceId,
                   ProcessInstance.TargetObjectId,
                   ProcessInstance.TargetObject.Name,
                   ProcessInstance.Status,
                   ActorId
            FROM ProcessInstanceWorkitem
            WHERE ActorId = :UserInfo.getUserId()
            AND ProcessInstance.Status = 'Pending'
            AND ProcessInstance.TargetObject.Type = 'Contact'
        ];

        if (workItems.isEmpty()) return results;

        Set<Id> contactIds     = new Set<Id>();
        Set<Id> processInstIds = new Set<Id>();
        for (ProcessInstanceWorkitem item : workItems) {
            contactIds.add(item.ProcessInstance.TargetObjectId);
            processInstIds.add(item.ProcessInstanceId);
        }

        // Contact fields — including both comment fields
        Map<Id, Contact> contactMap = new Map<Id, Contact>([
            SELECT Id, Name, Title, Email, Deletion_Reason__c,
                   Approver_Comments__c, Approver_Comments_2__c
            FROM Contact
            WHERE Id IN :contactIds
        ]);

        // Stage detection: count APPROVED steps per process instance
        // Stage 1 = 0 approved steps so far; Stage 2 = 1 approved step already done
        Map<Id, Integer> approvedStepCount = new Map<Id, Integer>();
        for (Id pid : processInstIds) {
            approvedStepCount.put(pid, 0);
        }
        List<ProcessInstanceStep> approvedSteps = [
            SELECT ProcessInstanceId
            FROM ProcessInstanceStep
            WHERE ProcessInstanceId IN :processInstIds
            AND StepStatus = 'Approved'
        ];
        for (ProcessInstanceStep s : approvedSteps) {
            approvedStepCount.put(
                s.ProcessInstanceId,
                approvedStepCount.get(s.ProcessInstanceId) + 1
            );
        }

        // Latest attachment per contact
        List<Attachment> attachments = [
            SELECT Id, ParentId, Body, ContentType
            FROM Attachment
            WHERE ParentId IN :contactIds
            ORDER BY CreatedDate DESC
        ];
        Map<Id, Attachment> latestAttachmentMap = new Map<Id, Attachment>();
        for (Attachment a : attachments) {
            if (!latestAttachmentMap.containsKey(a.ParentId)) {
                latestAttachmentMap.put(a.ParentId, a);
            }
        }

        for (ProcessInstanceWorkitem item : workItems) {
            Id contactId = item.ProcessInstance.TargetObjectId;
            Contact c    = contactMap.get(contactId);
            if (c == null) continue;

            // Stage 1 = no approved steps yet, Stage 2 = 1 approved step already
            Integer stage = approvedStepCount.get(item.ProcessInstanceId) >= 1 ? 2 : 1;

            ContactApprovalWrapper w  = new ContactApprovalWrapper();
            w.workItemId              = item.Id;
            w.contactId               = c.Id;
            w.contactName             = c.Name;
            w.jobTitle                = c.Title;
            w.email                   = c.Email;
            w.deletionReason          = c.Deletion_Reason__c;
            w.stageNumber             = stage;
            w.approverComments        = c.Approver_Comments__c; // stage 1 note shown to stage 2

            Attachment att = latestAttachmentMap.get(contactId);
            if (att != null) {
                String contentType = String.isBlank(att.ContentType) ? 'image/jpeg' : att.ContentType;
                w.photoUrl = 'data:' + contentType + ';base64,' + EncodingUtil.base64Encode(att.Body);
            }

            results.add(w);
        }
        return results;
    }

    @AuraEnabled
    public static void processApproval(Id workItemId, String action, String comments, Id contactId, Integer stageNumber) {
        if (action != 'Approve' && action != 'Reject') {
            throw new AuraHandledException('Invalid action. Use Approve or Reject.');
        }

        // 1. Save comment + update Deletion Status per stage
        if (contactId != null) {
            Contact c = new Contact(Id = contactId);

            if (stageNumber == 1) {
                if (String.isNotBlank(comments)) {
                    c.Approver_Comments__c = comments;
                }
                if (action == 'Approve') {
                    c.Deletion_Status__c   = 'Approved';
                    // Stage 1 approved → Stage 2 now pending approval
                    c.Deletion_Status_1__c = 'Pending Approval';
                } else {
                    c.Deletion_Status__c   = 'Rejected';
                    // Stage 1 rejected → Stage 2 not started
                    c.Deletion_Status_1__c = 'Pending Approval';
                }

            } else if (stageNumber == 2) {
                // Save the comment regardless of Approve/Reject
                if (String.isNotBlank(comments)) {
                    c.Approver_Comments_2__c = comments;
                }
                // Update Stage 2's own status field, not Stage 1's
                c.Deletion_Status_1__c = action == 'Approve' ? 'Approved' : 'Rejected';
            }

            update c;
        }

        // 2. Process the approval work item
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setWorkitemId(workItemId);
        req.setAction(action);
        req.setComments(comments != null ? comments : '');
        Approval.ProcessResult result = Approval.process(req);

        if (!result.isSuccess()) {
            throw new AuraHandledException(
                'Approval action failed: ' + result.getInstanceStatus()
            );
        }
    }

    public class ContactApprovalWrapper {
        @AuraEnabled public Id      workItemId;
        @AuraEnabled public Id      contactId;
        @AuraEnabled public String  contactName;
        @AuraEnabled public String  jobTitle;
        @AuraEnabled public String  email;
        @AuraEnabled public String  deletionReason;
        @AuraEnabled public String  photoUrl;
        @AuraEnabled public Integer stageNumber;       // 1 or 2
        @AuraEnabled public String  approverComments;  // stage 1 note — shown read-only to stage 2
    }
}