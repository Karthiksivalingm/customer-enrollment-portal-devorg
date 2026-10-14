global with sharing class CaseSLAScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {

        Database.executeBatch(new CaseSLARecalculationBatch(),200);
    }
}