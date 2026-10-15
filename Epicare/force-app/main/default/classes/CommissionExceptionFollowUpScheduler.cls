public class CommissionExceptionFollowUpScheduler
    implements Schedulable {

    public void execute(
        SchedulableContext sc
    ) {

        Database.executeBatch(
            new CommissionExceptionFollowUpBatch(),
            200
        );
    }
}