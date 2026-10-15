public with sharing class GuestSessionAttendanceController {
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getSessionAttendance(Id guestListId, Integer pageSize, Integer offset) {
        Integer ps = pageSize != null ? pageSize : 20;
        Integer os = offset   != null ? offset   : 0;
        Integer totalCount = [
            SELECT COUNT() FROM Session_Attendance__c WHERE Guest_List__c = :guestListId
        ];
        List<Session_Attendance__c> records = [
            SELECT
                Id,
                Sub_Event_Name__c,
                Sub_Event__c,
                Sub_Event__r.Sub_Event_Name__c,
                Attended__c,
                Registered__c,
                Event_Name__c,
                Events_List__c
            FROM Session_Attendance__c
            WHERE Guest_List__c = :guestListId
            ORDER BY CreatedDate ASC
            LIMIT :ps OFFSET :os
        ];
        List<SessionWrapper> wrappers = new List<SessionWrapper>();
        Integer idx = os + 1;
        for (Session_Attendance__c r : records) {
            SessionWrapper w  = new SessionWrapper();
            w.id              = r.Id;
            w.rowNum          = idx++;
            // Sub_Event_Name__c on Session_Attendance__c isn't kept in sync,
            // so pull the real name from the related Sub_Event__c record and
            // only fall back to the local field if the lookup is empty.
            w.subEventName    = (r.Sub_Event__r != null && String.isNotBlank(r.Sub_Event__r.Sub_Event_Name__c))
                                    ? r.Sub_Event__r.Sub_Event_Name__c
                                    : r.Sub_Event_Name__c;
            w.subEventId      = r.Sub_Event__c;
            w.attended        = r.Attended__c == true;
            w.registered      = r.Registered__c == true;
            w.eventName       = r.Event_Name__c;
            w.eventsListId    = r.Events_List__c;
            wrappers.add(w);
        }
        Map<String, Object> result = new Map<String, Object>();
        result.put('records',    wrappers);
        result.put('totalCount', totalCount);
        result.put('hasMore',    (os + ps) < totalCount);
        return result;
    }
    public class SessionWrapper {
        @AuraEnabled public String  id;
        @AuraEnabled public Integer rowNum;
        @AuraEnabled public String  subEventName;
        @AuraEnabled public String  subEventId;
        @AuraEnabled public Boolean attended;
        @AuraEnabled public Boolean registered;
        @AuraEnabled public String  eventName;
        @AuraEnabled public String  eventsListId;
    }
}