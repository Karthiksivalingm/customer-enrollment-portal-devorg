public with sharing class CaseOrchestratorHandler {

    private static Boolean isRunning = false;

    public static void enqueue(List<Case> newCases,
                               Map<Id, Case> oldMap) {

        if (isRunning) return;

        isRunning = true;

        System.enqueueJob(
            new CaseOrchestratorQueueable(newCases, oldMap)
        );
    }
}