trigger CommissionPaidEventSubscriber on Commission_Paid__e (after insert) {
    CommissionPaidHelper.sendToGoAMS(Trigger.new);
}