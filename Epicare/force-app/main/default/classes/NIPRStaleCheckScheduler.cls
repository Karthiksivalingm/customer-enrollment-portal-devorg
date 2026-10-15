public class NIPRStaleCheckScheduler
    implements Schedulable {

    public void execute(
        SchedulableContext sc
    ) {

        Database.executeBatch(
            new NIPRStaleCheckBatch(),
            500
        );
    }
}