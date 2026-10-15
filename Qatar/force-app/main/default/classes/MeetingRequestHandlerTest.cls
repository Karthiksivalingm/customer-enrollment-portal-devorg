@isTest
public class MeetingRequestHandlerTest {
 /*   @isTest
    static void testCreateMinutesOfMeeting() {
      
        Meeting_Request__c meeting = new Meeting_Request__c(Name = 'Test Meeting');
        insert meeting;

       
        Agenda_Item__c agendaItem = new Agenda_Item__c(Name = 'Test Agenda', Meeting_Request__c = meeting.Id);
        insert agendaItem;

      
        Attendees__c attendee = new Attendees__c(Meeting_Request__c = meeting.Id);
        insert attendee;

        
        List<Meeting_Request__c> completedMeetings = [SELECT Id, Name FROM Meeting_Request__c WHERE Id = :meeting.Id];

       
        Test.startTest();
        MeetingRequestHandler.createMinutesOfMeeting(completedMeetings);
        Test.stopTest();


    }*/
}