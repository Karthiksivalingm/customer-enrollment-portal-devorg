trigger ContactactiveTrigger on Contact (after insert, after update, after delete, after undelete) {

    Set<Id> accountIds = new Set<Id>();

    // Insert / Update / Undelete
    if(Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete){
        for(Contact con : Trigger.new){
            if(con.AccountId != null){
                accountIds.add(con.AccountId);
            }
        }
    }

    // Delete
    if(Trigger.isDelete){
        for(Contact con : Trigger.old){
            if(con.AccountId != null){
                accountIds.add(con.AccountId);
            }
        }
    }

    if(!accountIds.isEmpty()){
        ContactactiveTriggerHandler.updateActiveAgentCount(accountIds);
    }
}