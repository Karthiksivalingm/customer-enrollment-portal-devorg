trigger TouchPointAutoGroupUpdateTrigger on Auto_Group__c (after update) {
    Process_Switches__c processSwitches = Process_Switches__c.getInstance(UserInfo.getProfileId());
    
    if (!processSwitches.Auto_Group_Integration_Bypass__c && !UserInfo.getName().equals('Integration User')) {
        Set<Id> agIdSet = new Set<Id>();
        for (Auto_Group__c ag : Trigger.new) {
            agIdSet.add(ag.Id);
        }
        if(System.IsBatch() == false && System.isFuture() == false){ 
            TouchPointMakeAutoGroupPOSTCallout.makePostCallout(agIdSet); 
        }
    }
}