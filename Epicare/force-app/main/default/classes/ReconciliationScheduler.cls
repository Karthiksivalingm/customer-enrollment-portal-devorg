/**
 * Package 3.5 — schedules CommissionReconciliationEngine twice daily
 * (2 AM / 2 PM ET) per Sec. 9.4 "Scheduled Sync (Apex Batch)" row.
 *
 * Batch chunk size kept modest (50) since each execute() does an
 * external callout per chunk — stay well under the 100-callout/txn
 * limit even if GO AMS's response payload forces a retry pattern later.
 */
public with sharing class ReconciliationScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CommissionReconciliationEngine(), 50);
    }
}