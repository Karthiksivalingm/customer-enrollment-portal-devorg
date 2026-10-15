/**
 * PolicyYearIncrementScheduler
 * ------------------------------------------------------------------
 * Run AFTER Payment_Batch processing finishes each night — confirm the
 * actual scheduled time of that job before picking this one's CRON, so
 * this doesn't read stale Commission_Record__c Paid counts.
 *
 * System.schedule's CRON runs in the ORG'S DEFAULT TIME ZONE, not
 * literally "EST" — if the org default isn't US Eastern, either change
 * it or schedule this via Setup > Scheduled Jobs UI instead, where you
 * can see/confirm the actual run time. DST also shifts ET between
 * EST/EDT; scheduling through Setup avoids having to hand-adjust the
 * CRON twice a year.
 *
 * Example (assumes org default time zone = US Eastern):
 *   System.schedule('Policy Year Increment - Nightly',
 *       '0 0 2 * * ?', new PolicyYearIncrementScheduler());
 */
public with sharing class PolicyYearIncrementScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new PolicyYearIncrementBatch(), 200);
    }
}