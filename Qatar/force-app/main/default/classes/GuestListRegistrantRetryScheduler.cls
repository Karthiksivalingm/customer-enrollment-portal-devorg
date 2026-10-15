/**
 * GuestListRegistrantRetryScheduler
 *
 * One-time scheduled job that re-runs GuestListRegistrantQueueable for
 * guests that got a 429 (Too Many Requests) from Swoogo on their first
 * attempt — typically because the Approval__c → Approved trigger fired
 * while the 15-min background sync (SwoogoSyncBatch/SwoogoSessionSyncBatch)
 * was also mid-run and using up Swoogo's rate-limit window.
 *
 * Scheduled by GuestListRegistrantQueueable.execute() itself; not intended
 * to be scheduled directly.
 */
public with sharing class GuestListRegistrantRetryScheduler implements Schedulable {
    private Set<Id> guestIds;

    public GuestListRegistrantRetryScheduler(Set<Id> guestIds) {
        this.guestIds = guestIds;
    }

    public void execute(SchedulableContext sc) {
        if (guestIds != null && !guestIds.isEmpty()) {
            System.enqueueJob(new GuestListRegistrantQueueable(guestIds));
        }
    }
}