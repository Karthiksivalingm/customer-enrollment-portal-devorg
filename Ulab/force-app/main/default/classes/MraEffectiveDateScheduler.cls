public class MraEffectiveDateScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new MraEffectiveDateBatch(), 200);
    }
}