global class AbortSwoogoJobsBatch implements Database.Batchable<SObject> {

    private String namePattern;

    global AbortSwoogoJobsBatch() {
        this('Swoogo%');
    }

    global AbortSwoogoJobsBatch(String namePattern) {
        this.namePattern = namePattern;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE :namePattern
            AND State NOT IN ('COMPLETE', 'DELETED', 'ERROR')
        ]);
    }

    global void execute(Database.BatchableContext bc, List<CronTrigger> scope) {
        for (CronTrigger ct : scope) {
            System.abortJob(ct.Id);
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Completed.');
    }
}