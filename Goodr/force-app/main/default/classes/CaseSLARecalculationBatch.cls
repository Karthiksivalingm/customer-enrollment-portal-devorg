global with sharing class CaseSLARecalculationBatch
implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator([
            SELECT Id,
                   Priority,
                   Email_To_Case_Address__c,
                   SLA_Due_Date__c,
                   Next_SLA_Due_Date__c,
                   First_Response_Date__c,
                   Next_Reply_Due_Date__c,
                   SLA_Paused__c,
                   IsClosed
            FROM Case
            WHERE IsClosed = FALSE
            AND (SLA_Due_Date__c != NULL
                 OR Next_SLA_Due_Date__c != NULL)
        ]);
    }

    global void execute(Database.BatchableContext bc,
                        List<Case> scope) {

        Map<String, SLA_Configuration__mdt> slaMap =
            new Map<String, SLA_Configuration__mdt>();

        for (SLA_Configuration__mdt mdt : [
            SELECT Priority__c,
                   Email_To_Case_Address__c,
                   Business_Hours_Name__c
            FROM SLA_Configuration__mdt
        ]) {
            String key =
                mdt.Priority__c + '-' +
                mdt.Email_To_Case_Address__c;

            slaMap.put(key, mdt);
        }

        Set<String> bhNames = new Set<String>();

        for (Case c : scope) {

            if (c.SLA_Paused__c == true) continue;

            String key =
                c.Priority + '-' +
                c.Email_To_Case_Address__c;

            if (slaMap.containsKey(key)) {
                bhNames.add(
                    slaMap.get(key).Business_Hours_Name__c
                );
            }
        }

        Map<String, BusinessHours> bhMap =
            new Map<String, BusinessHours>();

        if (!bhNames.isEmpty()) {
            for (BusinessHours bh : [
                SELECT Id, Name
                FROM BusinessHours
                WHERE Name IN :bhNames
            ]) {
                bhMap.put(bh.Name, bh);
            }
        }

        List<Case> updates = new List<Case>();

        for (Case c : scope) {

            if (c.SLA_Paused__c == true) continue;

            String key =
                c.Priority + '-' +
                c.Email_To_Case_Address__c;

            if (!slaMap.containsKey(key)) continue;

            String bhName =
                slaMap.get(key).Business_Hours_Name__c;

            if (!bhMap.containsKey(bhName)) continue;

            Id bhId = bhMap.get(bhName).Id;

            Case updateCase = new Case(Id = c.Id);

            /*
             ----------------------------------------
             FIRST SLA REMAINING (existing logic)
             ----------------------------------------
            */

            if (c.SLA_Due_Date__c != null &&
                c.First_Response_Date__c == null) {

                Long remainingMillis =
                    BusinessHours.diff(
                        bhId,
                        System.now(),
                        c.SLA_Due_Date__c
                    );

                if (remainingMillis != null) {

                    Decimal remainingHours =
                        remainingMillis / (1000.0 * 60 * 60);

                    remainingHours = Math.max(0, remainingHours);

                    Boolean isBreached =
                        remainingMillis <= 0;

                    updateCase.Remaining_Hours__c =
                        remainingHours;

                    updateCase.SLA_Status__c =
                        isBreached
                        ? 'Breached'
                        : 'Within SLA';

                    updateCase.SLA_Breached__c =
                        isBreached;
                }
            }
            else {
                // First SLA completed
                updateCase.Remaining_Hours__c = 0;
            }

            /*
             ----------------------------------------
             NEXT SLA REMAINING (NEW LOGIC)
             ----------------------------------------
            */

            if (c.First_Response_Date__c != null &&
                c.Next_SLA_Due_Date__c != null &&
                c.Next_Reply_Due_Date__c == null) {

                Long nextRemainingMillis =
                    BusinessHours.diff(
                        bhId,
                        System.now(),
                        c.Next_SLA_Due_Date__c
                    );

                if (nextRemainingMillis != null) {

                    Decimal nextRemainingHours =
                        nextRemainingMillis / (1000.0 * 60 * 60);

                    nextRemainingHours =
                        Math.max(0, nextRemainingHours);

                    updateCase.Next_Reply_Remaining_Hours__c =
                        nextRemainingHours;
                }
            }
            else {
                // Second reply sent OR next SLA not started
                updateCase.Next_Reply_Remaining_Hours__c = 0;
            }

            updates.add(updateCase);
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }

    global void finish(Database.BatchableContext bc) {}
}