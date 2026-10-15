public with sharing class GuestListApprovalController {
/*
    @AuraEnabled(cacheable=false)
    public static List<Guest_List__c> getGuestLists(Id sessionId) {

        // Step 1: Get all Guest List IDs for this session
        Set<Id> sessionGuestListIds = new Set<Id>();
        for (Guest_List__c gl : [
            SELECT Id FROM Guest_List__c WHERE Session__c = :sessionId
        ]) {
            sessionGuestListIds.add(gl.Id);
        }

        // Step 2: Find which ones are currently pending in approval process
        Set<Id> alreadyInProcess = new Set<Id>();
        for (ProcessInstance pi : [
            SELECT TargetObjectId
            FROM   ProcessInstance
            WHERE  TargetObjectId IN :sessionGuestListIds
            AND    Status = 'Pending'
        ]) {
            alreadyInProcess.add(pi.TargetObjectId);
        }

        // Step 3: Return only not-approved, not-pending records
        List<Guest_List__c> result = new List<Guest_List__c>();
        for (Guest_List__c gl : [
            SELECT Id,
                   Name,
                   Contact__r.Name,
                   Invitation__r.Name,
                   Title__c,
                   Reason__c
            FROM   Guest_List__c
            WHERE  Session__c  = :sessionId
            AND    Approval__c != 'Approved'
            AND    Approval__c != 'Pending'
        ]) {
            if (!alreadyInProcess.contains(gl.Id)) {
                result.add(gl);
            }
        }
        return result;
    }

    @AuraEnabled
    public static void submitForApproval(List<Id> guestListIds) {
        try {
            // Safety check - skip any already pending
            Set<Id> alreadyInProcess = new Set<Id>();
            for (ProcessInstance pi : [
                SELECT TargetObjectId
                FROM   ProcessInstance
                WHERE  TargetObjectId IN :guestListIds
                AND    Status = 'Pending'
            ]) {
                alreadyInProcess.add(pi.TargetObjectId);
            }

            List<Id> toSubmit = new List<Id>();
            for (Id gId : guestListIds) {
                if (!alreadyInProcess.contains(gId)) {
                    toSubmit.add(gId);
                }
            }

            if (toSubmit.isEmpty()) {
                throw new AuraHandledException('All selected records are already pending approval.');
            }

            // Submit to approval process
            List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
            for (Id gId : toSubmit) {
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setObjectId(gId);
                requests.add(req);
            }

            List<Approval.ProcessResult> results = Approval.process(requests);

            // Collect successfully submitted IDs
            List<Id> successIds = new List<Id>();
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    successIds.add(toSubmit[i]);
                } else {
                    String errMsg = '';
                    for (Database.Error err : results[i].getErrors()) {
                        errMsg += err.getMessage() + ' ';
                    }
                    throw new AuraHandledException(errMsg.trim());
                }
            }

            // Update Approval__c = 'Pending' on successfully submitted records
            if (!successIds.isEmpty()) {
                List<Guest_List__c> toUpdate = new List<Guest_List__c>();
                for (Id gId : successIds) {
                    toUpdate.add(new Guest_List__c(
                        Id         = gId,
                        Approval__c = 'Pending'
                    ));
                }
                update toUpdate;
            }

        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }*/
}