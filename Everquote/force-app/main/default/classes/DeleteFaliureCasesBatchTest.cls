@isTest
public class DeleteFaliureCasesBatchTest {
    static void testBatchDeletesCases() {
        
        // Create generic test cases
        List<Case> caseList = new List<Case>();
        for (Integer i = 0; i < 5; i++) {
            caseList.add(new Case(
                Subject = 'Test Case ' + i,
                Status = 'New'
            ));
        }
        insert caseList;

        // Verify the cases exist before running the batch
        System.assertEquals(5, [SELECT count() FROM Case WHERE Id IN :caseList]);

        Test.startTest();
        // Passing a query that specifically targets our test records
        String query = 'SELECT Id FROM Case WHERE Subject LIKE \'Test Case%\'';
        DeleteFaliureCasesBatch batch = new DeleteFaliureCasesBatch(query);
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify that the records in our scope were deleted
        List<Case> remainingCases = [SELECT Id FROM Case WHERE Id IN :caseList];
        System.assertEquals(0, remainingCases.size(), 'The batch should have deleted all cases in the scope.');
    }
}