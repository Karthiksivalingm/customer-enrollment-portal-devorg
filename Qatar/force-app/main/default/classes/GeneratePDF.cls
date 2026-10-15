public class GeneratePDF {
    public Minutes_Of_Meeting__c MOM {get; set;}
    public List<Agenda__c> Agendas {get; set;}
    public Id MOMId {get; set;}

    public GeneratePDF(){
        MOMId = ApexPages.currentPage().getParameters().get('id');
        if (MOMId != null) {
            MOM = [SELECT Id, Name FROM Minutes_Of_Meeting__c WHERE Id =:MOMId];
            Agendas = [SELECT Id, Name,CPO_Entity__c,CPO_Team_member__c,Meeting_Notes__c,Update_Comment__c
                      FROM Agenda__c WHERE Minutes_Of_Meeting__c =:MOMId];
        }
    }
}