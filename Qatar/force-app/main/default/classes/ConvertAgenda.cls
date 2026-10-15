public class ConvertAgenda {
    @AuraEnabled
    public static String createAction(String recordId) {
        String res = 'success';
        
        Agenda__c sourceRecord = [SELECT Id, Name, Meeting_Notes__c, Meetings__c FROM Agenda__c WHERE Id = :recordId];
        
        Action_Item__c targetRecord = new Action_Item__c();
        targetRecord.Name = sourceRecord.Name;
        targetRecord.Meetings__c = sourceRecord.Meetings__c;
        targetRecord.Notes__c = sourceRecord.Meeting_Notes__c;
        
        insert targetRecord;
        
        if (targetRecord != null) {
            return res;
        } else {
            // Provide a return statement for the case where targetRecord is null
            return 'error'; // Or any other appropriate error message
        }
    }
}