// === BATCH/SCHEDULABLE FRAMEWORK ===
// Wraps the batch class so it can run automatically on a recurring schedule.
public class NetSuiteSyncScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new NetSuiteProductSyncBatch(), 100);
    }
}