@isTest
public class CaseActionControllerTest {

    private static Case createTestCase(String status) {
        Case c = new Case(
            Subject = 'Test Case',
            Status = status,
            Origin = 'Phone'
        );
        insert c;
        return c;
    }

    @isTest
    static void testResolveCaseSuccess() {
        Case c = createTestCase('New');

        Test.startTest();
        CaseActionController.resolveCase(c.Id);
        Test.stopTest();

        Case updatedCase = [SELECT Status FROM Case WHERE Id = :c.Id];
        System.assertEquals('Resolved', updatedCase.Status, 'Case should be marked as Resolved');
    }

    @isTest
    static void testChangeStatusSuccess() {
        Case c = createTestCase('New');

        Test.startTest();
        CaseActionController.changeStatus(c.Id, 'Working');
        Test.stopTest();

        Case updatedCase = [SELECT Status FROM Case WHERE Id = :c.Id];
        System.assertEquals('Working', updatedCase.Status, 'Case status should be updated');
    }

    @isTest
    static void testGetCaseStatusesExcludingResolved() {
        Test.startTest();
        List<String> statuses = CaseActionController.getCaseStatusesExcludingResolved();
        Test.stopTest();

        System.assertNotEquals(0, statuses.size(), 'Statuses should not be empty');
        System.assert(!statuses.contains('Resolved'), 'List should not contain Resolved status');
    }
}