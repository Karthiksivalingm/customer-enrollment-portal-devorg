public with sharing class SystemLogExportScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new SystemLogExportBatch('LoginHistory'), 2000);
        Database.executeBatch(new SystemLogExportBatch('SetupAuditTrail'), 2000);
    }
}