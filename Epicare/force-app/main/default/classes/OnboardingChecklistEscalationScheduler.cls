global class OnboardingChecklistEscalationScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new OnboardingChecklistEscalationBatch(), 200);
    }
}