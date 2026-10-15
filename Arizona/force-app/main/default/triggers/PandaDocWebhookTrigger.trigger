// NEW: runs as the platform event's running user (set in Setup), not the site guest user
trigger PandaDocWebhookTrigger on PandaDoc_Webhook__e (after insert) {
    List<PandaDocEventProcessor.Job> jobs = new List<PandaDocEventProcessor.Job>();
    for (PandaDoc_Webhook__e e : Trigger.new) {
        PandaDocEventProcessor.Job j = PandaDocEventProcessor.fromEvent(e);
        if (j != null) {
            jobs.add(j);
        }
    }
    // Queueable, because triggers cannot make the PDF download callout
    if (!jobs.isEmpty()) {
        System.enqueueJob(new PandaDocEventProcessor(jobs));
    }
}