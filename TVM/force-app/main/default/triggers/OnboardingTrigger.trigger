trigger OnboardingTrigger on Foundation_Onboarding__c (before insert,before update, after update, after insert) {

    if(Trigger.isUpdate && Trigger.isAfter){ 
        if(OnboardingTriggerHandler.isFirstTime)
        {
            OnboardingTriggerHandler.isFirstTime = false;
            OnboardingTriggerHandler.AfterUpdateOnboardingFieldOfSameAccount(Trigger.old,Trigger.new,Trigger.oldMap,Trigger.newMap);
        }
    }
    
    if (Trigger.isBefore && Trigger.isInsert) {
        OnboardingTriggerHandler.beforeInsert(Trigger.new);
    }
    
    if (Trigger.isAfter && Trigger.isInsert) {
        OnboardingTriggerHandler.AfterInsert(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        OnboardingTriggerHandler.afterUpdate(Trigger.oldMap, Trigger.newMap);
    }
    
    if (Trigger.isBefore && Trigger.isUpdate) {
       // OnboardingTriggerHandler.beforeUpdate(Trigger.new);
    }    
}