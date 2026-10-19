global class AssignLeadToCadencesBatchScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        AssignLeadToCadencesBatch b = new AssignLeadToCadencesBatch(null);
        if(!Test.isRunningTest() ){
        	database.executebatch(b, 1);
        }
    }

}