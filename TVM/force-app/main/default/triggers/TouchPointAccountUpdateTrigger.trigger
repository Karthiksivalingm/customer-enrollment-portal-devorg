trigger TouchPointAccountUpdateTrigger on Account (after update) {
    Process_Switches__c processSwitches = Process_Switches__c.getInstance(UserInfo.getProfileId());
    
    if (!processSwitches.Account_Integration_Bypass__c && !UserInfo.getName().equals('Integration User')) {
        Set<Id> acctIdSet = new Set<Id>();
        for (Account acct : Trigger.new) {
            acctIdSet.add(acct.Id);
        }
        if(System.IsBatch() == false && System.isFuture() == false){ 
         //if(!Test.isrunningTest()){ //Added by FD team to take care of FD's test classes - 09/25/2025
                TouchPointMakeAccountPOSTCallout.makePostCallout(acctIdSet);
                TouchPointMakeCPPOSTCallout.makePostCallout(acctIdSet);
         //   }            
        }
    }
}