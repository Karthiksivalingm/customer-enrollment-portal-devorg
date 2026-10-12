/**
 * Batch Apex job that deletes Tasks auto-created by Einstein Activity Capture
 * (CreatedBy = "Automated Process"). Intended to run on a daily schedule.
 *
 * Implements both Batchable and Schedulable so a single class can be:
 *   1) Run on-demand:      Database.executeBatch(new DeleteAutomatedTasksBatch(), 200);
 *   2) Scheduled daily:    System.schedule('Daily Automated Task Cleanup', '0 0 2 * * ?', new DeleteAutomatedTasksBatch());
 */
public class DeleteAutomatedTasksBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful {

    // Only delete tasks older than this many days, as a safety buffer
    // (avoids deleting something still being processed same-day)
    private static final Integer DAYS_OLD_THRESHOLD = 5;

    public Integer recordsDeleted = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime cutoff = DateTime.now().addDays(-DAYS_OLD_THRESHOLD);

        return Database.getQueryLocator([
            SELECT Id, Subject, CreatedDate, CreatedById
            FROM Task
            WHERE CreatedBy.Name = 'Automated Process'
            AND TaskSubtype = 'Email'
            AND CreatedDate <= :cutoff
        ]);
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        List<Task> tasksToDelete = (List<Task>) scope;

        Database.DeleteResult[] results = Database.delete(tasksToDelete, false);

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
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('DeleteAutomatedTasksBatch finished. Records deleted: ' + recordsDeleted);

        // Optional: send yourself an email summary each run
        /*
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { UserInfo.getUserEmail() });
        mail.setSubject('Automated Task Cleanup - Daily Summary');
        mail.setPlainTextBody('Deleted ' + recordsDeleted + ' automated tasks today.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        */
    }

    // Schedulable interface - lets this same class be scheduled directly
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new DeleteAutomatedTasksBatch(), 200);
    }
}