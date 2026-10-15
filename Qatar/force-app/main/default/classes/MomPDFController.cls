public class MomPDFController {
    public Minutes_Of_Meeting__c  minutes{get; set;}
    public Meeting_Request__c meetingRequest { get; set; }
    public list<Action_Item__c> actionitems{get;set;}
    public List<Agenda_Item__c> agendaItems { get; set; }
    public List<Attendees__c> Attendees{get; set;}
    public MomPDFController() {
        Id minutesId = ApexPages.currentPage().getParameters().get('id');
        minutes = [SELECT Name,Date__c,CreatedDate FROM Minutes_Of_Meeting__c 
                          WHERE Id = :minutesId];
        
        agendaItems = [SELECT Name, Comment_from_her__c, Owner.Name,Attendees_Update__c,HE_Comments__c
                       FROM Agenda_Item__c 
                       WHERE Minutes_Of_Meeting__c = :minutesId];
        actionitems=[SELECT Name,Agenda_Item__c,Owner.Name,Due_Date__c FROM Action_Item__c WHERE Minutes_Of_Meeting__c=:minutesId ];
        Attendees =[SELECT Name,Responded__c,Internal_Contacts__r.name,Name__c from Attendees__c where Minutes_Of_Meeting__c = :minutesId]; 
    }
}