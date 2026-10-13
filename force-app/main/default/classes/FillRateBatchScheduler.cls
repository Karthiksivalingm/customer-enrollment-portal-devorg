global class FillRateBatchScheduler implements Schedulable {

    global void execute(SchedulableContext SC) {
        Database.executeBatch(new UpdateFillRateBatch(), 200);
    }
}