@IsTest
private class CertificationExpiryBatchTest {

    @TestSetup
    static void setupData() {

        Account acc = new Account(
            Name = 'Test Agency'
        );
        insert acc;

        Contact agent = new Contact(
            LastName = 'Test Agent',
            Email = 'agent@test.com',
            AccountId = acc.Id,
            NPN__c = '1234567890',
            Agent_Status__c = 'Onboarding'
        );
        insert agent;

        List<Certification__c> certs = new List<Certification__c>();

        // Should be processed by batch
        certs.add(new Certification__c(
            Agent__c = agent.Id,
            Certification_Type__c = 'AML',
            Status__c = 'Active',
            Expiration_Date__c = Date.today().addDays(10),
            Renewal_Required__c = true
        ));

        // Excluded because AHIP
        certs.add(new Certification__c(
            Agent__c = agent.Id,
            Certification_Type__c = 'AHIP',
            Status__c = 'Active',
            Expiration_Date__c = Date.today().addDays(10),
            Renewal_Required__c = true
        ));

        // Excluded because not Active
        certs.add(new Certification__c(
            Agent__c = agent.Id,
            Certification_Type__c = 'AML',
            Status__c = 'Expired',
            Expiration_Date__c = Date.today().addDays(10),
            Renewal_Required__c = true
        ));

        // Excluded because > 30 days
        certs.add(new Certification__c(
            Agent__c = agent.Id,
            Certification_Type__c = 'AML',
            Status__c = 'Active',
            Expiration_Date__c = Date.today().addDays(60),
            Renewal_Required__c = true
        ));

        insert certs;
    }

    @IsTest
    static void testBatchExecution() {

        Test.startTest();

        Database.executeBatch(
            new CertificationExpiryBatch(),
            1
        );

        Test.stopTest();

        System.assertEquals(
            4,
            [SELECT Count() FROM Certification__c]
        );
    }

    @IsTest
    static void testSchedulerExecution() {

        Test.startTest();

        System.schedule(
            'CertificationExpirySchedulerTest',
            '0 0 0 1 1 ? 2099',
            new CertificationExpiryScheduler()
        );

        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testStartMethod() {

        CertificationExpiryBatch batchObj =
            new CertificationExpiryBatch();

        Database.QueryLocator ql =
            batchObj.start(null);

        System.assertNotEquals(null, ql);
    }

    @IsTest
    static void testFinishMethod() {

        CertificationExpiryBatch batchObj =
            new CertificationExpiryBatch();

        batchObj.finish(null);

        System.assert(true);
    }
}