/**
 * SwoogoSessionSyncChunkScheduler
 *
 * One-time scheduled job that fires the next chunk of
 * SwoogoSessionSyncBatch after a delay (normal chunk progression only —
 * 429s are no longer retried, so there's nothing else this needs to track).
 */
public with sharing class SwoogoSessionSyncChunkScheduler implements Schedulable {

    private List<String> eventIds;
    private Boolean      isFirstRun;
    private Datetime     syncSince;
    private Datetime     batchStartTime;

    public SwoogoSessionSyncChunkScheduler(
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
        Database.executeBatch(
            new SwoogoSessionSyncBatch(
                eventIds, isFirstRun, syncSince, batchStartTime),
            1);
    }
}