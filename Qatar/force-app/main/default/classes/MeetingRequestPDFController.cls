public class MeetingRequestPDFController {
    public Meeting_Request__c meetingRequest { get; set; }
    public List<Agenda_Item__c> agendaItems { get; set; }
    public List<Attendees__c> Attendees{get; set;}
    public MeetingRequestPDFController() {
        Id meetingRequestId = ApexPages.currentPage().getParameters().get('id');
        meetingRequest = [SELECT Name, Subject__c, Status__c,Meeting_Type__c, 
                          CreatedDate
                          FROM Meeting_Request__c 
                          WHERE Id = :meetingRequestId];
        
        agendaItems = [SELECT Name, Comment_from_her__c, Owner.Name,Time_Alloted__c
                       FROM Agenda_Item__c 
                       WHERE Meeting_Request__c = :meetingRequestId];
        Attendees =[SELECT Name,Responded__c,Internal_Contacts__r.name,Name__c from Attendees__c where Meeting_Request__c = :meetingRequestId]; 
    }
}