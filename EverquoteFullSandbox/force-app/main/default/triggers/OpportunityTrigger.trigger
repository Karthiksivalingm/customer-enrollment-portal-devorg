/*
** Trigger: OpportunityTrigger
** SObject: Opportunity
** Created by J. Pipkin (OpFocus, Inc) on 
*/

trigger OpportunityTrigger on Opportunity (before insert, before update, before delete, after insert, after update, after delete){
    
    if(Trigger.isUpdate && Trigger.isAfter){
        OpportunityTriggerHandler.createNewOppWhenClose();
    }

    if(Trigger.isBefore && Trigger.isInsert){
        //OpportunityTriggerHandler.enterOnboardingProcess();
        //OpportunityTriggerHandler.assignOnboardingOwner();
    }
}