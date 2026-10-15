/**
 * MissingPaymentScheduler
 * ------------------------------------------------------------------
 * Runs MissingPaymentBatch automatically, checking the PREVIOUS
 * completed month (not the current month, which is still in progress
 * and would produce false Missing_Payment flags for policies whose
 * carrier files just haven't arrived yet this month).
 *
 * OPEN QUESTION FOR CLIENT: the original spec says to run this "after
 * you're confident that period's Data Loader imports are all in" -
 * that's a judgment call, not a fixed time. This assumes checking the
 * prior month is safe by the time this runs nightly. If carrier files
 * can legitimately arrive later than that (e.g. mid-month corrections
 * for the prior period), this needs a longer buffer or a manual trigger
 * instead of a nightly schedule - confirm with the client.
 *
 * Schedule via Setup > Scheduled Jobs (recommended over hardcoding a
 * CRON here, for the same timezone/DST reasons as PolicyYearIncrementScheduler).
 * Example:
 *   System.schedule('Missing Payment Check - Nightly',
 *       '0 30 2 * * ?', new MissingPaymentScheduler());
 */
public with sharing class MissingPaymentScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new MissingPaymentBatch(computePreviousPeriod()), 200);
    }

    private String computePreviousPeriod() {
        Date today = Date.today();
        Date firstOfThisMonth = Date.newInstance(today.year(), today.month(), 1);
        Date lastMonth = firstOfThisMonth.addDays(-1);
        return lastMonth.year() + '-' + String.valueOf(lastMonth.month()).leftPad(2, '0');
    }
}