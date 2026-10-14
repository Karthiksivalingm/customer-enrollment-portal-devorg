@isTest
public class SLARemainingTimeSchedule_Test {
    
    @isTest
    static void testScheduleExecution() {
        
        Test.startTest();
        SLARemainingTimeSendEmailBatchSchedule scheduleJob = new SLARemainingTimeSendEmailBatchSchedule();
        String sch = '0 0 23 * * ?';
        
        System.schedule('Test SLA Batch Schedule', sch, scheduleJob);
        Test.stopTest();
    }
}