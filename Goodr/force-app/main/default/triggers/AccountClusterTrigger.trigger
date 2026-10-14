trigger AccountClusterTrigger on Account (
    before insert, before update,
    after insert, after update
) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            ClusterRuleEngine.evaluate('Account', Trigger.new, null);
        }
        if (Trigger.isUpdate) {
            ClusterRuleEngine.evaluate('Account', Trigger.new, Trigger.oldMap);
        }
    }
    if (Trigger.isAfter) {
        AccountCascadeHandler.handle(
            Trigger.new,
            Trigger.oldMap
        );
    }
}