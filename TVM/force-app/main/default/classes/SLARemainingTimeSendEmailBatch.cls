//Apex from FND 
global class SLARemainingTimeSendEmailBatch implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Status_Filtered__c, Remaining_Hours__c,OwnerId,SLA_Time_fe__c,Account.Regional_performance_manager__c, Mail_Sent__c FROM Case where Foundation_Record__c = True OR Case_Category__c = \'New Digital Support\'';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Case> caseList) {
        List<Case> lstcase =  New List<Case>();
        for(Case cs : caseList) {
            if((cs.Remaining_Hours__c == 0 && cs.Mail_Sent__c != true && cs.Status_Filtered__c != 'Future' && cs.Status_Filtered__c != 'Closed') &&
              (cs.SLA_Time_fe__c != 0 && cs.SLA_Time_fe__c != NULL)){
               cs.Mail_Sent__c = true; 
            }
            lstcase.add(cs);
        }
        try {
            update lstcase;
            
        } catch(Exception e) {
            System.debug(e);
        }
        
    }   
    
    global void finish(Database.BatchableContext BC) {
    }
}