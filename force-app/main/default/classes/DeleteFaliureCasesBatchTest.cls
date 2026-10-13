/*
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
*/

/**********************************
Class Name    : DeleteFaliureCasesBatchTest
Description     : Test coverage for DeleteFaliureCasesBatch.
VERSION          DATE                   AUTHOR                DETAIL
---------------------------------------------------------------------------------------------------------
1.1              (bugfix)              testBatchDeletesCases() was missing the @isTest annotation on the
                                         METHOD itself (only the class had @isTest). Without it, the test
                                         runner never executes this method at all - it contributes zero
                                         coverage despite looking complete. Fixed by adding @isTest to the
                                         method.
                                        Also added a second test covering the error-handling fix in
                                         DeleteFaliureCasesBatch 1.1 - since Database.delete's all-or-none
                                         failure now logs instead of throwing, this confirms the batch job
                                         completes (rather than aborting) even when the query scope includes
                                         a record that cannot be deleted (a Case with a related, undeletable
                                         child record via a lookup that blocks deletion is hard to guarantee
                                         generically across orgs, so this test instead verifies the simpler,
                                         universally-true behavior: the batch completes successfully and
                                         does not throw for the caller when executeBatch() is invoked).
1.2              (bugfix)              testBatchDeletesCases() failed on `insert caseList` with
                                         CANNOT_EXECUTE_FLOW_TRIGGER / INVALID_CROSS_REFERENCE_KEY. The
                                         active flow "Case: Update Case Owner to Account Support Rep_1"
                                         fires on every Case create/update whose OwnerId isn't one of two
                                         specific queue Ids, and unconditionally sets OwnerId to
                                         Account.Support_Rep__c. These test Cases have no Account, so the
                                         flow tried to blank the Owner, which Salesforce rejects. Fixed by
                                         setting OwnerId to a queue already excluded by the flow's entry
                                         criteria before insert - the same workaround already used in
                                         TestCaseFirstActivity.addNewTaskAndEventToCase().
1.3              (test coverage)        Added testBatchLogsAndContinues_whenDeleteThrows(), which uses
                                         ThrowingDeleteFaliureCasesBatch to force performDelete() to throw a
                                         DmlException, exercising the catch(DmlException) branch in
                                         execute() that was previously uncovered. Requires
                                         DeleteFaliureCasesBatch 1.2's `virtual` class and `performDelete`
                                         seam.
1.4              (bugfix)              testBatchLogsAndContinues_whenDeleteThrows() failed with
                                         System.UnexpectedException: Error processing messages at
                                         Test.stopTest(), with zero SOQL/DML in the async job and no
                                         start()/execute() entries in the debug log - the batch dispatcher
                                         cannot resolve a Database.Batchable implementation nested inside an
                                         @isTest class (even public). Fixed by moving
                                         ThrowingDeleteFaliureCasesBatch out to its own top-level
                                         ThrowingDeleteFaliureCasesBatch.cls.
***********************************/
@isTest
public class DeleteFaliureCasesBatchTest {

    @isTest
    static void testBatchDeletesCases() {
        // Owner is set to a queue excluded by the "Update Case Owner to Account Support Rep" flow's
        // entry criteria, since these Cases have no Account and the flow would otherwise try to set a blank Owner.
        Group excludedQueue = [SELECT Id FROM Group WHERE DeveloperName = 'nyk_dawn_Opp_Case' AND Type = 'Queue' LIMIT 1];

        // Create generic test cases
        List<Case> caseList = new List<Case>();
        for (Integer i = 0; i < 5; i++) {
            caseList.add(new Case(
                Subject = 'Test Case ' + i,
                Status = 'New',
                OwnerId = excludedQueue.Id
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

    @isTest
    static void testBatchCompletesCleanly_withEmptyQueryScope() {
        // A query that matches nothing exercises the scope.isEmpty() early-return path and confirms
        // executeBatch() completes without throwing for the caller.
        String query = 'SELECT Id FROM Case WHERE Subject = \'No Such Subject Exists\'';

        Test.startTest();
        DeleteFaliureCasesBatch batch = new DeleteFaliureCasesBatch(query);
        Id jobId = Database.executeBatch(batch);
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'executeBatch should return a valid Job Id even for an empty query scope.');
    }

    @isTest
    static void testBatchLogsAndContinues_whenDeleteThrows() {
        // Owner is set to a queue excluded by the "Update Case Owner to Account Support Rep" flow's
        // entry criteria, since this Case has no Account and the flow would otherwise try to set a blank Owner.
        Group excludedQueue = [SELECT Id FROM Group WHERE DeveloperName = 'nyk_dawn_Opp_Case' AND Type = 'Queue' LIMIT 1];
        Case testCase = new Case(
            Subject = 'Test Case Delete Failure',
            Status = 'New',
            OwnerId = excludedQueue.Id
        );
        insert testCase;

        String query = 'SELECT Id FROM Case WHERE Subject = \'Test Case Delete Failure\'';

        Test.startTest();
        // ThrowingDeleteFaliureCasesBatch (a top-level test-support class) forces performDelete() to
        // throw, since the batch runs in system mode and no permission/sharing setup can make a real
        // Database.delete call fail here.
        DeleteFaliureCasesBatch batch = new ThrowingDeleteFaliureCasesBatch(query);
        Database.executeBatch(batch);
        Test.stopTest();

        // The simulated DmlException should be caught and logged inside execute(), not rethrown, so the
        // Case remains untouched and the batch job completes normally.
        Case remainingCase = [SELECT Id FROM Case WHERE Id = :testCase.Id];
        System.assertNotEquals(null, remainingCase, 'Case should still exist because the simulated delete failure was caught, not fatal.');
    }
}