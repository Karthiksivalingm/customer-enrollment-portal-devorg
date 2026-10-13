/* Trigger fires on update Opportunity
 * 1. Enrichment opp only
 * 2. When opp is Closed Lost/Won
 * 3. Create new opp with the same information
 */
trigger CreateNewOppWhenClose on Opportunity (after update) {
    //List<Opportunity> change_opps = Trigger.new;
    
    //// Loop through change events
    //for (Opportunity change_opp: change_opps){
    //    // Only consider Upsell opp that is closed
    //    if(change_opp.RecordTypeId != '0121a000000VlQPAAO')
    //        continue;
    //    if(change_opp.StageName != 'Closed Won' & change_opp.Stagename != 'Closed Lost')
    //        continue;
        
    //    // Make sure there is no other upsell opp open
    //    List<Opportunity> other_opps = [SELECT Id FROM Opportunity
    //                                   WHERE RecordTypeId = '0121a000000VlQPAAO'
    //                                   AND StageName != 'Closed Won' 
    //                                   AND Stagename != 'Closed Lost'
    //                                   AND AccountId = :change_opp.AccountId];
    //    if(other_opps.size() > 0)
    //        continue;
        
    //    // Create new opp
    //    Opportunity new_opp = new Opportunity();
    //    new_opp.Type = change_opp.Type;
    //    new_opp.Name = change_opp.Name;
    //    new_opp.LeadSource = change_opp.LeadSource;
    //    new_opp.RecordTypeId = change_opp.RecordTypeId;
    //    new_opp.OwnerId = change_opp.OwnerId;
    //    new_opp.AccountId = change_opp.AccountId;
    //    new_opp.Estimated_Lift__c = change_opp.Estimated_Lift__c;
    //    new_opp.Account_in_Extended_Pause__c = change_opp.Account_in_Extended_Pause__c;
    //    new_opp.Trigger_Ranking__c = change_opp.Trigger_Ranking__c;
    //    new_opp.Pro_Dunning_Success_Time__c = change_opp.Pro_Dunning_Success_Time__c;
    //    new_opp.Initial_CC_Failure_Date__c = change_opp.Initial_CC_Failure_Date__c;
        
    //    new_opp.StageName = 'Inactive';
    //    new_opp.CloseDate = Date.today().addDays(14);
    //    new_opp.Notes_from_Last_Opp__c = change_opp.Notes_for_Next_Opp__c;
    //    insert new_opp;
    //}
}