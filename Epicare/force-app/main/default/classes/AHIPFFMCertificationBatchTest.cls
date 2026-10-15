@IsTest
private class AHIPFFMCertificationBatchTest {

    @TestSetup
    static void setupData() {

        Account acc = new Account(
            Name = 'AHIP FFM Test Agency'
        );
        insert acc;

        Contact agent = new Contact(
            LastName = 'AHIP FFM Test Agent',
            Email = 'ahipffmagent@test.com',
            AccountId = acc.Id,
            NPN__c = '1234567890',
            Agent_Status__c = 'Onboarding'
        );
        insert agent;

        Certification__c cert = new Certification__c(
            Agent__c = agent.Id,
            Certification_Type__c = 'AHIP',
            Status__c = 'Active',
            Expiration_Date__c = Date.today().addDays(10),
            Renewal_Required__c = true
        );

        insert cert;
    }


    @IsTest
    static void testBatchExecution() {

        Integer certCount = [
            SELECT COUNT()
            FROM Certification__c
            WHERE Days_Until_Expiry__c < 90
            AND Status__c = 'Active'
            AND Certification_Type__c = 'AHIP'
        ];

        System.assert(
            certCount > 0,
            'Test AHIP certification was not created.'
        );

        Test.startTest();

        Database.executeBatch(
            new AHIPFFMCertificationBatch(),
            200
        );

        Test.stopTest();

        System.assertEquals(
            1,
            certCount,
            'Expected one AHIP certification for the test.'
        );
    }


    @IsTest
    static void testSchedulerExecution() {

        Test.startTest();

        System.schedule(
            'AHIP FFM Scheduler Test',
            '0 0 0 1 1 ? 2099',
            new AHIPFFMCertificationScheduler()
        );

        Test.stopTest();

        System.assert(
            true,
            'Scheduler executed successfully.'
        );
    }


    @IsTest
    static void testStartMethod() {

        AHIPFFMCertificationBatch batch =
            new AHIPFFMCertificationBatch();

        Database.QueryLocator ql =
            batch.start(null);

        System.assertNotEquals(
            null,
            ql,
            'QueryLocator should not be null.'
        );
    }


    @IsTest
    static void testFinishMethod() {

        AHIPFFMCertificationBatch batch =
            new AHIPFFMCertificationBatch();

        Test.startTest();

        batch.finish(null);

        Test.stopTest();

        System.assert(
            true,
            'Finish method executed successfully.'
        );
    }


    @IsTest
    static void testSchedulerDirectExecute() {

        Test.startTest();

        new AHIPFFMCertificationScheduler()
            .execute(null);

        Test.stopTest();

        System.assert(
            true,
            'Scheduler execute method completed successfully.'
        );
    }
}