public class EOInsuranceExpiryScheduler
    implements Schedulable {

    public void execute(
        SchedulableContext sc
    ) {

        Database.executeBatch(
            new EOInsuranceExpiryBatch(),
            200
        );
    }
}