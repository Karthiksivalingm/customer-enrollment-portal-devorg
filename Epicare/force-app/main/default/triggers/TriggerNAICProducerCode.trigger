trigger TriggerNAICProducerCode on NAICProducerCode__c (After insert,After Delete) {
    if(Trigger.isAfter && Trigger.isInsert){
System.enqueueJob(new NIPRAddTargets(Trigger.new));
    }
    if(Trigger.isAfter && Trigger.isDelete){
System.enqueueJob(new NIPRRemoveTargets(Trigger.old));        
    }
}