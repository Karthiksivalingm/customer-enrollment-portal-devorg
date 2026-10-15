trigger OnboardingChecklistTrigger on Onboarding_Checklist__c (
    after insert,
    after update,
    after delete,
    after undelete
) {
    OnboardingChecklistTriggerHandler.updateContactChecklistStatus(
        Trigger.isDelete ? Trigger.old : Trigger.new
    );
}