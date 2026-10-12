public inherited sharing class APILogCleanupBatch implements Database.Batchable<SObject>, Schedulable {

    // ── CHANGED: retention window extended from 90 days to 6 calendar months.   ──
    // ── addMonths() is used instead of a fixed day-count (e.g. addDays(-180))   ──
    // ── so the cutoff is a true "6 months ago" regardless of which months it    ──
    // ── spans (28/29/30/31-day months), rather than an approximation.          ──
    public Database.QueryLocator start(Database.BatchableContext BC) {
        Date cutoffDate = System.today().addMonths(-6);
        return Database.getQueryLocator([
            SELECT Id FROM API_Log__c WHERE CreatedDate < :cutoffDate
        ]);
    }

    public void execute(Database.BatchableContext BC, List<API_Log__c> scope) {
        delete scope;
    }

    public void finish(Database.BatchableContext BC) {}

    public void execute(SchedulableContext SC) {
        Database.executeBatch(new APILogCleanupBatch(), 200);
    }

                            
    public static void scheduleDailyJob() {
        String cronExp = '0 0 2 * * ?';
        System.schedule('API Error Log Cleanup', cronExp, new APILogCleanupBatch());
    }
}