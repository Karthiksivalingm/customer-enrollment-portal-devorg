trigger UplinePolicyCreatedEventTrigger on Upline_Policy_Created__e (after insert) {
    UplinePolicyCreatedEventHandler.handleAfterInsert(Trigger.new);
}