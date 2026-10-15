trigger RenewalScheduleTrigger on Renewal_Schedule__c (before insert, before update) {

    RenewalScheduleTriggerHandler handler = new RenewalScheduleTriggerHandler();
    handler.run();

}