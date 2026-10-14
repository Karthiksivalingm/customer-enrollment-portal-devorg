trigger TouchPointBudgetUpdateTrigger on Monthly_Budget__c (after update, after insert) {
  Process_Switches__c processSwitches = Process_Switches__c.getInstance(UserInfo.getProfileId());
  
  if (!processSwitches.Monthly_Budget_Integration_Bypass__c && !UserInfo.getName().equals('Integration User')) {
    Set<Id> budgetIdSet = new Set<Id>();
    for (Monthly_Budget__c budget : Trigger.new) {
          if(budget.Sent_to_TP__c == null){
            budgetIdSet.add(budget.Id);
          }
    }
    if(System.IsBatch() == false && System.isFuture() == false && budgetIdSet != null){ 
        if(!Test.isrunningTest()){ //Added by FD team to take care of FD's test classes - 09/25/2025
            TouchPointMakeBudgetPOSTCallout.makePostCallout(budgetIdSet);
        }    
    }
    }
}