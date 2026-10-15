/*
 * Consolidated handler for the Event object trigger.
 * Each method below corresponds to the logic that previously lived in its own standalone trigger:
 *   - handleUpdateUserRole    <- EventUpdateUserRole.trigger
 *   - handleCaseFirstActivity <- EventCaseFirstActivity.trigger
 *   - handleLeadFirstActivity <- EventLeadFirstActivity.trigger
 *   - handleConvertLead       <- ConvertLead.trigger
 *
 */
public class EventHandler {

    // Formerly EventUpdateUserRole.trigger (before insert)
    public static void handleUpdateUserRole(List<Event> newEvents) {
        Set<Id> ownerIds = new Set<Id>();
        for (Event e : newEvents) {
            if (e.OwnerId != null && String.valueOf(e.OwnerId).startsWith('005')) {
                ownerIds.add(e.OwnerId);
            }
        }
        if (ownerIds.isEmpty()) {
            return;
        }

        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, UserRole.Name, Profile.Name FROM User WHERE Id IN :ownerIds]);

        for (Event e : newEvents) {
            User u = userMap.get(e.OwnerId);
            if (u != null) {
                e.User_Role__c = u.UserRole != null ? u.UserRole.Name : null;
                e.User_Profile__c = u.Profile.Name;
            }
        }
    }

    // Formerly EventCaseFirstActivity.trigger (after insert)
    // Compute the number of hours between when the case is created and the first activity (event or task)
    public static void handleCaseFirstActivity(List<Event> newEvents) {
        Set<Id> whatIds = new Set<Id>();
        for (Event e : newEvents) {
            if (e.WhatId != null) {
                whatIds.add(e.WhatId);
            }
        }
        if (whatIds.isEmpty()) {
            return;
        }

        Map<Id, Case> caseMap = new Map<Id, Case>( [SELECT Id, CreatedDate FROM Case WHERE Id IN :whatIds] );
        if (caseMap.isEmpty()) {
            return;
        }

        Map<Id, Datetime> firstActivityByCaseId = new Map<Id, Datetime>();

        for (Task t : [SELECT Id, WhatId, CreatedDate FROM Task WHERE WhatId IN :caseMap.keySet() ORDER BY CreatedDate]) {
            if (!firstActivityByCaseId.containsKey(t.WhatId)) {
                firstActivityByCaseId.put(t.WhatId, t.CreatedDate);
            }
        }

        for (Event ev : [SELECT Id, WhatId, CreatedDate FROM Event WHERE WhatId IN :caseMap.keySet() ORDER BY CreatedDate]) {
            Datetime earliest = firstActivityByCaseId.get(ev.WhatId);
            if (earliest == null || ev.CreatedDate < earliest) {
                firstActivityByCaseId.put(ev.WhatId, ev.CreatedDate);
            }
        }

        List<Case> casesToUpdate = new List<Case>();
        for (Case c : caseMap.values()) {
            Datetime firstActivity = firstActivityByCaseId.get(c.Id);
            if (firstActivity == null) {
                continue;
            }
            Decimal deltaHours = (firstActivity.getTime() - c.CreatedDate.getTime()) / 1000.0 / 3600;
            casesToUpdate.add(new Case(Id = c.Id, Time_to_First_Response__c = deltaHours));
        }

        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
    }

    // Formerly EventLeadFirstActivity.trigger (after insert)
    // Compute the number of hours between when the lead is created and the first activity (event or task)
    public static void handleLeadFirstActivity(List<Event> newEvents) {
        Set<Id> whoIds = new Set<Id>();
        for (Event e : newEvents) {
            if (e.WhoId != null) {
                whoIds.add(e.WhoId);
            }
        }
        if (whoIds.isEmpty()) {
            return;
        }

        Map<Id, Lead> leadMap = new Map<Id, Lead>( [SELECT Id, CreatedDate, Assigned_Date__c FROM Lead WHERE Id IN :whoIds]);
        if (leadMap.isEmpty()) {
            return;
        }

        Map<Id, Datetime> startDateByLeadId = new Map<Id, Datetime>();
        for (Lead l : leadMap.values()) {
            Datetime startDate = l.CreatedDate;
            if (l.Assigned_Date__c > startDate) {
                startDate = l.Assigned_Date__c;
            }
            startDateByLeadId.put(l.Id, startDate);
        }

        Map<Id, Datetime> firstActivityByLeadId = new Map<Id, Datetime>();

        for (Task t : [SELECT Id, WhoId, CreatedDate FROM Task
                       WHERE WhoId IN :leadMap.keySet()
                       AND Subject != 'Lead On Pro. Please Contact!'
                       AND Subject != 'New Lead! Please contact'
                       ORDER BY CreatedDate]) {
            Datetime startDate = startDateByLeadId.get(t.WhoId);
            if (startDate == null || t.CreatedDate <= startDate) {
                continue;
            }
            if (!firstActivityByLeadId.containsKey(t.WhoId)) {
                firstActivityByLeadId.put(t.WhoId, t.CreatedDate);
            }
        }

        for (Event ev : [SELECT Id, WhoId, CreatedDate FROM Event
                         WHERE WhoId IN :leadMap.keySet()
                         ORDER BY CreatedDate]) {
            Datetime startDate = startDateByLeadId.get(ev.WhoId);
            if (startDate == null || ev.CreatedDate <= startDate) {
                continue;
            }
            Datetime earliest = firstActivityByLeadId.get(ev.WhoId);
            if (earliest == null || ev.CreatedDate < earliest) {
                firstActivityByLeadId.put(ev.WhoId, ev.CreatedDate);
            }
        }

        List<Lead> leadsToUpdate = new List<Lead>();
        for (Lead l : leadMap.values()) {
            Datetime firstActivity = firstActivityByLeadId.get(l.Id);
            Decimal deltaHours = null;
            if (firstActivity != null) {
                Datetime startDate = startDateByLeadId.get(l.Id);
                deltaHours = (firstActivity.getTime() - startDate.getTime()) / 1000.0 / 3600;
            }
            leadsToUpdate.add(new Lead(Id = l.Id, Time_to_First_Response__c = deltaHours));
        }

        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
    }

    // Formerly ConvertLead.trigger (after insert, after update)
    // Update Lead fields when there is an Initial Meeting with correct contact
    public static void handleConvertLead(List<Event> newEvents) {
        Set<Id> whoIds = new Set<Id>();
        for (Event e : newEvents) {
            if (e.Subject == 'Initial Meeting' && e.Meeting_Result__c == 'Held - Correct Contact' && e.WhoId != null) {
                whoIds.add(e.WhoId);
            }
        }
        if (whoIds.isEmpty()) {
            return;
        }

        Map<Id, Lead> leadMap = new Map<Id, Lead>( [SELECT Id FROM Lead WHERE Id IN :whoIds] );
        if (leadMap.isEmpty()) {
            return;
        }

        Map<Id, Lead> leadsToUpdate = new Map<Id, Lead>();
        for (Event e : newEvents) {
            if (e.Subject == 'Initial Meeting' && e.Meeting_Result__c == 'Held - Correct Contact') {
                Lead lead = leadMap.get(e.WhoId);
                if (lead == null) {
                    continue;
                }
                leadsToUpdate.put(lead.Id, new Lead(
                    Id = lead.Id,
                    IMHeld__c = true,
                    InitialMeetingDate__c = e.ActivityDate,
                    OwnerId = e.OwnerId
                ));
            }
        }

        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate.values();
        }
    }
}