trigger ContactInsuranceTrigger on Contact (before insert, after insert, after update) {
if (Trigger.isAfter) {

        if (Trigger.isInsert) {
            ContactInsuranceHandler.syncInsurance(
                Trigger.new,
                null
            );
        }

        if (Trigger.isUpdate) {
            ContactInsuranceHandler.syncInsurance(
                Trigger.new,
                Trigger.oldMap
            );
        }
    }
}