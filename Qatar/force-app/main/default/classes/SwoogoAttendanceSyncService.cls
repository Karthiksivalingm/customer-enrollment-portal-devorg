public with sharing class SwoogoAttendanceSyncService {

    public static void syncAttendances(
        List<SwoogoApiClient.SessionAttendance> attendances,
        List<SwoogoApiClient.SwoogoRegistrant>  registrants,
        Id invitationId)
    {
        if (attendances == null || attendances.isEmpty()) return;
        if (invitationId == null) return;

        // Build registrant_id → session_ids map for Registered__c
        Map<String, Set<String>> regIdToSessionIds = new Map<String, Set<String>>();
        if (registrants != null) {
            for (SwoogoApiClient.SwoogoRegistrant r : registrants) {
                if (r.id == null) continue;
                Set<String> sids = new Set<String>();
                if (r.session_ids != null) sids.addAll(r.session_ids);
                regIdToSessionIds.put(String.valueOf(r.id), sids);
            }
        }

        // Build session_id → Sub_Event__c Id
        Set<String> swoSessionIds = new Set<String>();
        for (SwoogoApiClient.SessionAttendance a : attendances)
            if (a.session_id != null) swoSessionIds.add(String.valueOf(a.session_id));

        Map<String, Id> subEventIdMap = new Map<String, Id>();
        for (Sub_Event__c se : [
            SELECT Id, Sub_Event_ID__c FROM Sub_Event__c
            WHERE Invitation__c = :invitationId
              AND Sub_Event_ID__c IN :swoSessionIds
        ]) subEventIdMap.put(se.Sub_Event_ID__c, se.Id);

        if (subEventIdMap.isEmpty()) return;

        // Build registrant_id → Guest_List__c Id
        Set<String> swoRegistrantIds = new Set<String>();
        for (SwoogoApiClient.SessionAttendance a : attendances)
            if (a.registrant_id != null)
                swoRegistrantIds.add(String.valueOf(a.registrant_id));

        Map<String, Id> guestIdMap = new Map<String, Id>();
        for (Guest_List__c g : [
            SELECT Id, Swoogo_Registrant_Id__c FROM Guest_List__c
            WHERE Swoogo_Registrant_Id__c IN :swoRegistrantIds
        ]) {
            if (String.isNotBlank(g.Swoogo_Registrant_Id__c))
                guestIdMap.put(g.Swoogo_Registrant_Id__c, g.Id);
        }

        // Deduplicate Swoogo rows by registrant_id|session_id
        Map<String, SwoogoApiClient.SessionAttendance> mergedByKey =
            new Map<String, SwoogoApiClient.SessionAttendance>();
        for (SwoogoApiClient.SessionAttendance a : attendances) {
            if (a.registrant_id == null || a.session_id == null) continue;
            String key = String.valueOf(a.registrant_id) + '|' + String.valueOf(a.session_id);
            if (!mergedByKey.containsKey(key)) {
                mergedByKey.put(key, a);
            } else {
                SwoogoApiClient.SessionAttendance m = mergedByKey.get(key);
                if (String.isNotBlank(a.check_in_date))  m.check_in_date  = a.check_in_date;
                if (String.isNotBlank(a.on_demand_date)) m.on_demand_date = a.on_demand_date;
                mergedByKey.put(key, m);
            }
        }

        // Query existing Session_Attendance__c records
        Set<Id> guestSfIds    = new Set<Id>(guestIdMap.values());
        Set<Id> subEventSfIds = new Set<Id>(subEventIdMap.values());

        Map<String, Session_Attendance__c> existing = new Map<String, Session_Attendance__c>();
        if (!guestSfIds.isEmpty() && !subEventSfIds.isEmpty()) {
            for (Session_Attendance__c sa : [
                SELECT Id, Guest_List__c, Sub_Event__c,
                       Attended__c, Registered__c, Events_List__c
                FROM Session_Attendance__c
                WHERE Guest_List__c IN :guestSfIds
                  AND Sub_Event__c  IN :subEventSfIds
            ]) existing.put(
                String.valueOf(sa.Guest_List__c) + '|' + String.valueOf(sa.Sub_Event__c), sa);
        }

        List<Session_Attendance__c> toInsert = new List<Session_Attendance__c>();
        List<Session_Attendance__c> toUpdate = new List<Session_Attendance__c>();

        for (SwoogoApiClient.SessionAttendance a : mergedByKey.values()) {
            String regKey  = String.valueOf(a.registrant_id);
            String sesKey  = String.valueOf(a.session_id);
            Id     guestId = guestIdMap.get(regKey);
            Id     subEvId = subEventIdMap.get(sesKey);

            if (guestId == null || subEvId == null) continue;

            Boolean newAttended = String.isNotBlank(a.check_in_date);

            Boolean newRegistered;
            if (regIdToSessionIds.containsKey(regKey)) {
                newRegistered = regIdToSessionIds.get(regKey).contains(sesKey);
            } else {
                newRegistered = newAttended;
            }

            String ck = String.valueOf(guestId) + '|' + String.valueOf(subEvId);

            if (existing.containsKey(ck)) {
                // Always update to ensure Attended__c and Registered__c
                // reflect current Swoogo state, regardless of what SF
                // currently holds — avoids stale records from being
                // silently skipped when values appear unchanged due to
                // type or comparison issues.
                Session_Attendance__c sa = existing.get(ck);
                sa.Attended__c    = newAttended;
                sa.Registered__c  = newRegistered;
                sa.Events_List__c = invitationId;
                toUpdate.add(sa);
            } else {
                toInsert.add(new Session_Attendance__c(
                    Guest_List__c  = guestId,
                    Sub_Event__c   = subEvId,
                    Events_List__c = invitationId,
                    Attended__c    = newAttended,
                    Registered__c  = newRegistered
                ));
            }
        }

        System.debug('AttendanceSync: toInsert=' + toInsert.size()
            + ' toUpdate=' + toUpdate.size());

        if (!toInsert.isEmpty()) {
            List<Database.SaveResult> results = Database.insert(toInsert, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess())
                    System.debug('SA INSERT FAILED: '
                        + results[i].getErrors()[0].getMessage()
                        + ' guest=' + toInsert[i].Guest_List__c
                        + ' subEvent=' + toInsert[i].Sub_Event__c);
            }
        }

        if (!toUpdate.isEmpty()) {
            List<Database.SaveResult> results = Database.update(toUpdate, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess())
                    System.debug('SA UPDATE FAILED: '
                        + results[i].getErrors()[0].getMessage()
                        + ' id=' + toUpdate[i].Id);
            }
        }
    }
}