trigger AgentCreatedEventSubscriber on Agent_Created__e (after insert) {
    AgentCreatedHelper.sendToGoAMS(Trigger.new);
}