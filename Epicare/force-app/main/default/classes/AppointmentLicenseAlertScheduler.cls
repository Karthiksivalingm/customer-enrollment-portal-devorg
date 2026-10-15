public class AppointmentLicenseAlertScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(
            new AppointmentLicenseAlertBatch(),
            200
        );
    }
}