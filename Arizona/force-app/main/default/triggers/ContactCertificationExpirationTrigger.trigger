trigger ContactCertificationExpirationTrigger on Contact (before insert, before update) {

   
    ContactCertificationExpirationHandler.calculateExpirationDates(
        Trigger.new,
        Trigger.isUpdate ? Trigger.oldMap : null
    );
}