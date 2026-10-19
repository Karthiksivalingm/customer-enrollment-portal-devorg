/* When a call is marked "Spoke to Decision Maker", 
 * change owner of lead or opportunity
 */

trigger ChangeOwnerAfterSpokeDM on Task (after insert, after update) {
    List<Task> change_tasks = Trigger.new;
    for (Task change_task: change_tasks){
        if(change_task.CallDisposition == 'Spoke to Decision Maker') {
            
            // 1. Lead not Lost, and belongs to a queue
            List<Lead> leads = [SELECT Id, Status, OwnerId FROM Lead WHERE Id = :change_task.WhoId];
            if(leads.size() > 0){
                Lead lead = leads[0];
                if(lead.Status != 'Lost' & lead.Status != 'Unqualified' & lead.Status != 'Duplicate' & string.valueOf(lead.OwnerId).startsWith('00G')) {
                    lead.OwnerId = change_task.OwnerId;
                    update lead;
                }
                continue;
            }
            
            // 2. Winback Opportunity, belongs to system owner
            List<Opportunity> opps = [SELECT Id, OwnerId, Type FROM Opportunity WHERE Id = :change_task.WhatId];
            if(opps.size() == 0)
                continue;
            Opportunity opp = opps[0];
            if((opp.OwnerId == '0051a000001UvIRAA0' || opp.OwnerId == '0051a000002RkQgAAK') && opp.Type == 'Winback') {
                opp.OwnerId = change_task.OwnerId;
                update opp;
            }
        }
    }
}