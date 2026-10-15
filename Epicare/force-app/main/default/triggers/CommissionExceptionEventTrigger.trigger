/**
 * CommissionExceptionEventTrigger
 * ------------------------------------------------------------------
 * Subscriber for Commission_Exception_Event__e (Publish Behavior must be
 * set to "Publish Immediately" in the platform event's setup page - this
 * is what makes the event survive even when the transaction that
 * published it later gets rolled back via addError()).
 *
 * This fires in a separate async transaction from the original
 * CommissionRecordTriggerHandler execution, so it's immune to whatever
 * rollback happened there.
 */
trigger CommissionExceptionEventTrigger on Commission_Exception_Event__e (after insert) {

    List<Commission_Exception__c> toInsert = new List<Commission_Exception__c>();

    for (Commission_Exception_Event__e evt : Trigger.new) {
        toInsert.add(new Commission_Exception__c(
            Exception_Type__c  = evt.Exception_Type__c,
            Policy_Number__c   = evt.Policy_Number__c,
            Agent__c           = evt.Agent_Id__c,
            Carrier__c         = evt.Carrier_Id__c,
            Expected_Amount__c = evt.Expected_Amount__c,
            Actual_Amount__c   = evt.Actual_Amount__c,
            Status__c          = 'Open',
            Payload__c         = evt.Payload__c
        ));
    }

    if (!toInsert.isEmpty()) insert toInsert;
}