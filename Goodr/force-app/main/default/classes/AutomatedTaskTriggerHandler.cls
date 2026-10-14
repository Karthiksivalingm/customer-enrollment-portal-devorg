/**
 * AutomatedTaskTriggerHandler
 *
 * Deletes Tasks auto-created by Einstein Activity Capture
 * (CreatedBy = "Automated Process", TaskSubtype = 'Email')
 * immediately after insert.
 *
 * CreatedBy.Name is not available on Trigger.new (it's a lookup field,
 * not populated without a query), so we re-query the just-inserted
 * Task Ids to evaluate that condition, then delete matches.
 */
public with sharing class AutomatedTaskTriggerHandler {

    public static void deleteAutomatedTasks(List<Task> newTasks) {
        Set<Id> candidateIds = new Set<Id>();

        for (Task t : newTasks) {
            if (t.TaskSubtype == 'Email') {
                candidateIds.add(t.Id);
            }
        }

        if (candidateIds.isEmpty()) {
            return;
        }

        List<Task> tasksToDelete = [
            SELECT Id
            FROM Task
            WHERE Id IN :candidateIds
            AND CreatedBy.Name = 'Automated Process'
        ];

        if (tasksToDelete.isEmpty()) {
            return;
        }

        Database.DeleteResult[] results = Database.delete(tasksToDelete, false);

        Integer recordsDeleted = 0;
        for (Database.DeleteResult dr : results) {
            if (dr.isSuccess()) {
                recordsDeleted++;
            } else {
                for (Database.Error err : dr.getErrors()) {
                    System.debug(LoggingLevel.ERROR,
                        'Failed to delete Task ' + dr.getId() + ': ' + err.getMessage());
                }
            }
        }

        System.debug('AutomatedTaskTriggerHandler: deleted ' + recordsDeleted + ' automated task(s).');
    }
}