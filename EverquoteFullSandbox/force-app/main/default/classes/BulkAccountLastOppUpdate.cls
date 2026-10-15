public class BulkAccountLastOppUpdate implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc){
      String query = 'SELECT Id,Last_Opportunity_was_Close_Lost__c,(SELECT Id,Stagename FROM Opportunities ORDER BY closeDate DESC) FROM Account WHERE Last_Opportunity_was_Close_Lost__c = false';
        return Database.getQueryLocator(query);
   }
   public void execute(Database.BatchableContext bc, List<Account> accList ){
       List<Account> listOfAcc = new List<Account>();
       for(Account acc:accList){
          if(acc.opportunities.size()>0 && acc.opportunities[0].stageName =='Closed Lost'){
        acc.Last_Opportunity_was_Close_Lost__c = true;
            listOfAcc.add(acc);
              
       }
    
    }
       update listOfAcc;
   }
   public void finish(Database.BatchableContext bc){
   }
}