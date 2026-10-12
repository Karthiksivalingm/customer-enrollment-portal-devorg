public class WinbackStatusSync {
    
    public static final String CAMPAIGN_NAME = 
        '2026-T2-Specialty-Sellgoodr-ALL-winback';
    public static final String CADENCE_NAME  = 
        '2026-Winback-SUMMERFLIGHT15';
    
    // ═══════════════════════════════════════
    // PART 1 — Add to Campaign when email 
    // step is executed in cadence
    // Trigger: AutomaticallyCompleted step
    // ═══════════════════════════════════════
    public static void syncEnrollments() {
        System.debug('=== START syncEnrollments ===');
        
        Campaign camp = getCampaign();
        if (camp == null) return;
        
        // Get contacts where cadence email
        // step was AutomaticallyCompleted
        List<ActionCadenceStepTracker> trackers = 
            new List<ActionCadenceStepTracker>();
        try {
            trackers = [
                SELECT Id,
                       TargetId,
                       State,
                       StepType,
                       StepTitle,
                       CompletionReason,
                       IsActionTaken,
                       ActionCadenceName
                FROM ActionCadenceStepTracker
                WHERE ActionCadenceName = :CADENCE_NAME
                AND StepType = 'SendAnEmail'
                AND State = 'Completed'
                AND CompletionReason = 'AutomaticallyCompleted'
            ];
        } catch (Exception e) {
            System.debug('Query error: ' + e.getMessage());
            return;
        }
        
        System.debug('Email steps completed: ' 
                    + trackers.size());
        if (trackers.isEmpty()) return;
        
        // Collect IDs
        Set<Id> contactIds = new Set<Id>();
        Set<Id> leadIds    = new Set<Id>();
        
        for (ActionCadenceStepTracker t : trackers) {
            if (t.TargetId == null) continue;
            String px = String.valueOf(
                t.TargetId).substring(0,3);
            if (px == '003') contactIds.add(t.TargetId);
            if (px == '00Q') leadIds.add(t.TargetId);
        }
        
        // Check existing members
        Set<Id> existingC = new Set<Id>();
        Set<Id> existingL = new Set<Id>();
        
        for (CampaignMember cm : [
            SELECT ContactId, LeadId
            FROM CampaignMember
            WHERE CampaignId = :camp.Id
            AND (ContactId IN :contactIds
                 OR LeadId IN :leadIds)
        ]) {
            if (cm.ContactId != null) 
                existingC.add(cm.ContactId);
            if (cm.LeadId != null) 
                existingL.add(cm.LeadId);
        }
        
        // Build insert list
        List<CampaignMember> toInsert = 
            new List<CampaignMember>();
        
        for (Id cId : contactIds) {
            if (!existingC.contains(cId)) {
                toInsert.add(new CampaignMember(
                    CampaignId = camp.Id,
                    ContactId  = cId,
                    Status     = 'Sent'
                ));
                System.debug('New Contact: ' + cId);
            }
        }
        for (Id lId : leadIds) {
            if (!existingL.contains(lId)) {
                toInsert.add(new CampaignMember(
                    CampaignId = camp.Id,
                    LeadId     = lId,
                    Status     = 'Sent'
                ));
                System.debug('New Lead: ' + lId);
            }
        }
        
        if (!toInsert.isEmpty()) {
            try {
                insert toInsert;
                System.debug('Inserted: ' + toInsert.size());
            } catch (DmlException e) {
                System.debug('DML error: ' + e.getMessage());
            }
        }
        System.debug('=== END syncEnrollments ===');
    }
    
    // ═══════════════════════════════════════
    // PART 2 — Sync Cadence completion states
    // Maps cadence tracker states to
    // Campaign Member statuses
    // ═══════════════════════════════════════
    public static void syncCadenceStates() {
        System.debug('=== START syncCadenceStates ===');
        
        Campaign camp = getCampaign();
        if (camp == null) return;
        
        // Get all trackers for our cadence
        List<ActionCadenceTracker> cadenceTrackers = 
            new List<ActionCadenceTracker>();
        try {
            cadenceTrackers = [
                SELECT Id,
                       TargetId,
                       State,
                       ActionCadence.Name
                FROM ActionCadenceTracker
                WHERE ActionCadence.Name = :CADENCE_NAME
            ];
        } catch (Exception e) {
            System.debug('Query error: ' + e.getMessage());
            return;
        }
        
        System.debug('Cadence trackers: ' 
                    + cadenceTrackers.size());
        if (cadenceTrackers.isEmpty()) return;
        
        // Map State to Campaign Member Status
        // Running  = still in cadence = Sent
        // Complete = finished cadence = Sent (no reply)
        // Removed  = opted out        = Opted Out
        Map<Id, String> targetStatusMap = 
            new Map<Id, String>();
        
        for (ActionCadenceTracker ct : cadenceTrackers) {
            if (ct.TargetId == null) continue;
            
            String newStatus = null;
            System.debug('State: ' + ct.State 
                        + ' Target: ' + ct.TargetId);
            
            if (ct.State == 'Running' || 
                ct.State == 'Paused') {
                newStatus = 'Sent';
            } else if (ct.State == 'Complete') {
                newStatus = 'Sent';
            } else if (ct.State == 'Removed') {
                newStatus = 'Opted Out';
            }
            
            if (newStatus != null) {
                targetStatusMap.put(ct.TargetId, newStatus);
            }
        }
        
        if (targetStatusMap.isEmpty()) return;
        
        // Get Campaign Members
        Set<Id> allTargetIds = targetStatusMap.keySet();
        Set<Id> contactIds   = new Set<Id>();
        Set<Id> leadIds      = new Set<Id>();
        
        for (Id tid : allTargetIds) {
            String px = String.valueOf(tid).substring(0,3);
            if (px == '003') contactIds.add(tid);
            if (px == '00Q') leadIds.add(tid);
        }
        
        List<CampaignMember> toUpdate = 
            new List<CampaignMember>();
        
        for (CampaignMember cm : [
            SELECT Id, ContactId, LeadId, Status
            FROM CampaignMember
            WHERE CampaignId = :camp.Id
            AND (ContactId IN :contactIds
                 OR LeadId IN :leadIds)
        ]) {
            Id targetId = cm.ContactId != null 
                          ? cm.ContactId : cm.LeadId;
            String newStatus = targetStatusMap.get(targetId);
            
            if (newStatus != null && 
                getStatusPriority(newStatus) > 
                getStatusPriority(cm.Status)) {
                System.debug(
                    'Update ' + targetId +
                    ' [' + cm.Status + '] → ' +
                    '[' + newStatus + ']'
                );
                cm.Status = newStatus;
                toUpdate.add(cm);
            }
        }
        
        if (!toUpdate.isEmpty()) {
            try {
                update toUpdate;
                System.debug('Updated: ' + toUpdate.size());
            } catch (DmlException e) {
                System.debug('DML error: ' + e.getMessage());
            }
        }
        System.debug('=== END syncCadenceStates ===');
    }
    
    // ═══════════════════════════════════════
    // PART 3 — Handle Bounced emails
    // Checks for bounced EmailMessages
    // and marks Campaign Member as Bounced
    // ═══════════════════════════════════════
    public static void syncBouncedEmails() {
        System.debug('=== START syncBouncedEmails ===');
        
        Campaign camp = getCampaign();
        if (camp == null) return;
        
        // Query ActionCadenceStepTracker
        // for error/bounce states
        List<ActionCadenceStepTracker> bounced = 
            new List<ActionCadenceStepTracker>();
        try {
            bounced = [
                SELECT Id,
                       TargetId,
                       State,
                       ErrorCode,
                       CompletionReason,
                       ActionCadenceName
                FROM ActionCadenceStepTracker
                WHERE ActionCadenceName = :CADENCE_NAME
                AND StepType = 'SendAnEmail'
                AND (
                    State = 'Cancelled'
                    OR ErrorCode != null
                )
            ];
        } catch (Exception e) {
            System.debug('Query error: ' + e.getMessage());
            return;
        }
        
        System.debug('Bounced/Error steps: ' 
                    + bounced.size());
        if (bounced.isEmpty()) return;
        
        Set<Id> contactIds = new Set<Id>();
        Set<Id> leadIds    = new Set<Id>();
        
        for (ActionCadenceStepTracker t : bounced) {
            if (t.TargetId == null) continue;
            System.debug('ErrorCode: ' + t.ErrorCode 
                        + ' Target: ' + t.TargetId);
            String px = String.valueOf(
                t.TargetId).substring(0,3);
            if (px == '003') contactIds.add(t.TargetId);
            if (px == '00Q') leadIds.add(t.TargetId);
        }
        
        List<CampaignMember> toUpdate = 
            new List<CampaignMember>();
        
        for (CampaignMember cm : [
            SELECT Id, ContactId, LeadId, Status
            FROM CampaignMember
            WHERE CampaignId = :camp.Id
            AND (ContactId IN :contactIds
                 OR LeadId IN :leadIds)
            AND Status = 'Sent'
        ]) {
            cm.Status = 'Bounced';
            toUpdate.add(cm);
        }
        
        if (!toUpdate.isEmpty()) {
            try {
                update toUpdate;
                System.debug('Bounced updated: ' 
                            + toUpdate.size());
            } catch (DmlException e) {
                System.debug('DML error: ' + e.getMessage());
            }
        }
        System.debug('=== END syncBouncedEmails ===');
    }
    
    // ═══════════════════════════════════════
    // MASTER RUN — Calls all sync methods
    // Called by scheduler
    // ═══════════════════════════════════════
    public static void runFullSync() {
        System.debug('============================');
        System.debug('=== FULL SYNC STARTED    ===');
        System.debug('=== ' + DateTime.now() + ' ===');
        System.debug('============================');
        
        syncEnrollments();
        syncCadenceStates();
        syncBouncedEmails();
        
        System.debug('============================');
        System.debug('=== FULL SYNC COMPLETED  ===');
        System.debug('============================');
    }
    
    // ─────────────────────────────────────
    // Helper: Get Campaign
    // ─────────────────────────────────────
    private static Campaign getCampaign() {
        List<Campaign> camps = [
            SELECT Id, Name
            FROM Campaign
            WHERE Name = :CAMPAIGN_NAME
            LIMIT 1
        ];
        if (camps.isEmpty()) {
            System.debug('Campaign not found: ' 
                        + CAMPAIGN_NAME);
            return null;
        }
        System.debug('Campaign found: ' + camps[0].Id);
        return camps[0];
    }
    
    // ─────────────────────────────────────
    // Helper: Status priority
    // Higher = more engaged
    // ─────────────────────────────────────
    public static Integer getStatusPriority(String status) {
        Map<String, Integer> p = new Map<String, Integer>{
            'Not Sent'     => 0,
            'Sent'         => 1,
            'Opened'       => 2,
            'Clicked'      => 3,
            'Replied'      => 4,
            'Placed Order' => 5,
            'Offboarded'   => 6,
            'Opted Out'    => 7,
            'Bounced'      => 8
        };
        return p.containsKey(status) ? p.get(status) : 0;
    }
}