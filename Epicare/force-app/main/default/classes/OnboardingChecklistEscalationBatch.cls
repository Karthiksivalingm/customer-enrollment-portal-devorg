global class OnboardingChecklistEscalationBatch 
    implements Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext bc) {

        // ✅ FIX: Use Date because field is Date type
        Date cutoffDate = System.today().addDays(-1);

        return Database.getQueryLocator([
            SELECT Id, Name, OwnerId
            FROM Onboarding_Checklist__c
            WHERE Status__c = 'Not Started'
            AND EPA_Signed_Date__c != null
            AND EPA_Signed_Date__c <= :cutoffDate
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Onboarding_Checklist__c> scope) {

        Set<Id> recordIds = new Set<Id>();

        for (Onboarding_Checklist__c rec : scope) {
            recordIds.add(rec.Id);
        }

        // 🔒 Step 1: Find existing escalation tasks (prevent duplicates)
        Set<Id> alreadyEscalated = new Set<Id>();

        for (Task t : [
            SELECT WhatId
            FROM Task
            WHERE WhatId IN :recordIds
            AND Subject LIKE 'ESCALATION: ONBOARDING%'
            AND Status != 'Completed'
        ]) {
            alreadyEscalated.add(t.WhatId);
        }

        List<Task> tasksToInsert = new List<Task>();

        // 🔥 Step 2: Create tasks only if not already escalated
        for (Onboarding_Checklist__c rec : scope) {

            if (alreadyEscalated.contains(rec.Id)) {
                continue;
            }

            Task t = new Task();
            t.Subject = 'ESCALATION: ONBOARDING NOT STARTED (24H SLA BREACH)';
            t.WhatId = rec.Id;
            t.OwnerId = rec.OwnerId;
            t.Priority = 'High';
            t.Status = 'Not Started';
            t.ActivityDate = Date.today();
            t.Description = 'Auto-escalated task: EPA Signed Date exceeded SLA and onboarding not started.';

            tasksToInsert.add(t);
        }

        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Onboarding Checklist Escalation Batch Completed Successfully');
    }
}