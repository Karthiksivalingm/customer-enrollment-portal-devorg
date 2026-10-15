public with sharing class GuestListInvitationController {

    private static final Set<String> TERMINAL_STATUSES = new Set<String>{
        'Approved', 'Rejected', 'Removed', 'Cancelled'
    };

    public class GuestRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String recordName;
        @AuraEnabled public String contactName;
        @AuraEnabled public String invitationName;
        @AuraEnabled public String titleC;
        @AuraEnabled public String reasonC;
        @AuraEnabled public String approvalC;
        @AuraEnabled public Id mainGuestId;
        @AuraEnabled public Boolean isActionable;
        @AuraEnabled public String statusLabel;
    }

    @AuraEnabled(cacheable=false)
    public static List<GuestRow> getGuestLists(Id invitationId) {

        Set<Id> invitationGuestListIds = new Set<Id>();
        for (Guest_List__c gl : [
            SELECT Id FROM Guest_List__c WHERE Invitation__c = :invitationId
        ]) {
            invitationGuestListIds.add(gl.Id);
        }

        Set<Id> alreadyInProcess = new Set<Id>();
        for (ProcessInstance pi : [
            SELECT TargetObjectId, Status
            FROM   ProcessInstance
            WHERE  TargetObjectId IN :invitationGuestListIds
        ]) {
            if (!TERMINAL_STATUSES.contains(pi.Status)) {
                alreadyInProcess.add(pi.TargetObjectId);
            }
        }

        Boolean accompanyingGuestApprovalRequired = false;
        for (Invitation__c inv : [
            SELECT Accompanying_Guest_Approval_Required__c
            FROM   Invitation__c
            WHERE  Id = :invitationId
            LIMIT 1
        ]) {
            accompanyingGuestApprovalRequired = inv.Accompanying_Guest_Approval_Required__c;
        }

        String query = 'SELECT Id, Name, Main_Guest__c, Approval__c, Contact__r.Name, Invitation__r.Name, Title__c, Reason__c ' +
                        'FROM Guest_List__c ' +
                        'WHERE Invitation__c = :invitationId ' +
                        'AND Approval__c != \'Approved\' ' +
                        'AND Approval__c != \'Pending\'';

        if (!accompanyingGuestApprovalRequired) {
            query += ' AND Main_Guest__c = null';
        }

        List<Guest_List__c> actionableRaw = new List<Guest_List__c>();
        for (Guest_List__c gl : Database.query(query)) {
            if (!alreadyInProcess.contains(gl.Id)) {
                actionableRaw.add(gl);
            }
        }

        Map<Id, GuestRow> rowsById       = new Map<Id, GuestRow>();
        Set<Id>           actionableMainIds = new Set<Id>();

        for (Guest_List__c gl : actionableRaw) {
            GuestRow row = toRow(gl, true, alreadyInProcess);
            rowsById.put(gl.Id, row);
            if (gl.Main_Guest__c == null) {
                actionableMainIds.add(gl.Id);
            }
        }

        // Backfill missing MAIN guests for children that came back actionable
        // (so a lone actionable accompanying guest still shows nested under its main).
        Set<Id> referencedMainIds = new Set<Id>();
        for (Guest_List__c gl : actionableRaw) {
            if (gl.Main_Guest__c != null && !rowsById.containsKey(gl.Main_Guest__c)) {
                referencedMainIds.add(gl.Main_Guest__c);
            }
        }

        if (!referencedMainIds.isEmpty()) {
            for (Guest_List__c mainGl : [
                SELECT Id, Name, Main_Guest__c, Approval__c, Contact__r.Name, Invitation__r.Name, Title__c, Reason__c
                FROM   Guest_List__c
                WHERE  Id IN :referencedMainIds
            ]) {
                if (!rowsById.containsKey(mainGl.Id)) {
                    rowsById.put(mainGl.Id, toRow(mainGl, false, alreadyInProcess));
                }
            }
        }

        // Backfill missing CHILD (accompanying) guests for every main guest that is
        // now in the result set — regardless of the child's Approval__c status and
        // regardless of accompanyingGuestApprovalRequired. This is what makes
        // already-approved/pending or non-required accompanying guests still show
        // up (read-only) nested under their main guest instead of disappearing.
        Set<Id> allMainIdsInResult = new Set<Id>();
        for (GuestRow row : rowsById.values()) {
            if (row.mainGuestId == null) {
                allMainIdsInResult.add(row.id);
            }
        }

        if (!allMainIdsInResult.isEmpty()) {
            for (Guest_List__c childGl : [
                SELECT Id, Name, Main_Guest__c, Approval__c, Contact__r.Name, Invitation__r.Name, Title__c, Reason__c
                FROM   Guest_List__c
                WHERE  Main_Guest__c IN :allMainIdsInResult
            ]) {
                if (!rowsById.containsKey(childGl.Id)) {
                    rowsById.put(childGl.Id, toRow(childGl, false, alreadyInProcess));
                }
            }
        }

        return rowsById.values();
    }

    private static GuestRow toRow(Guest_List__c gl, Boolean isActionable, Set<Id> alreadyInProcess) {
        GuestRow row        = new GuestRow();
        row.id               = gl.Id;
        row.recordName       = gl.Name;
        row.contactName      = gl.Contact__r != null ? gl.Contact__r.Name : null;
        row.invitationName   = gl.Invitation__r != null ? gl.Invitation__r.Name : null;
        row.titleC           = gl.Title__c;
        row.reasonC          = gl.Reason__c;
        row.approvalC        = gl.Approval__c;
        row.mainGuestId      = gl.Main_Guest__c;
        row.isActionable     = isActionable;

        if (gl.Approval__c == 'Approved') {
            row.statusLabel = 'Approved';
        } else if (alreadyInProcess.contains(gl.Id)) {
            row.statusLabel = 'In Approval Process';
        } else if (String.isNotBlank(gl.Approval__c)) {
            row.statusLabel = gl.Approval__c;
        } else {
            row.statusLabel = null;
        }

        return row;
    }

    @AuraEnabled
    public static void submitForApproval(List<Id> guestListIds) {
        try {
            Set<Id> alreadyInProcess = new Set<Id>();
            for (ProcessInstance pi : [
                SELECT TargetObjectId, Status
                FROM   ProcessInstance
                WHERE  TargetObjectId IN :guestListIds
            ]) {
                if (!TERMINAL_STATUSES.contains(pi.Status)) {
                    alreadyInProcess.add(pi.TargetObjectId);
                }
            }

            List<Id> toSubmit = new List<Id>();
            for (Id gId : guestListIds) {
                if (!alreadyInProcess.contains(gId)) {
                    toSubmit.add(gId);
                }
            }

            if (toSubmit.isEmpty()) {
                throw new AuraHandledException('All selected records are already in an approval process.');
            }

            List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
            for (Id gId : toSubmit) {
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setObjectId(gId);
                requests.add(req);
            }

            List<Approval.ProcessResult> results = Approval.process(requests);

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

            if (!successIds.isEmpty()) {
                List<Guest_List__c> toUpdate = new List<Guest_List__c>();
                for (Id gId : successIds) {
                    toUpdate.add(new Guest_List__c(
                        Id          = gId,
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
    }
}