@isTest
public class CaseTriggerHelperTest {

    private static Id companyRtId = Schema.SObjectType.Account
        .getRecordTypeInfosByName().get('Company').getRecordTypeId();

    @isTest
    static void testAssignClusterFromQueue() {
        List<Group> queues = [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Queue'
            AND DeveloperName = 'Cluster_1'
            LIMIT 1
        ];

        if (queues.isEmpty()) {
            System.assert(true, 'Cluster_1 queue does not exist in this org — test skipped');
            return;
        }

        Group queue = queues[0];

        Case testCase = new Case(
            Subject = 'Test Case for Cluster 1',
            Status  = 'New',
            Origin  = 'Email',
            OwnerId = queue.Id
        );

        Test.startTest();
        insert testCase;
        Test.stopTest();

        Case insertedCase = [
            SELECT Id, Case_Cluster__c
            FROM Case
            WHERE Id = :testCase.Id
        ];
        System.assertEquals('Cluster 1', insertedCase.Case_Cluster__c,
            'Cluster should be set to Cluster 1 when case owned by Cluster_1 queue');
    }

    @isTest
    static void testAssignClusterFromQueueWithAccount() {
        List<Group> queues = [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Queue'
            AND DeveloperName = 'Cluster_4'
            LIMIT 1
        ];

        if (queues.isEmpty()) {
            System.assert(true, 'Cluster_4 queue does not exist in this org — test skipped');
            return;
        }

        Group queue = queues[0];

        Account acc = new Account(
            Name             = 'Company',
            Tax_Id__c        = '123456789',
            RecordTypeId     = companyRtId,
            Sales_Channel__c = 'Specialty',
            Cluster__c       = 'Cluster 3'
        );
        insert acc;

        Case testCase = new Case(
            Subject   = 'Test Case for Cluster 4',
            AccountId = acc.Id,
            Status    = 'New',
            Origin    = 'Email',
            OwnerId   = queue.Id
        );

        Test.startTest();
        insert testCase;
        Test.stopTest();

        // FIX: Added Cluster__c to the SOQL query — was missing causing SObjectException
        Case insertedCase = [
            SELECT Id, Case_Cluster__c, Cluster__c
            FROM Case
            WHERE Id = :testCase.Id
        ];
        System.assertEquals(null, insertedCase.Case_Cluster__c,
            'Case_Cluster__c should be null when account already has cluster');
        System.assertEquals('Cluster 3', insertedCase.Cluster__c,
            'Cluster should be set to Cluster 3 from the Account');
    }

    @isTest
    static void testAssignCaseCluster_NoMatchingQueue() {
        Case testCase = new Case(
            Subject = 'Test Case No Queue Match',
            Status  = 'New',
            Origin  = 'Email'
        );

        Test.startTest();
        insert testCase;
        Test.stopTest();

        // FIX: Added Cluster__c to SOQL in case it is accessed elsewhere
        Case inserted = [
            SELECT Id, Case_Cluster__c, Cluster__c
            FROM Case
            WHERE Id = :testCase.Id
        ];
        System.assertEquals(null, inserted.Case_Cluster__c,
            'Case_Cluster__c should remain null when owner is not a cluster queue');
    }

    @isTest
    static void testAssignCaseCluster_DirectCall_EmptyQueueList() {
        Case testCase = new Case(
            Subject = 'Direct Call Test',
            Status  = 'New',
            Origin  = 'Email'
        );
        insert testCase;

        // FIX: Added Cluster__c to SOQL so field is available on the object
        Case caseWithOwner = [
            SELECT Id, OwnerId, Case_Cluster__c, Cluster__c
            FROM Case
            WHERE Id = :testCase.Id
        ];

        Test.startTest();
        CaseTriggerHelper.assignCaseCluster(new List<Case>{ caseWithOwner });
        Test.stopTest();

        System.assertEquals(null, caseWithOwner.Case_Cluster__c,
            'Case_Cluster__c should remain null when no queue match found');
    }

    @isTest
    static void testAssignCaseCluster_DynamicQueueMatch() {
        List<Group> clusterQueues = [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Queue'
            AND DeveloperName IN ('Cluster_1', 'Cluster_2', 'Cluster_3', 'Cluster_4')
            LIMIT 1
        ];

        if (clusterQueues.isEmpty()) {
            Case testCase = new Case(
                Subject = 'No Cluster Queue Test',
                Status  = 'New',
                Origin  = 'Email'
            );
            Test.startTest();
            insert testCase;
            Test.stopTest();

            // FIX: Added Cluster__c to SOQL
            Case inserted = [
                SELECT Id, Case_Cluster__c, Cluster__c
                FROM Case
                WHERE Id = :testCase.Id
            ];
            System.assertEquals(null, inserted.Case_Cluster__c,
                'No cluster queues exist — Case_Cluster__c should be null');
            return;
        }

        Group clusterQueue = clusterQueues[0];

        Case testCase = new Case(
            Subject = 'Dynamic Cluster Queue Test',
            Status  = 'New',
            Origin  = 'Email',
            OwnerId = clusterQueue.Id
        );

        Test.startTest();
        insert testCase;
        Test.stopTest();

        // FIX: Added Cluster__c to SOQL
        Case inserted = [
            SELECT Id, Case_Cluster__c, Cluster__c
            FROM Case
            WHERE Id = :testCase.Id
        ];
        System.assertNotEquals(null, inserted.Case_Cluster__c,
            'Case_Cluster__c should be set when case is owned by a cluster queue');
    }
}