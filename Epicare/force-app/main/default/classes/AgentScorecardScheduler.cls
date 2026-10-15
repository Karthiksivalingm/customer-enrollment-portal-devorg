public class AgentScorecardScheduler
    implements Schedulable {

    public void execute(
        SchedulableContext sc
    ) {

        Database.executeBatch(
            new AgentScorecardBatch(),
            100
        );
    }
}