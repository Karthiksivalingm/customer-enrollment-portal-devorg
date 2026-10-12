trigger ContactClusterTrigger on Contact (after insert) {

    System.enqueueJob(
        new ContactTeamReassignQueueable(
            Trigger.newMap.keySet()
        )
    );

}