public class CommissionExceptionFollowUpBatch
    implements Database.Batchable<SObject> {

    // ─────────────────────────────────────────────
    // GET COMMISSIONS DIRECTOR USER
    // ─────────────────────────────────────────────
    private Id getDirectorUserId() {

        List<User> users = [

            SELECT Id
            FROM User

            WHERE UserRole.Name =
                'Commissions Director'

            AND IsActive = true

            LIMIT 1
        ];

        if (!users.isEmpty()) {

            return users[0].Id;
        }

        return null;
    }

    // ─────────────────────────────────────────────
    // START
    // ─────────────────────────────────────────────
    public Database.QueryLocator start(
        Database.BatchableContext bc
    ) {

        return Database.getQueryLocator([

            SELECT Id,
                   Name,
                   Status__c,
                   Follow_Up_Date__c,
                   Policy_Number__c

            FROM Commission_Exception__c

            WHERE Status__c = 'Open'
            AND Follow_Up_Date__c < TODAY
        ]);
    }

    // ─────────────────────────────────────────────
    // EXECUTE
    // ─────────────────────────────────────────────
    public void execute(
        Database.BatchableContext bc,
        List<Commission_Exception__c> scope
    ) {

        // Get Director User
        Id directorId =
            getDirectorUserId();

        // Stop if no Director found
        if (directorId == null) {

            System.debug(
                'No active Commissions Director found'
            );

            return;
        }

        List<Task> tasks =
            new List<Task>();

        // Prevent duplicate tasks
        Set<Id> exceptionIds =
            new Set<Id>();

        for (
            Commission_Exception__c ex
            : scope
        ) {

            exceptionIds.add(ex.Id);
        }

        Map<Id, Task> existingTasks =
            new Map<Id, Task>();

        for (Task t : [

            SELECT Id,
                   WhatId

            FROM Task

            WHERE WhatId IN :exceptionIds
            AND Subject =
                'Commission Exception Follow-Up'
            AND Status != 'Completed'
        ]) {

            existingTasks.put(
                t.WhatId,
                t
            );
        }

        // Create Tasks
        for (
            Commission_Exception__c ex
            : scope
        ) {

            // Skip existing task
            if (
                existingTasks.containsKey(
                    ex.Id
                )
            ) {
                continue;
            }

            Task t = new Task();

            t.Subject =
                'Commission Exception Follow-Up';

            t.Priority =
                'High';

            t.Status =
                'Not Started';

            t.OwnerId =
                directorId;

            t.WhatId =
                ex.Id;

            t.ActivityDate =
                Date.today();

            t.Description =
                'Commission Exception "' +
                ex.Name +
                '" requires follow-up. ' +
                'Follow-up date has passed.';

            tasks.add(t);

            System.debug(
                'TASK CREATED → ' +
                ex.Name
            );
        }

        // Insert Tasks
        if (!tasks.isEmpty()) {

            insert tasks;

            System.debug(
                'TOTAL TASKS CREATED → ' +
                tasks.size()
            );
        }
        else {

            System.debug(
                'NO FOLLOW-UP TASKS REQUIRED'
            );
        }
    }

    // ─────────────────────────────────────────────
    // FINISH
    // ─────────────────────────────────────────────
    public void finish(
        Database.BatchableContext bc
    ) {

        System.debug(
            'Commission Exception Follow-Up Batch Completed'
        );
    }
}