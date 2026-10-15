trigger AgentDeactivatedEventSubscriber on Agent_Deactivated__e (after insert) {
    AgentDeactivatedHelper.sendToGoAMS(Trigger.new);
}