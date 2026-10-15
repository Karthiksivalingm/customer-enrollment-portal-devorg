@isTest
public class MomPDFControllerTest {
    
    @testSetup
    static void setupTestData() {
       
        Meeting_Request__c testMeetingRequest = new Meeting_Request__c(
            Name = 'Test Meeting Request'
        );
        insert testMeetingRequest;

    
        Minutes_Of_Meeting__c testMinutes = new Minutes_Of_Meeting__c(
            Name = 'Test Meeting',
            Date__c = Date.today(),
            Meeting_Request__c = testMeetingRequest.Id
        );
        insert testMinutes;
        
        
        Agenda_Item__c testAgendaItem = new Agenda_Item__c(
            Name = 'Test Agenda Item',
            Minutes_Of_Meeting__c = testMinutes.Id,
            Attendees_Update__c = 'Test Update',
            HE_Comments__c = 'Test Comments'
        );
        insert testAgendaItem;
        
      
        Action_Item__c testActionItem = new Action_Item__c(
            Agenda_Item__c = testAgendaItem.Id,
            OwnerId = UserInfo.getUserId(),
            Due_Date__c = Date.today().addDays(7)
        );
        insert testActionItem;
        
       
        Attendees__c testAttendee = new Attendees__c(
            Minutes_Of_Meeting__c = testMinutes.Id,
            Responded__c = 'Yes'
        );
        insert testAttendee;
    }

    @isTest
    static void testController() {
        
        Minutes_Of_Meeting__c testMinutes = [SELECT Id FROM Minutes_Of_Meeting__c LIMIT 1];
        ApexPages.currentPage().getParameters().put('id', testMinutes.Id);
        MomPDFController controller = new MomPDFController();
    
    }
}