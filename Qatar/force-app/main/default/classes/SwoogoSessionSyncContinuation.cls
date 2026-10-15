/**
 * SwoogoSessionSyncContinuation
 *
 * One-time scheduled job that kicks off the next chunk of
 * SwoogoSessionSyncBatch a few minutes after the previous chunk
 * finished. System.schedule requires a Schedulable, so this small
 * wrapper exists purely to bridge SwoogoSessionSyncBatch.finish()
 * scheduling its own continuation.
 *
 * This is NOT meant to be scheduled directly or recurring — each
 * instance fires exactly once, then SwoogoSessionSyncBatch.finish()
 * schedules a fresh one-off SwoogoSessionSyncContinuation for the
 * next chunk if events remain, and so on until the full event list
 * is processed.
 */
public with sharing class SwoogoSessionSyncContinuation implements Schedulable {

    private List<String> eventIds;
    private Boolean      isFirstRun;
    private Datetime     syncSince;
    private Datetime     batchStartTime;

    public SwoogoSessionSyncContinuation(
        List<String> eventIds,
        Boolean isFirstRun,
        Datetime syncSince,
        Datetime batchStartTime)
    {
        this.eventIds       = eventIds;
        this.isFirstRun     = isFirstRun;
        this.syncSince      = syncSince;
        this.batchStartTime = batchStartTime;
    }

    public void execute(SchedulableContext sc) {
        // Defensive: don't start if a Pass 2 batch is somehow still
        // running (shouldn't normally happen since each chunk waits
        // for the prior one to finish() before scheduling the next,
        // but guards against edge cases like manual re-runs overlapping).
        List<AsyncApexJob> running = [
            SELECT Id FROM AsyncApexJob
            WHERE ApexClass.Name = 'SwoogoSessionSyncBatch'
              AND Status IN ('Queued','Processing','Holding','Preparing')
            LIMIT 1
        ];
        if (!running.isEmpty()) {
            System.debug('SwoogoSessionSyncContinuation: a Pass 2 batch '
                + 'is already running — re-scheduling this continuation '
                + 'shortly instead of starting a duplicate');
            // Re-schedule a short retry rather than dropping the
            // remaining events entirely.
            Datetime retryAt = Datetime.now().addMinutes(2);
            String cronExp = String.format(
                '{0} {1} {2} {3} {4} ? {5}',
                new List<String>{
                    String.valueOf(retryAt.second()),
                    String.valueOf(retryAt.minute()),
                    String.valueOf(retryAt.hour()),
                    String.valueOf(retryAt.day()),
                    String.valueOf(retryAt.month()),
                    String.valueOf(retryAt.year())
                });
            System.schedule(
                'SwoogoP2Retry-' + Datetime.now().getTime(),
                cronExp,
                new SwoogoSessionSyncContinuation(
                    eventIds, isFirstRun, syncSince, batchStartTime));
            return;
        }

        Database.executeBatch(
            new SwoogoSessionSyncBatch(
                eventIds, isFirstRun, syncSince, batchStartTime),
            1);
    }
}