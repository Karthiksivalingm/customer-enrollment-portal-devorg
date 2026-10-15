public with sharing class SessionAttendanceController {
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getSessionAttendance(Id subEventId, Integer pageSize, Integer offset) {
        Integer ps = pageSize != null ? pageSize : 20;
        Integer os = offset   != null ? offset   : 0;
        Integer totalCount = [
            SELECT COUNT() FROM Session_Attendance__c WHERE Sub_Event__c = :subEventId
        ];
        List<Session_Attendance__c> records = [
            SELECT
                Id,
                Guest_Name__c,
                Guest_List__r.Contact__r.Name,
                Guest_List__r.Contact__r.Contact_External_Id__c,
                Guest_List__r.Contact__c,
                Guest_List__c,
                Attended__c,
                Registered__c,
                Event_Name__c,
                Events_List__c
            FROM Session_Attendance__c
            WHERE Sub_Event__c = :subEventId
            ORDER BY Guest_Name__c ASC
            LIMIT :ps OFFSET :os
        ];
        List<SessionAttendanceWrapper> wrappers = new List<SessionAttendanceWrapper>();
        Integer idx = os + 1;
        for (Session_Attendance__c r : records) {
            SessionAttendanceWrapper w = new SessionAttendanceWrapper();
            w.id            = r.Id;
            w.rowNum        = idx++;
            // Guest_Name__c on Session_Attendance__c isn't kept in sync, so
            // pull the real name from the related Contact via Guest_List__r
            // and only fall back to the local field if that's empty.
            w.guestName     = (r.Guest_List__r != null && r.Guest_List__r.Contact__r != null
                                    && String.isNotBlank(r.Guest_List__r.Contact__r.Name))
                                ? r.Guest_List__r.Contact__r.Name
                                : r.Guest_Name__c;
            w.contactId     = r.Guest_List__r != null ? r.Guest_List__r.Contact__c : '';
            w.contactExtId  = r.Guest_List__r != null && r.Guest_List__r.Contact__r != null
                                ? r.Guest_List__r.Contact__r.Contact_External_Id__c : '';
            w.guestListId   = r.Guest_List__c;
            w.attended      = r.Attended__c == true;
            w.registered    = r.Registered__c == true;
            w.eventName     = r.Event_Name__c;
            w.eventsListId  = r.Events_List__c;
            wrappers.add(w);
        }
        Map<String, Object> result = new Map<String, Object>();
        result.put('records',    wrappers);
        result.put('totalCount', totalCount);
        result.put('hasMore',    (os + ps) < totalCount);
        return result;
    }
    public class SessionAttendanceWrapper {
        @AuraEnabled public String  id;
        @AuraEnabled public Integer rowNum;
        @AuraEnabled public String  guestName;
        @AuraEnabled public String  contactId;
        @AuraEnabled public String  contactExtId;
        @AuraEnabled public String  guestListId;
        @AuraEnabled public Boolean attended;
        @AuraEnabled public Boolean registered;
        @AuraEnabled public String  eventName;
        @AuraEnabled public String  eventsListId;
    }
}