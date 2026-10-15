public with sharing class RenewalScheduleTriggerHandler {

    public void run() {
        if (Trigger.isBefore && Trigger.isInsert) {
            validateOverlap(
                (List<Renewal_Schedule__c>)Trigger.new,
                null
            );
        }

        if (Trigger.isBefore && Trigger.isUpdate) {
            validateOverlap(
                (List<Renewal_Schedule__c>)Trigger.new,
                (Map<Id, Renewal_Schedule__c>)Trigger.oldMap
            );
        }
    }

    private void validateOverlap(
        List<Renewal_Schedule__c> newList,
        Map<Id, Renewal_Schedule__c> oldMap
    ) {

        Set<Id> productIds = new Set<Id>();
        Set<String> scheduleTypes = new Set<String>();

        // Collect filters
        for (Renewal_Schedule__c rs : newList) {

            if (rs.Product_State__c != null) {
                productIds.add(rs.Product_State__c);
            }

            if (String.isNotBlank(rs.Schedule_Type__c)) {
                scheduleTypes.add(rs.Schedule_Type__c);
            }
        }

        if (productIds.isEmpty() || scheduleTypes.isEmpty()) return;

        // Query existing siblings
        List<Renewal_Schedule__c> existing = [
            SELECT Id,
                   Product_State__c,
                   Schedule_Type__c,
                   Year_From__c,
                   Year_To__c
            FROM Renewal_Schedule__c
            WHERE Product_State__c IN :productIds
            AND Schedule_Type__c IN :scheduleTypes
        ];

        System.debug('EXISTING RECORDS → ' + existing);

        for (Renewal_Schedule__c newRec : newList) {

            // Null checks (Decimal fields)
            if (newRec.Year_From__c == null ||
                newRec.Year_To__c == null) {
                continue;
            }

            Decimal newFrom = newRec.Year_From__c;
            Decimal newTo   = newRec.Year_To__c;

            for (Renewal_Schedule__c oldRec : existing) {

                // Skip same record during update
                if (oldMap != null && oldRec.Id == newRec.Id) continue;

                // Match grouping
                if (oldRec.Product_State__c != newRec.Product_State__c) continue;
                if (oldRec.Schedule_Type__c != newRec.Schedule_Type__c) continue;

                if (oldRec.Year_From__c == null ||
                    oldRec.Year_To__c == null) continue;

                Decimal oldFrom = oldRec.Year_From__c;
                Decimal oldTo   = oldRec.Year_To__c;

                // OVERLAP LOGIC
                Boolean isOverlap =
                    (newFrom <= oldTo) &&
                    (newTo >= oldFrom);

                if (isOverlap) {

                    newRec.addError(
                        'Overlapping renewal schedule detected for this Product State and Schedule Type. ' +
                        'Existing range: ' + oldRec.Year_From__c +
                        ' - ' + oldRec.Year_To__c
                    );
                }
            }
        }
    }
}