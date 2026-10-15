public class CertificationExpiryScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {

        Database.executeBatch(
            new CertificationExpiryBatch(),
            200
        );
    }
}