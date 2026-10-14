trigger ContactTrigger on Contact (after insert, after update, after delete, after undelete) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) ContactRoleAccountHandler.syncContacts(Trigger.new, null, false);
        if (Trigger.isUpdate) ContactRoleAccountHandler.syncContacts(Trigger.new, Trigger.old, false);
        if (Trigger.isDelete) ContactRoleAccountHandler.syncContacts(null, Trigger.old, true);
        if (Trigger.isUndelete) ContactRoleAccountHandler.syncContacts(Trigger.new, null, false);
    }
}