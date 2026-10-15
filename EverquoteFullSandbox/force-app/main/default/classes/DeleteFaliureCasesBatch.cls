global class DeleteFaliureCasesBatch implements Database.Batchable<SObject>, Database.Stateful {
    
   private String query;
    global DeleteFaliureCasesBatch(String query) {
        this.query = query;
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        if (!scope.isEmpty()) {
            Database.delete(scope, true); 
        }
    }
    global void finish(Database.BatchableContext bc) {
        System.debug('Batch job to delete Task finished.');
    }
}