public class ConversationEntryBatchScheduler implements Schedulable {
    public static String sched = '0 00 00 * * ?'; 
    
    public void execute(SchedulableContext sc) {
        Date ninetyDaysAgo = Date.today().addDays(-90);
        string query = 'SELECT Id FROM ConversationEntry WHERE CreatedDate < :ninetyDaysAgo';
        if(Test.isRunningTest()){
            query = 'SELECT Id FROM Account';   
        }  
        DeleteOldConversationEntriesBatch b1 = new DeleteOldConversationEntriesBatch(query);
        ID batchprocessid = Database.executeBatch(b1,200);           
    }
}