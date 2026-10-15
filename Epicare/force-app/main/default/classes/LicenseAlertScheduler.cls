public class LicenseAlertScheduler implements Schedulable {
    public void execute(SchedulableContext ctx) {
        Database.executeBatch(new LicenseAlertBatch());
    }
}