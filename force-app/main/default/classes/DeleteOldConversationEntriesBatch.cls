public class DeleteOldConversationEntriesBatch implements Database.Batchable<SObject>, Database.Stateful {
    private string query;
    public DeleteOldConversationEntriesBatch(String query){
        this.query=query;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Sobject> scope) {
        try {
            delete scope;
        } catch (Exception e) {
            System.debug('Error deleting records: ' + e.getMessage());
        }
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('Batch job completed successfully.');
    }
}