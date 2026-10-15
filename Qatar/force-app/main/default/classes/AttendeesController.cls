public class AttendeesController {
    @AuraEnabled
    public static List<Attendees__c> getAttendees(Id meetingRequestId) {
        return [SELECT Id, Name, Responded__c FROM Attendees__c WHERE Meeting_Request__c = :meetingRequestId];
    }

    @AuraEnabled
    public static Attendees__c saveAttendee(Attendees__c attendee) {
        upsert attendee;
        return attendee;
    }

    @AuraEnabled
    public static void deleteAttendee(Id attendeeId) {
        delete [SELECT Id FROM Attendees__c WHERE Id = :attendeeId];
    }
}