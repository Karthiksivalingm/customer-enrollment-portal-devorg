trigger TouchPointContactUpdateTrigger on Contact (after update, after insert) {
    Process_Switches__c processSwitches = Process_Switches__c.getInstance(UserInfo.getProfileId());

    if (!processSwitches.Contact_Integration_Bypass__c && !UserInfo.getName().equals('Integration User')) {
        Set<Id> conIdSet = new Set<Id>();
        for (Contact con : Trigger.new) {
            conIdSet.add(con.Id);
        }
        if(System.IsBatch() == false && System.isFuture() == false){ 
            if(!Test.isrunningTest()){ //Added by FD team to take care of FD's test classes - 09/25/2025
                TouchPointMakeContactPOSTCallout.makePostCallout(conIdSet);
            }
        }
    }
}