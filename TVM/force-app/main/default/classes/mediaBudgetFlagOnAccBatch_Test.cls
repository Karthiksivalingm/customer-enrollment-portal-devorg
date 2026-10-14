@IsTest(seeAllData = false)
public class mediaBudgetFlagOnAccBatch_Test {
    
    public static void createTestData() {
        // Date setup
        DateTime nowDt = DateTime.now();
        String curMonth = nowDt.format('MMM');
        String curYear = String.valueOf(nowDt.format('yyyy'));
        
        DateTime nextDt = nowDt.addMonths(1);
        String nextMonth = nextDt.format('MMM');
        String nextYear = String.valueOf(nextDt.format('yyyy'));
        
        DateTime prevDt = nowDt.addMonths(-1);
        String prevMonth = prevDt.format('MMM');
        String prevYear = String.valueOf(prevDt.format('yyyy'));
        
        // Non-TVM billed account that uses its own Monthly_Budgets__r
        Account nonTvmAcc = new Account(
            Name = 'Non TVM Acc',
            FNDN_Billed_Through_TVM__c = false,
            Active__c = true,
            Type__c = 'Digital Advertising',
            Total_MRR__c = 1000
        );
        insert nonTvmAcc;
        
        // Foundation account (acc1) that TVM accounts reference
        Account foundationAcc = new Account(
            Name = 'Foundation Acc',
            FNDN_Billed_Through_TVM__c = true,
            Active__c = true,
            Type__c = 'Digital Advertising',
            Total_MRR__c = 2000,
            Foundation_Account__c = 'FOUND-001'
        );
        insert foundationAcc;
        
        // TVM billed account that should enter:
        // if (acc.FNDN_Billed_Through_TVM__c == True && acc.Touchpoint_Master_ID__c != null) { for (Account acc1 : accTVMlist) { ... } }
        Account tvmAcc = new Account(
            Name = 'TVM Acc',
            FNDN_Billed_Through_TVM__c = true,
            Active__c = true,
            Type__c = 'Digital Advertising',
            Total_MRR__c = 1500,
            Touchpoint_Master_ID__c = foundationAcc.Foundation_Account__c
        );
        insert tvmAcc;
        
        // Budgets so all three accounts are eligible via start() scope (Accounts with Monthly_Budget__c)
        // Non TVM account budgets: last, current and next month to exercise all 3 branches
        insert new List<Monthly_Budget__c>{
            // Last month
            new Monthly_Budget__c(
                Account__c = nonTvmAcc.Id,
                Budget_Month__c = prevMonth,
                Budget_Year__c = prevYear,
                PPC_Budget_Sales__c = 90,
                PPC_Budget_Service__c = 40,
                PPC_Budget_DISC__c = 20,
                Video_Budget_Sales__c = 60,
                SMA_Budget_Sales__c = 55,
                SMA_Budget_Preowned__c = 35,
                PPC_Budget_VLA_New__c = 25,
                PPC_Budget_VLA_Used__c = 15
                
            ),
                // Current month
                new Monthly_Budget__c(
                    Account__c = nonTvmAcc.Id,
                    Budget_Month__c = curMonth,
                    Budget_Year__c = curYear,
                    PPC_Budget_Sales__c = 100,
                    PPC_Budget_Service__c = 50,
                    PPC_Budget_DISC__c = 25,
                    Video_Budget_Sales__c = 75,
                    SMA_Budget_Sales__c = 60,
                    SMA_Budget_Preowned__c = 40,
                    PPC_Budget_VLA_New__c = 30,
                    PPC_Budget_VLA_Used__c = 20
                    
                ),
                // Next month
                new Monthly_Budget__c(
                    Account__c = nonTvmAcc.Id,
                    Budget_Month__c = nextMonth,
                    Budget_Year__c = nextYear,
                    PPC_Budget_Sales__c = 110,
                    PPC_Budget_Service__c = 55,
                    PPC_Budget_DISC__c = 28,
                    Video_Budget_Sales__c = 80,
                    SMA_Budget_Sales__c = 65,
                    SMA_Budget_Preowned__c = 45,
                    PPC_Budget_VLA_New__c = 33,
                    PPC_Budget_VLA_Used__c = 22
                    
                )
                };
                    
                    // Foundation account budgets (acc1 path used by tvmAcc)
                    insert new List<Monthly_Budget__c>{
                        // Last month
                        new Monthly_Budget__c(
                            Account__c = foundationAcc.Id,
                            Budget_Month__c = prevMonth,
                            Budget_Year__c = prevYear,
                            PPC_Budget_Sales__c = 180,
                            PPC_Budget_Service__c = 70,
                            PPC_Budget_DISC__c = 35,
                            Video_Budget_Sales__c = 85,
                            SMA_Budget_Sales__c = 65,
                            SMA_Budget_Preowned__c = 45,
                            PPC_Budget_VLA_New__c = 32,
                            PPC_Budget_VLA_Used__c = 22                
                        ),
                            // Current month
                            new Monthly_Budget__c(
                                Account__c = foundationAcc.Id,
                                Budget_Month__c = curMonth,
                                Budget_Year__c = curYear,
                                PPC_Budget_Sales__c = 200,
                                PPC_Budget_Service__c = 80,
                                PPC_Budget_DISC__c = 40,
                                Video_Budget_Sales__c = 90,
                                SMA_Budget_Sales__c = 70,
                                SMA_Budget_Preowned__c = 50,
                                PPC_Budget_VLA_New__c = 35,
                                PPC_Budget_VLA_Used__c = 25
                                
                            ),
                            // Next month
                            new Monthly_Budget__c(
                                Account__c = foundationAcc.Id,
                                Budget_Month__c = nextMonth,
                                Budget_Year__c = nextYear,
                                PPC_Budget_Sales__c = 210,
                                PPC_Budget_Service__c = 85,
                                PPC_Budget_DISC__c = 45,
                                Video_Budget_Sales__c = 95,
                                SMA_Budget_Sales__c = 75,
                                SMA_Budget_Preowned__c = 55,
                                PPC_Budget_VLA_New__c = 40,
                                PPC_Budget_VLA_Used__c = 30
                                
                            )
                            };
                                
                                // IMPORTANT: Add at least one Monthly_Budget__c for tvmAcc so it is included in the batch scope
                                insert new Monthly_Budget__c(
                                    Account__c = tvmAcc.Id,
                                    Budget_Month__c = curMonth,
                                    Budget_Year__c = curYear,
                                    PPC_Budget_Sales__c = 10,
                                    PPC_Budget_Service__c = 5,
                                    PPC_Budget_DISC__c = 2,
                                    Video_Budget_Sales__c = 7,
                                    SMA_Budget_Sales__c = 6,
                                    SMA_Budget_Preowned__c = 4,
                                    PPC_Budget_VLA_New__c = 3,
                                    PPC_Budget_VLA_Used__c = 2
                                    
                                );
    }
    
    @IsTest
    static void test_Batch_Covers_TVM_and_NonTVM_Paths() {
        createTestData();
        
        Test.startTest();
        Database.executeBatch(new mediaBudgetFlagOnAccBatch(), 10);
        Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());
        Integer callouts = Limits.getCallouts();
        Test.stopTest();
        
    }
  
    @IsTest
    static void test_Schedulable_Path() {
        createTestData();
        Test.startTest();
        System.schedule('mediaBudgetFlagOnAccBatch_Sched', '0 0 0 1 1 ? 2099', new mediaBudgetFlagOnAccBatch());
        Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());
        Integer callouts = Limits.getCallouts();
        Test.stopTest();
        
    }
}