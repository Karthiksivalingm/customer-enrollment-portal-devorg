public class AppointmentRenewalAlertScheduler
    implements Schedulable {

    public void execute(
        SchedulableContext sc
    ) {

        Database.executeBatch(
            new AppointmentRenewalAlertBatch(),
            200
        );
    }
}