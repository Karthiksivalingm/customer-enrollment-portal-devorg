trigger UplineImportCompleteEventSubscriber on Upline_Policy_Import_Completed__e (after insert) {
    UplineImportCompleteHelper.sendToGoAMS(Trigger.new);
}