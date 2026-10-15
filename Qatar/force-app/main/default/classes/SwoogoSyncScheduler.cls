public with sharing class SwoogoSyncScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        // Skip if EITHER Pass 1 or Pass 2 is already running to avoid
        // overlapping batch jobs. Previously only Pass 1 was checked —
        // if Pass 2 (SwoogoSessionSyncBatch) was still finishing up from
        // the prior tick (which can take 1-2+ minutes for 30+ events),
        // the next scheduled tick would see Pass 1 idle and start a
        // brand new run, chaining a second concurrent Pass 2. Two Pass 2
        // jobs writing to the same Sub_Event__c / Guest_List__c /
        // Session_Attendance__c records at once causes row-lock
        // contention and silent partial failures that look exactly like
        // "the scheduler isn't syncing sessions."
        List<AsyncApexJob> running = [
            SELECT Id, ApexClass.Name, Status
            FROM AsyncApexJob
            WHERE ApexClass.Name IN ('SwoogoSyncBatch', 'SwoogoSessionSyncBatch')
              AND Status IN ('Queued','Processing','Holding','Preparing')
            LIMIT 1
        ];
        if (!running.isEmpty()) {
            System.debug('Swoogo sync already running ('
                + running[0].ApexClass.Name + ', status=' + running[0].Status
                + ') — skipping this schedule tick');
            return;
        }

        // A Pass 2 chunk can be "in flight" between chunks without any
        // AsyncApexJob existing at all — the gap between one chunk
        // finishing and the next one starting is implemented as a
        // one-time System.schedule() (see SwoogoSessionSyncChunkScheduler),
        // which only shows up as a CronTrigger row, not an AsyncApexJob,
        // until it actually fires and enters the batch queue. Without this
        // check, a 15-min tick landing in that gap would see "nothing
        // running" and kick off a brand-new Pass 1 concurrently with the
        // pending chunk — the exact overlap this guard exists to prevent.
        //
        // IMPORTANT: Salesforce never actually deletes CronTrigger rows for
        // completed one-time jobs — it just flips State to 'DELETED' and
        // leaves the row in place permanently. Without the "State !=
        // 'DELETED'" filter below, this query matches ANY SwoogoP2Chunk
        // job that has EVER fired, forever — which would make this guard
        // permanently true after the very first Pass 2 run ever completes,
        // silently blocking every future scheduled tick from ever calling
        // SwoogoSyncBatch.run() again.
        List<CronTrigger> pendingChunks = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE 'SwoogoP2Chunk%'
              AND State != 'DELETED'
            LIMIT 1
        ];
        if (!pendingChunks.isEmpty()) {
            System.debug('Swoogo Pass 2 chunk pending ('
                + pendingChunks[0].CronJobDetail.Name
                + ') — skipping this schedule tick');
            return;
        }

        System.debug('SwoogoSyncScheduler: starting batch run');
        SwoogoSyncBatch.run();
    }

    // ── Schedule helpers (run from Anonymous Apex) ────────────

    // Schedule every 15 minutes
    // Usage: SwoogoSyncScheduler.scheduleAll();
    public static void scheduleAll() {
        String jobName = 'SwoogoSync';
        // Abort any existing jobs with this name prefix first
        for (CronTrigger ct : [
            SELECT Id FROM CronTrigger
            WHERE CronJobDetail.Name LIKE :jobName + '%'
        ]) System.abortJob(ct.Id);

        SwoogoSyncScheduler s = new SwoogoSyncScheduler();
        // 4 jobs staggered 15 minutes apart
        System.schedule(jobName + '_00', '0 0  * * * ?', s);
        System.schedule(jobName + '_15', '0 15 * * * ?', s);
        System.schedule(jobName + '_30', '0 30 * * * ?', s);
        System.schedule(jobName + '_45', '0 45 * * * ?', s);
        System.debug('Scheduled 4 SwoogoSync jobs (every 15 min)');
    }

    // Abort all scheduled jobs
    public static void abortAll() {
        for (CronTrigger ct : [
            SELECT Id FROM CronTrigger
            WHERE CronJobDetail.Name LIKE 'SwoogoSync%'
        ]) System.abortJob(ct.Id);
        System.debug('All SwoogoSync scheduled jobs aborted');
    }
}