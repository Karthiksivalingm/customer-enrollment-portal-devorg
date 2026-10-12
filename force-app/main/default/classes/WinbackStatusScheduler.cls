public class WinbackStatusScheduler implements Schedulable {
    
    public void execute(SchedulableContext ctx) {
        System.debug('=== Scheduled Job Started: ' 
                    + DateTime.now() + ' ===');
        
        // Step 1: Add new enrollments to Campaign
        WinbackStatusSync.syncEnrollments();
        
        // Step 2: Update statuses from
        // ActionCadenceStepTracker
        WinbackStatusSync.syncEmailStatus();
        
        System.debug('=== Scheduled Job Completed ===');
    }
}