public class ShopifySalesSyncScheduler implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new ShopifySalesSyncBatch(), 10);
    }
}