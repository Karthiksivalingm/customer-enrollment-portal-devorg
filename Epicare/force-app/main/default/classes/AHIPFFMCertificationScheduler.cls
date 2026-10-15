public class AHIPFFMCertificationScheduler
    implements Schedulable {

    public void execute(
        SchedulableContext sc
    ) {

        Database.executeBatch(
            new AHIPFFMCertificationBatch(),
            200
        );
    }
}