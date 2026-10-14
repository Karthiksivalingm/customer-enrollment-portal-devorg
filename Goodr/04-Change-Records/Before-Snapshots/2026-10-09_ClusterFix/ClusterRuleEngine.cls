public with sharing class ClusterRuleEngine {

    public static void evaluate(
        String objectName,
        List<SObject> records,
        Map<Id, SObject> oldMap
    ) {
        if (records.isEmpty()) return;
        if (objectName == 'Contact') return;

        List<Sales_Channel_Cluster__mdt> rules = [
            SELECT ObjectAPIName__c,
                   Rule_Condition__c,
                   Cluster_Value__c
            FROM Sales_Channel_Cluster__mdt
            WHERE ObjectAPIName__c = :objectName
        ];

        for (SObject record : records) {

            // On update: skip rule engine entirely if Sales Channel did not change.
            // This means any manual Cluster change (to any value) is preserved,
            // and non-cluster saves (owner change etc.) never touch Cluster__c.
            if (oldMap != null) {
                SObject oldRecord = oldMap.get(record.Id);
                if (oldRecord != null) {
                    String newSC = (String) record.get('Sales_Channel__c');
                    String oldSC = (String) oldRecord.get('Sales_Channel__c');
                    if (newSC == oldSC) continue;
                }
            }

            // Insert, or Sales Channel changed — evaluate rules
            String matchedCluster = null;
            for (Sales_Channel_Cluster__mdt rule : rules) {
                if (evaluateCondition(record, rule.Rule_Condition__c)) {
                    matchedCluster = rule.Cluster_Value__c;
                    break;
                }
            }

            // Never write null to a restricted picklist
            if (matchedCluster == null) continue;

            try {
                record.put('Cluster__c', matchedCluster);
            } catch (SObjectException e) {
                // Formula field or not writable — skip silently
            }
        }
    }

    private static Boolean evaluateCondition(SObject record, String condition) {
        if (String.isBlank(condition)) return false;
        List<String> parts = condition.split('&&');
        for (String rawPart : parts) {
            String part = rawPart.trim();
            String operator;
            if      (part.contains('>=')) operator = '>=';
            else if (part.contains('<=')) operator = '<=';
            else if (part.contains('!=')) operator = '!=';
            else if (part.contains('>'))  operator = '>';
            else if (part.contains('<'))  operator = '<';
            else if (part.contains('='))  operator = '=';
            else return false;
            List<String> tokens = part.split(operator);
            if (tokens.size() != 2) return false;
            String fieldName = tokens[0].trim();
            String expected  = tokens[1].trim().replace('\'', '');
            Object fieldValue;
            try {
                fieldValue = record.get(fieldName);
            } catch (SObjectException e) {
                return false;
            }
            if (fieldValue == null) return false;
            String actual = String.valueOf(fieldValue);
            if (operator == '='  && actual != expected) return false;
            if (operator == '!=' && actual == expected) return false;
        }
        return true;
    }
}