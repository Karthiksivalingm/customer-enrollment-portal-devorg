public with sharing class DataRetentionEnforcementBatch implements Database.Batchable<sObject>, Database.Stateful {

    private String ruleDeveloperName;
    private Data_Retention_Rule__mdt rule;
    private Integer recordsDeleted = 0;
    private Boolean hasError = false;
    private String errorDetails = '';

    public DataRetentionEnforcementBatch(String ruleDeveloperName) {
        this.ruleDeveloperName = ruleDeveloperName;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        rule = [
            SELECT MasterLabel, Object_API_Name__c, Date_Field_API_Name__c,
                   Retention_Years__c, Filter_Field_API_Name__c, Filter_Values__c,
                   Action__c, Test_Mode__c
            FROM Data_Retention_Rule__mdt
            WHERE DeveloperName = :ruleDeveloperName
            LIMIT 1
        ];

        Date cutoffDate = Date.today().addYears(-Integer.valueOf(rule.Retention_Years__c));

        String query = 'SELECT Id FROM ' + String.escapeSingleQuotes(rule.Object_API_Name__c) +
                        ' WHERE ' + String.escapeSingleQuotes(rule.Date_Field_API_Name__c) + ' <= :cutoffDate';

        if (String.isNotBlank(rule.Filter_Field_API_Name__c) && String.isNotBlank(rule.Filter_Values__c)) {
            List<String> values = rule.Filter_Values__c.split(',');
            List<String> quoted = new List<String>();
            for (String v : values) {
                quoted.add('\'' + String.escapeSingleQuotes(v.trim()) + '\'');
            }
            query += ' AND ' + String.escapeSingleQuotes(rule.Filter_Field_API_Name__c) +
                      ' IN (' + String.join(quoted, ',') + ')';
        }

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        if (scope.isEmpty()) {
            return;
        }

        if (rule.Test_Mode__c) {
            recordsDeleted += scope.size();
            return;
        }

        List<Database.DeleteResult> results = Database.delete(scope, false);
        for (Database.DeleteResult dr : results) {
            if (dr.isSuccess()) {
                recordsDeleted++;
            } else {
                hasError = true;
                for (Database.Error err : dr.getErrors()) {
                    errorDetails += err.getMessage() + '; ';
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        Data_Retention_Log__c log = new Data_Retention_Log__c(
            Rule_Name__c = rule.MasterLabel,
            Object_API_Name__c = rule.Object_API_Name__c,
            Records_Deleted__c = recordsDeleted,
            Status__c = hasError ? 'Completed with Errors' : 'Success',
            Error_Details__c = errorDetails.length() > 0 ? errorDetails.left(32000) : null,
            Batch_Job_Id__c = bc.getJobId()
        );
        insert log;
    }
}