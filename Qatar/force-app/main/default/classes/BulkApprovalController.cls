public with sharing class BulkApprovalController {

    @AuraEnabled
    public static List<ApprovalRequestWrapper> getPendingApprovals() {
        Id currentUserId = UserInfo.getUserId();

        Set<Id> userQueueIds = new Set<Id>();
        for (GroupMember gm : [
            SELECT GroupId FROM GroupMember WHERE UserOrGroupId = :currentUserId
        ]) {
            userQueueIds.add(gm.GroupId);
        }

        List<ProcessInstanceWorkitem> workItems = [
            SELECT
                Id,
                ProcessInstance.Id,
                ProcessInstance.TargetObjectId,
                ProcessInstance.TargetObject.Name,
                ProcessInstance.TargetObject.Type,
                ProcessInstance.SubmittedById,
                ProcessInstance.SubmittedBy.Name,
                ProcessInstance.Status,
                ProcessInstance.CreatedDate,
                ProcessInstance.LastModifiedDate,
                Actor.Name,
                ActorId,
                OriginalActor.Name
            FROM ProcessInstanceWorkitem
            WHERE (ActorId = :currentUserId OR ActorId IN :userQueueIds)
            AND ProcessInstance.Status = 'Pending'
            ORDER BY ProcessInstance.CreatedDate DESC
            LIMIT 1000
        ];

        Set<Id> targetObjectIds    = new Set<Id>();
        Set<Id> processInstanceIds = new Set<Id>();

        for (ProcessInstanceWorkitem wi : workItems) {
            targetObjectIds.add(wi.ProcessInstance.TargetObjectId);
            processInstanceIds.add(wi.ProcessInstance.Id);
        }

        // ── Determine approval stage per ProcessInstance ──────────────────────
        Map<Id, Integer> stageMap = new Map<Id, Integer>();
        for (ProcessInstanceStep step : [
            SELECT ProcessInstanceId
            FROM ProcessInstanceStep
            WHERE ProcessInstanceId IN :processInstanceIds
            AND StepStatus = 'Approved'
        ]) {
            Integer cnt = stageMap.containsKey(step.ProcessInstanceId)
                ? stageMap.get(step.ProcessInstanceId) + 1 : 1;
            stageMap.put(step.ProcessInstanceId, cnt);
        }

        // ── Guest_List__c full detail fetch ───────────────────────────────────
        Map<Id, String>  contactNameMap    = new Map<Id, String>();
        Map<Id, String>  eventNameMap      = new Map<Id, String>();
        Map<Id, String>  sessionNameMap    = new Map<Id, String>();
        Map<Id, String>  recordPhotoMap    = new Map<Id, String>();
        Map<Id, Id>      guestToContactMap = new Map<Id, Id>();
        Set<Id>          contactIds        = new Set<Id>();
        Map<Id, GuestDetailWrapper> detailMap = new Map<Id, GuestDetailWrapper>();

        try {
            for (Guest_List__c gl : [
                SELECT Id,
                       Contact__c,
                       Contact__r.Name,
                       Contact__r.Title,
                       Contact__r.Contact_External_Id__c,
                       Title__c,
                       Invitation__c,
                       Invitation__r.Name,
                       Session_Names__c,
                       Reason_for_Inviting__c,
                       Bio__c,
                       Source__c,
                       Protocol_Tier__c,
                       Guest_Category__c,
                       Guest_Sector__c,
                       Company__c,
                       Background_Check__c,
                       Guest_Tier_Recommendations__c,
                       RSVP__c,
                       Inbound_Date_Time__c,
                       Outbound_Date_Time__c,
                       Hotel_Name__c,
                       X1_of_Invited_Guests__c,
                       Relationship_to__c,
                       Escorted_By__c,
                       Escorted_By__r.Name,
                       Main_Guest_Names__c,
                       Notes__c
                FROM Guest_List__c
                WHERE Id IN :targetObjectIds
            ]) {
                if (gl.Contact__c != null) {
                    contactNameMap.put(gl.Id, gl.Contact__r.Name);
                    guestToContactMap.put(gl.Id, gl.Contact__c);
                    contactIds.add(gl.Contact__c);
                }
                if (gl.Invitation__c != null) eventNameMap.put(gl.Id, gl.Invitation__r.Name);
                if (gl.Session_Names__c != null) sessionNameMap.put(gl.Id, gl.Session_Names__c);

                GuestDetailWrapper d = new GuestDetailWrapper();
                d.guestListId      = gl.Id;
                d.contactId        = gl.Contact__r != null ? gl.Contact__r.Contact_External_Id__c : null;
                d.titleField       = gl.Title__c;
                d.fullName         = gl.Contact__r != null ? gl.Contact__r.Name : null;
                d.contactTitle     = gl.Contact__r != null ? gl.Contact__r.Title     : null;
                d.bio              = gl.Bio__c;
                d.reason           = gl.Reason_for_Inviting__c;
                d.source           = gl.Source__c;
                d.protocolTier     = gl.Protocol_Tier__c;
                d.guestCategory    = gl.Guest_Category__c;
                d.guestSector      = gl.Guest_Sector__c;
                d.company          = gl.Company__c;
                d.position         = gl.Contact__r != null ? gl.Contact__r.Title : null;
                d.backgroundCheck  = gl.Background_Check__c;
                d.guestTierRecommendation = gl.Guest_Tier_Recommendations__c;
                d.rsvpStatus       = gl.RSVP__c;
                d.inboundDateTime  = gl.Inbound_Date_Time__c != null
                    ? gl.Inbound_Date_Time__c.addHours(2).format('dd/MM/yyyy hh:mm a') : null;
                d.outboundDateTime = gl.Outbound_Date_Time__c != null
                    ? gl.Outbound_Date_Time__c.addHours(2).format('dd/MM/yyyy hh:mm a') : null;
                d.hotelName        = gl.Hotel_Name__c;
                d.plusOne          = gl.X1_of_Invited_Guests__c != null ? gl.X1_of_Invited_Guests__c : null;
                d.relationshipTo   = gl.Relationship_to__c;
                d.escortedBy       = gl.Escorted_By__r != null ? gl.Escorted_By__r.Name : null;
                d.mainGuestName    = gl.Main_Guest_Names__c;
                if (String.isNotBlank(gl.Main_Guest_Names__c)) {
                    Matcher mgMatcher = Pattern.compile('href="([^"]+)"[^>]*>([^<]+)<')
                        .matcher(gl.Main_Guest_Names__c);
                    if (mgMatcher.find()) {
                        d.mainGuestName = mgMatcher.group(2);
                        d.mainGuestId   = mgMatcher.group(1).substringAfterLast('/');
                    }
                }
                d.notes            = gl.Notes__c;
                detailMap.put(gl.Id, d);
            }
        } catch (Exception e) { throw new AuraHandledException('Guest_List__c query failed: ' + e.getMessage()); }

        // ── HE Requests related list ──────────────────────────────────────────
        Map<Id, List<String>> heRequestMap = new Map<Id, List<String>>();
        try {
            for (HE_Request__c her : [
                SELECT Id, Name, Guest_List__c
                FROM HE_Request__c
                WHERE Guest_List__c IN :targetObjectIds
                ORDER BY Name ASC
            ]) {
                if (!heRequestMap.containsKey(her.Guest_List__c)) {
                    heRequestMap.put(her.Guest_List__c, new List<String>());
                }
                heRequestMap.get(her.Guest_List__c).add(her.Name);
            }
        } catch (Exception e) { }

        // ── Contact photo (Attachment first, then ContentDocumentLink) ────────
        if (!contactIds.isEmpty()) {
            Set<Id> seenContacts = new Set<Id>();
            for (Attachment att : [
                SELECT ParentId, Id, ContentType
                FROM Attachment
                WHERE ParentId IN :contactIds
                AND ContentType IN ('image/jpeg','image/jpg','image/png','image/gif')
                ORDER BY CreatedDate DESC
            ]) {
                Id cId = att.ParentId;
                if (!seenContacts.contains(cId)) {
                    seenContacts.add(cId);
                    String photoUrl = '/servlet/servlet.FileDownload?file=' + att.Id;
                    for (Id glId : guestToContactMap.keySet()) {
                        if (guestToContactMap.get(glId) == cId) recordPhotoMap.put(glId, photoUrl);
                    }
                }
            }
            Set<Id> remainingContacts = new Set<Id>();
            for (Id cId : contactIds) {
                if (!seenContacts.contains(cId)) remainingContacts.add(cId);
            }
            if (!remainingContacts.isEmpty()) {
                for (ContentDocumentLink cdl : [
                    SELECT LinkedEntityId,
                           ContentDocument.LatestPublishedVersionId,
                           ContentDocument.FileType
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId IN :remainingContacts
                    AND ContentDocument.FileType IN ('JPG','JPEG','PNG','GIF')
                    ORDER BY ContentDocument.CreatedDate DESC
                ]) {
                    Id cId = cdl.LinkedEntityId;
                    if (!seenContacts.contains(cId)) {
                        seenContacts.add(cId);
                        String photoUrl = '/sfc/servlet.shepherd/version/download/'
                            + cdl.ContentDocument.LatestPublishedVersionId;
                        for (Id glId : guestToContactMap.keySet()) {
                            if (guestToContactMap.get(glId) == cId) recordPhotoMap.put(glId, photoUrl);
                        }
                    }
                }
            }
        }

        // ── Last comment per instance ─────────────────────────────────────────
        Map<Id, String> commentMap = new Map<Id, String>();
        for (ProcessInstanceStep step : [
            SELECT ProcessInstanceId, Comments, CreatedDate
            FROM ProcessInstanceStep
            WHERE ProcessInstanceId IN :processInstanceIds
            ORDER BY CreatedDate DESC
        ]) {
            if (!commentMap.containsKey(step.ProcessInstanceId)) {
                commentMap.put(step.ProcessInstanceId, step.Comments);
            }
        }

        List<ApprovalRequestWrapper> wrappers = new List<ApprovalRequestWrapper>();

        for (ProcessInstanceWorkitem wi : workItems) {
            ApprovalRequestWrapper w = new ApprovalRequestWrapper();
            w.workItemId          = wi.Id;
            w.processInstanceId   = wi.ProcessInstance.Id;
            w.targetObjectId      = wi.ProcessInstance.TargetObjectId;
            w.targetObjectName    = wi.ProcessInstance.TargetObject.Name;
            w.targetObjectType    = wi.ProcessInstance.TargetObject.Type;
            w.submittedByName     = wi.ProcessInstance.SubmittedBy.Name;
            w.submittedByPhotoUrl = recordPhotoMap.get(wi.ProcessInstance.TargetObjectId);
            w.contactName         = contactNameMap.get(wi.ProcessInstance.TargetObjectId);
            w.eventName           = eventNameMap.get(wi.ProcessInstance.TargetObjectId);
            w.sessionName         = sessionNameMap.get(wi.ProcessInstance.TargetObjectId);
            w.status              = wi.ProcessInstance.Status;
            w.createdDate         = wi.ProcessInstance.CreatedDate;
            w.lastModifiedDate    = wi.ProcessInstance.LastModifiedDate;
            w.assignedTo          = wi.Actor.Name;
            w.lastComment         = commentMap.get(wi.ProcessInstance.Id);

            Integer approvedSteps = stageMap.containsKey(wi.ProcessInstance.Id)
                ? stageMap.get(wi.ProcessInstance.Id) : 0;
            w.approvalStage = approvedSteps == 0 ? 1 : 2;

            GuestDetailWrapper d = detailMap.get(wi.ProcessInstance.TargetObjectId);
            if (d != null) {
                w.detail = d;
                w.detail.photoUrl   = recordPhotoMap.get(wi.ProcessInstance.TargetObjectId);
                w.detail.heRequests = heRequestMap.containsKey(wi.ProcessInstance.TargetObjectId)
                    ? heRequestMap.get(wi.ProcessInstance.TargetObjectId) : new List<String>();
            }
            wrappers.add(w);
        }

        return wrappers;
    }

    @AuraEnabled
    public static BulkActionResult processBulkApprovals(
        List<String> workItemIds,
        String action,
        String comments,
        Map<String, String> guestTierUpdates
    ) {
        BulkActionResult result = new BulkActionResult();
        result.successCount = 0;
        result.failureCount = 0;
        result.errors       = new List<String>();

        if (workItemIds == null || workItemIds.isEmpty()) {
            result.errors.add('No work items provided.');
            return result;
        }
        if (action != 'Approve' && action != 'Reject') {
            result.errors.add('Invalid action: ' + action);
            return result;
        }

        if (String.isNotBlank(comments)) {
            Set<Id> workItemIdSet = new Set<Id>();
            for (String wId : workItemIds) workItemIdSet.add((Id) wId);

            List<ProcessInstanceWorkitem> wis = [
                SELECT ProcessInstance.TargetObjectId
                FROM ProcessInstanceWorkitem
                WHERE Id IN :workItemIdSet
            ];

            Set<Id> glIds = new Set<Id>();
            for (ProcessInstanceWorkitem wi : wis) glIds.add(wi.ProcessInstance.TargetObjectId);

            List<Guest_List__c> glsToUpdate = new List<Guest_List__c>();
            for (Id glId : glIds) glsToUpdate.add(new Guest_List__c(Id = glId, Notes__c = comments));

            if (!glsToUpdate.isEmpty()) {
                try { update glsToUpdate; } catch (Exception e) {
                    result.errors.add('Notes save failed: ' + e.getMessage());
                }
            }
        }

        // ── Push Guest Tier Recommendation -> Guest_Tiers__c (Approve only) ────
        // A work item is only approved once its Guest Tier Recommendation value
        // has been successfully pushed to Guest_Tiers__c. If the push fails for
        // a given work item, that work item is excluded from the approval batch
        // below and counted as a failure.
        Set<String> guestTierPushFailedWorkItemIds = new Set<String>();

        if (action == 'Approve' && guestTierUpdates != null && !guestTierUpdates.isEmpty()) {
            Map<Id, String> workItemToTargetMap = new Map<Id, String>();
            Set<Id> guestTierWorkItemIdSet = new Set<Id>();
            for (String wId : guestTierUpdates.keySet()) {
                try {
                    guestTierWorkItemIdSet.add((Id) wId);
                } catch (Exception e) {
                    guestTierPushFailedWorkItemIds.add(wId);
                }
            }

            Map<Id, Id> workItemIdToTargetObjectId = new Map<Id, Id>();
            for (ProcessInstanceWorkitem wi : [
                SELECT Id, ProcessInstance.TargetObjectId
                FROM ProcessInstanceWorkitem
                WHERE Id IN :guestTierWorkItemIdSet
            ]) {
                workItemIdToTargetObjectId.put(wi.Id, wi.ProcessInstance.TargetObjectId);
            }

            List<Guest_List__c> glsToUpdate    = new List<Guest_List__c>();
            Map<Id, String>     glIdToWorkItem = new Map<Id, String>();

            for (String wId : guestTierUpdates.keySet()) {
                if (guestTierPushFailedWorkItemIds.contains(wId)) continue;

                Id targetId = workItemIdToTargetObjectId.get((Id) wId);
                if (targetId == null) {
                    guestTierPushFailedWorkItemIds.add(wId);
                    continue;
                }
                glsToUpdate.add(new Guest_List__c(
                    Id             = targetId,
                    Guest_Tiers__c = guestTierUpdates.get(wId)
                ));
                glIdToWorkItem.put(targetId, wId);
            }

            if (!glsToUpdate.isEmpty()) {
                List<Database.SaveResult> saveResults = Database.update(glsToUpdate, false);
                for (Integer i = 0; i < saveResults.size(); i++) {
                    if (!saveResults[i].isSuccess()) {
                        String failedWId = glIdToWorkItem.get(glsToUpdate[i].Id);
                        guestTierPushFailedWorkItemIds.add(failedWId);
                        for (Database.Error err : saveResults[i].getErrors()) {
                            result.errors.add('Guest Tier Recommendation push failed: ' + err.getMessage());
                        }
                    }
                }
            }
        }

        // Exclude work items whose Guest Tier Recommendation push failed —
        // they must not be approved.
        List<String> workItemIdsToProcess = new List<String>();
        for (String wId : workItemIds) {
            if (guestTierPushFailedWorkItemIds.contains(wId)) {
                result.failureCount++;
            } else {
                workItemIdsToProcess.add(wId);
            }
        }

        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
        for (String wId : workItemIdsToProcess) {
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setWorkitemId(wId);
            req.setAction(action);
            if (String.isNotBlank(comments)) req.setComments(comments);
            requests.add(req);
        }

        Integer batchSize = 10;
        for (Integer i = 0; i < requests.size(); i += batchSize) {
            Integer endIdx = Math.min(i + batchSize, requests.size());
            List<Approval.ProcessWorkitemRequest> batch = new List<Approval.ProcessWorkitemRequest>();
            for (Integer j = i; j < endIdx; j++) batch.add(requests[j]);
            try {
                List<Approval.ProcessResult> results = Approval.process(batch, false);
                for (Approval.ProcessResult pr : results) {
                    if (pr.isSuccess()) {
                        result.successCount++;
                    } else {
                        result.failureCount++;
                        for (Database.Error err : pr.getErrors()) result.errors.add(err.getMessage());
                    }
                }
            } catch (Exception e) {
                result.failureCount += batch.size();
                result.errors.add(e.getMessage());
            }
        }
        return result;
    }

    // ── Wrappers ──────────────────────────────────────────────────────────────
    public class ApprovalRequestWrapper {
        @AuraEnabled public String   workItemId;
        @AuraEnabled public String   processInstanceId;
        @AuraEnabled public String   targetObjectId;
        @AuraEnabled public String   targetObjectName;
        @AuraEnabled public String   targetObjectType;
        @AuraEnabled public String   submittedByName;
        @AuraEnabled public String   submittedByPhotoUrl;
        @AuraEnabled public String   contactName;
        @AuraEnabled public String   eventName;
        @AuraEnabled public String   sessionName;
        @AuraEnabled public String   status;
        @AuraEnabled public DateTime createdDate;
        @AuraEnabled public DateTime lastModifiedDate;
        @AuraEnabled public String   assignedTo;
        @AuraEnabled public String   lastComment;
        @AuraEnabled public Integer  approvalStage;
        @AuraEnabled public GuestDetailWrapper detail;
    }

    public class GuestDetailWrapper {
        @AuraEnabled public String   guestListId;
        @AuraEnabled public String   contactId;        // Contact__r.Contact_External_Id__c
        @AuraEnabled public String   photoUrl;
        @AuraEnabled public String   titleField;       // Title__c
        @AuraEnabled public String   fullName;         // Contact__r.Name
        @AuraEnabled public String   contactTitle;     // Contact__r.Title
        @AuraEnabled public String   bio;              // Bio__c
        @AuraEnabled public String   reason;           // Reason_for_Inviting__c
        @AuraEnabled public String   source;           // Source__c
        @AuraEnabled public String   protocolTier;     // Protocol_Tier__c
        @AuraEnabled public String   guestCategory;    // Guest_Category__c
        @AuraEnabled public String   guestSector;      // Guest_Sector__c
        @AuraEnabled public String   company;          // Company__c
        @AuraEnabled public String   position;         // Contact__r.Title (Job Title)
        @AuraEnabled public String   backgroundCheck;  // Background_Check__c
        @AuraEnabled public String   guestTierRecommendation; // Guest_Tier_Recommendations__c (editable, Stage 2 only; pushed to Guest_Tiers__c on Approve)
        @AuraEnabled public String   rsvpStatus;       // RSVP__c
        @AuraEnabled public String   inboundDateTime;  // Inbound_Date_Time__c
        @AuraEnabled public String   outboundDateTime; // Outbound_Date_Time__c
        @AuraEnabled public String   hotelName;        // Hotel_Name__c
        @AuraEnabled public String   plusOne;          // X1_of_Invited_Guests__c
        @AuraEnabled public String   relationshipTo;   // Relationship_to__c
        @AuraEnabled public String   escortedBy;       // Escorted_By__c
        @AuraEnabled public String   mainGuestName;    // Main_Guest_Names__c — the primary guest this accompanying guest is linked to (parsed from the field's link HTML)
        @AuraEnabled public String   mainGuestId;      // Record Id parsed out of Main_Guest_Names__c's link, for navigation
        @AuraEnabled public String   notes;            // Notes__c
        @AuraEnabled public List<String> heRequests;
    }

    public class BulkActionResult {
        @AuraEnabled public Integer      successCount;
        @AuraEnabled public Integer      failureCount;
        @AuraEnabled public List<String> errors;
    }
}