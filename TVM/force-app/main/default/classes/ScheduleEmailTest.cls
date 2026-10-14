@isTest
private class ScheduleEmailTest {
    private static String uniqueSuffix() {        
        return String.valueOf(Math.abs(Crypto.getRandomInteger()));
    }
    private static void setupTestData() {
         String suf = uniqueSuffix();
               User rpm = [SELECT Id, Email FROM User WHERE IsActive = true LIMIT 1];

        System.runAs(rpm) {
        Account acc = new Account(
           Name = 'Test Account'+suf,
            Quickbase_Record_ID__c = suf
        );
        insert acc;
          Opportunity opp = new Opportunity(
            Name = acc.name,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id
        );
        insert opp;
        List<Foundation_Onboarding__c> onboardingRecords = new List<Foundation_Onboarding__c>();
        
        onboardingRecords.add(new Foundation_Onboarding__c(
            
            Account__c = acc.Id,
            Regional_performance_manager__c = rpm.Id,
            Active__c = true,
             Opportunity__c = opp.Id,
            Advertised_Payments_Ready_to_Send__c = Date.today(),
            Advertised_Payments_Approved__c = null,
            Actual_Google_Launch_Date__c = Date.today().addDays(5)
        ));
        
        onboardingRecords.add(new Foundation_Onboarding__c(
            
            Account__c = acc.Id,
            Regional_performance_manager__c = rpm.Id,
            Active__c = true,
             Opportunity__c = opp.Id,
            Advertised_Payments_Ready_to_Send__c = Date.today(),
            Advertised_Payments_Approved__c = Date.today(),
            Actual_Google_Launch_Date__c = Date.today().addDays(5)
        ));
        
        onboardingRecords.add(new Foundation_Onboarding__c(
            
            Account__c = acc.Id,
            Regional_performance_manager__c = rpm.Id,
            Active__c = true,
             Opportunity__c = opp.Id,
            Complete_Kickoff_Call__c = Date.today(),
            Differentiators_Verified_in_DigAd__c = null,
            Actual_Google_Launch_Date__c = Date.today().addDays(5)
        ));
        
        onboardingRecords.add(new Foundation_Onboarding__c(
            
            Account__c = acc.Id,
            Regional_performance_manager__c = rpm.Id,
            Active__c = true,
             Opportunity__c = opp.Id,
            Complete_Kickoff_Call__c = Date.today(),
            Differentiators_Verified_in_DigAd__c = Date.today(),
            Actual_Google_Launch_Date__c = Date.today().addDays(5)
        ));
        
        onboardingRecords.add(new Foundation_Onboarding__c(
            
            Account__c = acc.Id,
            Regional_performance_manager__c = rpm.Id,
            Active__c = true,
             Opportunity__c = opp.Id,
            Complete_Kickoff_Call__c = Date.today(),
            Proposed_Budgets_Sent__c = null,
            Actual_Google_Launch_Date__c = Date.today().addDays(5)
        ));
        
        onboardingRecords.add(new Foundation_Onboarding__c(
            
            Account__c = acc.Id,
            Regional_performance_manager__c = rpm.Id,
            Active__c = true,
             Opportunity__c = opp.Id,
            Complete_Kickoff_Call__c = Date.today(),
            Proposed_Budgets_Sent__c = Date.today(),
            Actual_Google_Launch_Date__c = Date.today().addDays(5)
        ));
        
        onboardingRecords.add(new Foundation_Onboarding__c(
            
            Account__c = acc.Id,
            Regional_performance_manager__c = rpm.Id,
            Active__c = true,
             Opportunity__c = opp.Id,
            Complete_Kickoff_Call__c = Date.today(),
            Geos_Received__c = false,
            Actual_Google_Launch_Date__c = Date.today().addDays(5)
        ));
        
        onboardingRecords.add(new Foundation_Onboarding__c(
            
            Account__c = acc.Id,
            Regional_performance_manager__c = rpm.Id,
            Active__c = true,
             Opportunity__c = opp.Id,
            Complete_Kickoff_Call__c = Date.today(),
            Geos_Received__c = true,
            Geos_Ready_To_Send__c = null,
            Actual_Google_Launch_Date__c = Date.today().addDays(5)
        ));
        
        onboardingRecords.add(new Foundation_Onboarding__c(
            
            Account__c = acc.Id,
            Regional_performance_manager__c = rpm.Id,
            Active__c = true,
             Opportunity__c = opp.Id,
            Complete_Kickoff_Call__c = Date.today(),
            Geos_Received__c = true,
            Geos_Ready_To_Send__c = Date.today(),
            Actual_Google_Launch_Date__c = Date.today().addDays(5)
        ));
        
        onboardingRecords.add(new Foundation_Onboarding__c(
            
            Account__c = acc.Id,
            Regional_performance_manager__c = rpm.Id,
            Active__c = true,
             Opportunity__c = opp.Id,
            Advertised_Payments_Ready_to_Send__c = Date.today(),
            Advertised_Payments_Approved__c = null,
            Actual_Google_Launch_Date__c = null
        ));
        
        insert onboardingRecords;
    }
    }
   @isTest
    static void testBatchExecution() {
        setupTestData();
        Test.startTest();
        ScheduleEmail batch = new ScheduleEmail();
        Database.executeBatch(batch);
        Test.stopTest();
    }
    
    @isTest
    static void testSchedulableExecution() {
        setupTestData();
        Test.startTest();
        ScheduleEmail sched = new ScheduleEmail();
        SchedulableContext sc = null; 
        sched.execute(sc);
        Test.stopTest();
     }
    
    @isTest
    static void testEmailSendingFailure() {
        setupTestData();
        Test.startTest();
        ScheduleEmail batch = new ScheduleEmail();
        Database.executeBatch(batch);
        Test.stopTest();
    }
}