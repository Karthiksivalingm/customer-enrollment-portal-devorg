public with sharing class DataRetentionSchedulerJob implements Schedulable {

    public void execute(SchedulableContext sc) {
        List<Data_Retention_Rule__mdt> rules = [
            SELECT DeveloperName
            FROM Data_Retention_Rule__mdt
            WHERE Active__c = true
        ];

        for (Data_Retention_Rule__mdt rule : rules) {
            Database.executeBatch(new DataRetentionEnforcementBatch(rule.DeveloperName), 200);
        }
    }
}