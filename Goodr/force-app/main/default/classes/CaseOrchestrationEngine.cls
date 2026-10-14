public with sharing class CaseOrchestrationEngine {
    
    public static void process(List<Case> newCases,
                               Map<Id, Case> oldMap) {
                                   
        if (newCases == null || newCases.isEmpty()) return;
        
        // INITIAL SETUP
        
        List<CaseTeamMember> teamToInsert = new List<CaseTeamMember>();
        Map<Id, Case> casesToUpdateMap = new Map<Id, Case>();
        
        for (Case c : newCases) {
            casesToUpdateMap.put(c.Id, new Case(Id = c.Id));
        }
        
        // CASE TEAM + OWNER ASSIGNMENT 
        
        Set<Id> queueIds = new Set<Id>();
        Map<Id, Case> casesForTeam = new Map<Id, Case>();
        
        for (Case c : newCases) {
            
            Boolean ownerChanged = oldMap == null ||
                c.OwnerId != oldMap.get(c.Id)?.OwnerId;
            
            if (ownerChanged &&
                c.OwnerId != null &&
                String.valueOf(c.OwnerId).startsWith('00G')) {
                    
                queueIds.add(c.OwnerId);
                casesForTeam.put(c.Id, c);
            }
        }
        
        if (!queueIds.isEmpty()) {
            
            Map<Id, Group> queueMap =
                new Map<Id, Group>(
                    [SELECT Id, Name FROM Group WHERE Id IN :queueIds]
                );
            
            Set<String> queueNames = new Set<String>();
            for (Group g : queueMap.values()) {
                queueNames.add(g.Name);
            }
            
            Map<String, Case_Queue_Team_Routing__mdt> routingMap =
                new Map<String, Case_Queue_Team_Routing__mdt>();
            
            for (Case_Queue_Team_Routing__mdt mdt : [
                SELECT Queue_Name__c,
                       Case_Team_Template__c,
                       Owner_Role_Name__c
                FROM Case_Queue_Team_Routing__mdt
                WHERE Queue_Name__c IN :queueNames
            ]) {
                routingMap.put(mdt.Queue_Name__c, mdt);
            }
            
            Set<String> templateNames = new Set<String>();
            for (Case_Queue_Team_Routing__mdt m : routingMap.values()) {
                templateNames.add(m.Case_Team_Template__c);
            }
            
            Map<String, CaseTeamTemplate> templateMap =
                new Map<String, CaseTeamTemplate>();
            
            if (!templateNames.isEmpty()) {
                for (CaseTeamTemplate t : [
                    SELECT Id, Name
                    FROM CaseTeamTemplate
                    WHERE Name IN :templateNames
                ]) {
                    templateMap.put(t.Name, t);
                }
            }
            
            Map<Id, List<CaseTeamTemplateMember>> templateMembersMap =
                new Map<Id, List<CaseTeamTemplateMember>>();
            
            if (!templateMap.isEmpty()) {
                for (CaseTeamTemplateMember tm : [
                    SELECT MemberId, TeamRoleId, TeamTemplateId
                    FROM CaseTeamTemplateMember
                    WHERE TeamTemplateId IN :templateMap.values()
                ]) {
                    if (!templateMembersMap.containsKey(tm.TeamTemplateId)) {
                        templateMembersMap.put(
                            tm.TeamTemplateId,
                            new List<CaseTeamTemplateMember>()
                        );
                    }
                    
                    templateMembersMap.get(tm.TeamTemplateId).add(tm);
                }
            }
            
            Set<Id> roleIds = new Set<Id>();
            for (List<CaseTeamTemplateMember> members :
                 templateMembersMap.values()) {
                for (CaseTeamTemplateMember tm : members) {
                    roleIds.add(tm.TeamRoleId);
                }
            }
            
            Map<Id, CaseTeamRole> roleMap = new Map<Id, CaseTeamRole>();
            if (!roleIds.isEmpty()) {
                roleMap = new Map<Id, CaseTeamRole>(
                    [SELECT Id, Name FROM CaseTeamRole WHERE Id IN :roleIds]
                );
            }
            
            for (Case c : casesForTeam.values()) {
                
                Group queue = queueMap.get(c.OwnerId);
                if (queue == null) continue;
                
                Case_Queue_Team_Routing__mdt routing =
                    routingMap.get(queue.Name);
                if (routing == null) continue;
                
                CaseTeamTemplate template =
                    templateMap.get(routing.Case_Team_Template__c);
                
                if (template == null ||
                    !templateMembersMap.containsKey(template.Id)) continue;
                
                Id newOwnerId;
                
                for (CaseTeamTemplateMember tm :
                     templateMembersMap.get(template.Id)) {
                    
                    teamToInsert.add(new CaseTeamMember(
                        ParentId = c.Id,
                        MemberId = tm.MemberId,
                        TeamRoleId = tm.TeamRoleId
                    ));
                    
                    if (roleMap.containsKey(tm.TeamRoleId) &&
                        roleMap.get(tm.TeamRoleId).Name ==
                        routing.Owner_Role_Name__c) {
                        newOwnerId = tm.MemberId;
                    }
                }
                
                if (newOwnerId != null &&
                    newOwnerId != c.OwnerId) {
                    casesToUpdateMap.get(c.Id).OwnerId = newOwnerId;
                }
            }
        }
        
        // SLA CALCULATION 
        
        Map<String, SLA_Configuration__mdt> slaMap =
            new Map<String, SLA_Configuration__mdt>();
        
        for (SLA_Configuration__mdt mdt : [
            SELECT Priority__c,
                   Email_To_Case_Address__c,
                   Business_Hours_Name__c,
                   First_Reply_Hours__c,
                   Next_Reply_Hours__c
            FROM SLA_Configuration__mdt
        ]) {
            slaMap.put(
                mdt.Priority__c + '-' + mdt.Email_To_Case_Address__c,
                mdt
            );
        }
        
        Set<String> bhNames = new Set<String>();
        for (SLA_Configuration__mdt m : slaMap.values()) {
            if (m.Business_Hours_Name__c != null)
                bhNames.add(m.Business_Hours_Name__c);
        }
        
        Map<String, BusinessHours> bhMap =
            new Map<String, BusinessHours>();
        
        if (!bhNames.isEmpty()) {
            for (BusinessHours bh : [
                SELECT Id, Name FROM BusinessHours
                WHERE Name IN :bhNames
            ]) {
                bhMap.put(bh.Name, bh);
            }
        }
        
        for (Case c : newCases) {
            
            Boolean isNew =
                oldMap == null || !oldMap.containsKey(c.Id);
            
            Boolean slaNeedsRecalc =
                isNew ||
                c.Priority != oldMap.get(c.Id)?.Priority ||
                c.Email_To_Case_Address__c !=
                oldMap.get(c.Id)?.Email_To_Case_Address__c;
            
            if (!slaNeedsRecalc) continue;
            
            if (c.Priority == null ||
                c.Email_To_Case_Address__c == null) continue;
            
            String key =
                c.Priority + '-' + c.Email_To_Case_Address__c;
            
            if (!slaMap.containsKey(key)) continue;
            
            SLA_Configuration__mdt sla = slaMap.get(key);
            
            if (sla.Business_Hours_Name__c == null ||
                !bhMap.containsKey(sla.Business_Hours_Name__c)) continue;
            
            BusinessHours bh =
                bhMap.get(sla.Business_Hours_Name__c);
            
            Datetime startDate =
                c.CreatedDate != null
                ? c.CreatedDate
                : System.now();
            
            Long firstMillis =
                (Long)(sla.First_Reply_Hours__c * 3600000);
            
            Datetime dueDate =
                BusinessHours.add(bh.Id, startDate, firstMillis);
            
            Case updateCase = casesToUpdateMap.get(c.Id);
            
            updateCase.SLA_Due_Date__c = dueDate;
            updateCase.SLA_Target_Date__c = startDate;
            updateCase.SLA_Hours__c =
                (Integer)Math.ceil(sla.First_Reply_Hours__c);
            updateCase.First_Reply_Time__c =
                sla.First_Reply_Hours__c;
            updateCase.Next_Reply_Time__c =
                sla.Next_Reply_Hours__c;
        }
        
        // PAUSE / RESUME + FIRST → NEXT REPLY SWITCH
        
        if (oldMap != null) {
            
            for (Case c : newCases) {
                
                if (!oldMap.containsKey(c.Id)) continue;
                
                Case oldCase = oldMap.get(c.Id);
                Case updateCase = casesToUpdateMap.get(c.Id);
                
                // FIRST REPLY CAPTURED → SWITCH TO NEXT SLA
                
               if (c.First_Response_Date__c != null &&
    (oldCase.First_Response_Date__c == null ||
     oldCase.First_Response_Date__c != c.First_Response_Date__c))
 {
                    
                    if (c.Priority != null &&
                        c.Email_To_Case_Address__c != null) {
                        
                        String key =
                            c.Priority + '-' + c.Email_To_Case_Address__c;
                        
                        if (slaMap.containsKey(key)) {
                            
                            SLA_Configuration__mdt sla =
                                slaMap.get(key);
                            
                            if (sla.Business_Hours_Name__c != null &&
                                bhMap.containsKey(sla.Business_Hours_Name__c)) {
                                
                                BusinessHours bh =
                                    bhMap.get(
                                        sla.Business_Hours_Name__c);
                                
                                Long nextMillis =
                                    (Long)(sla.Next_Reply_Hours__c * 3600000);
                                
                                Datetime newDueDate =
                                    BusinessHours.add(
                                        bh.Id,
                                        c.First_Response_Date__c,
                                        nextMillis
                                    );
                                
                                updateCase.SLA_Target_Date__c =
                                    c.First_Response_Date__c;
                                
                                updateCase.SLA_Due_Date__c =
                                    newDueDate;
                                updateCase.Next_SLA_Due_Date__c = newDueDate;
                            }
                        }
                    }
                }
                
                // EXISTING PAUSE / RESUME LOGIC (UNCHANGED)
                
                if (oldCase.Status != c.Status) {
                    
                    if (c.Status == 'On Hold' &&
                        oldCase.SLA_Paused__c == false) {
                        
                        updateCase.SLA_Paused__c = true;
                        updateCase.SLA_Pause_Start__c = System.now();
                    }
                    
                    if (oldCase.Status == 'On Hold' &&
                        c.Status != 'On Hold' &&
                        oldCase.SLA_Paused__c == true &&
                        oldCase.SLA_Pause_Start__c != null) {
                        
                        Long pausedMillis =
                            System.now().getTime() -
                            oldCase.SLA_Pause_Start__c.getTime();
                        
                        Long existingMillis =
                            oldCase.Total_Pause_Millis__c == null
                            ? 0
                            : oldCase.Total_Pause_Millis__c.longValue();
                        
                        updateCase.Total_Pause_Millis__c =
                            existingMillis + pausedMillis;
                        
                        updateCase.SLA_Paused__c = false;
                        updateCase.SLA_Pause_Start__c = null;
                        
                        if (oldCase.SLA_Due_Date__c != null &&
                            c.Priority != null &&
                            c.Email_To_Case_Address__c != null) {
                            
                            String key =
                                c.Priority + '-' +
                                c.Email_To_Case_Address__c;
                            
                            if (slaMap.containsKey(key)) {
                                
                                SLA_Configuration__mdt sla =
                                    slaMap.get(key);
                                
                                if (bhMap.containsKey(
                                    sla.Business_Hours_Name__c)) {
                                    
                                    BusinessHours bh =
                                        bhMap.get(
                                            sla.Business_Hours_Name__c);
                                    
                                    updateCase.SLA_Due_Date__c =
                                        BusinessHours.add(
                                            bh.Id,
                                            oldCase.SLA_Due_Date__c,
                                            pausedMillis
                                        );
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // FINAL DML
        
        if (!teamToInsert.isEmpty()) {
            insert teamToInsert;
        }
        
        List<Case> finalUpdates =
            new List<Case>(casesToUpdateMap.values());
        
        if (!finalUpdates.isEmpty()) {
            update finalUpdates;
        }
    }
}