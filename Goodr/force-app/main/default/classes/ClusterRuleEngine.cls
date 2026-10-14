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

            // On update: skip rule engine entirely if neither Sales Channel nor Sector changed.
            // This means any manual Cluster change (to any value) is preserved,
            // and non-cluster saves (owner change etc.) never touch Cluster__c.
            // CHANGED: Sector change also re-evaluates (rules now depend on Sector values,
            // e.g. Specialty + Self Service -> Cluster 6, Specialty + Planned -> Cluster 5).
            if (oldMap != null) {
                SObject oldRecord = oldMap.get(record.Id);
                if (oldRecord != null) {
                    String newSC = (String) record.get('Sales_Channel__c');
                    String oldSC = (String) oldRecord.get('Sales_Channel__c');
                    Object newSector = safeGet(record, 'Sector__c');
                    Object oldSector = safeGet(oldRecord, 'Sector__c');
                    if (newSC == oldSC && newSector == oldSector) continue;
                }
            }

            // Insert, or Sales Channel / Sector changed — evaluate rules
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

    // Returns null when the field is not available on the record (e.g. not queried)
    private static Object safeGet(SObject record, String fieldName) {
        try {
            return record.get(fieldName);
        } catch (SObjectException e) {
            return null;
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