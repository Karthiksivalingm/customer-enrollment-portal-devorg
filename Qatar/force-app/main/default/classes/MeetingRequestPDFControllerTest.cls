@isTest
public class MeetingRequestPDFControllerTest {
    @isTest
    static void testMeetingRequestPDFController() {
      
        Meeting_Request__c meetingRequest = new Meeting_Request__c(
            Name = 'Test Meeting', 
            Subject__c = 'Test Subject', 
            Status__c = 'Completed', 
            Meeting_Type__c = 'Weekly Meeting'
        );
        insert meetingRequest;

        
        Agenda_Item__c agendaItem1 = new Agenda_Item__c(
            Name = 'Agenda Item 1', 
            Meeting_Request__c = meetingRequest.Id, 
            Comment_from_her__c = 'Comment 1'
        );
        Agenda_Item__c agendaItem2 = new Agenda_Item__c(
            Name = 'Agenda Item 2', 
            Meeting_Request__c = meetingRequest.Id, 
            Comment_from_her__c = 'Comment 2'
        );
        insert new List<Agenda_Item__c> { agendaItem1, agendaItem2 };

       
        Attendees__c attendee1 = new Attendees__c(
            Meeting_Request__c = meetingRequest.Id, 
            Responded__c = 'Yes'
        );
        Attendees__c attendee2 = new Attendees__c(
            Meeting_Request__c = meetingRequest.Id, 
            Responded__c = 'No'
        );
        insert new List<Attendees__c> { attendee1, attendee2 };

       
        PageReference pageRef = Page.MeetingRequestPDFPage; 
        pageRef.getParameters().put('id', meetingRequest.Id);
        Test.setCurrentPage(pageRef);

       
        MeetingRequestPDFController controller = new MeetingRequestPDFController();

        
        System.assertEquals(meetingRequest.Id, controller.meetingRequest.Id, 'The meeting request should be the same.');
        System.assertEquals(2, controller.agendaItems.size(), 'There should be 2 agenda items.');
        System.assertEquals(2, controller.Attendees.size(), 'There should be 2 attendees.');

       
        Test.startTest();
       
        Test.stopTest();
    }
}