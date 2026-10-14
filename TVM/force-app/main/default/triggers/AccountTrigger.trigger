//Trigger from FND

trigger AccountTrigger on Account (before insert, before update) {
   
    List<Account> filteredNewList = new List<Account>();           
    List<Account> filteredUpdateNewList = new List<Account>();       
    Map<Id, Account> filteredOldMap = new Map<Id, Account>();       
    
    if (Trigger.isInsert) {    
        for (Account a : Trigger.new) {
            if (a.Foundation_record__c == true) {
                filteredNewList.add(a);                
            }
        }
    } 
    else if (Trigger.isUpdate) {
        // Build old-state map for qualifying records
        for (Id recId : Trigger.oldMap.keySet()) {
            Account oldA = Trigger.oldMap.get(recId);
            if (oldA != null && oldA.Foundation_record__c == true) {
                filteredOldMap.put(recId, oldA);
            }
        }
        // Build new-state list aligned to the same qualification. Adjust the condition if the requirement is to key off new value instead.
        for (Account a : Trigger.new) {
            Account oldA = Trigger.oldMap.get(a.Id);
            if (oldA != null && oldA.Foundation_record__c == true && a.ShippingPostalCode != oldA.ShippingPostalCode) {
                filteredUpdateNewList.add(a);
            }
        }
    }
    if (Trigger.IsInsert && Trigger.IsBefore){
        if (!filteredNewList.isEmpty()) {
            UpdateDMA1Helper.updateDMABeforeInsert(filteredNewList);
        }
    }
    if (Trigger.IsUpdate && Trigger.IsBefore){        
        if (!filteredUpdateNewList.isEmpty()) {
            UpdateDMA1Helper.updateDMABeforeUpdate(filteredUpdateNewList, filteredOldMap);
        }
    }
    
}