trigger ContactEncryptedFieldTrigger on Contact (before insert, before update) {
    for (Contact con : Trigger.new) {
        // Only update if source field has a value
        if (con.SSN__c != null) {
            con.SSN_Number__c = con.SSN__c ;
        }
    }
}