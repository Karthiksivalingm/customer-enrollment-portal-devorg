@isTest
private class EOInsuranceExpiryBatchTest {

    @isTest
    static void testBatch() {

        // Create Contact
  Contact con = new Contact(
    LastName = 'Test Agent',
    Email = 'agent@test.com',
    NPN__c = '12345678',
    Agent_Status__c = 'Onboarding',
    E_O_Termination_Date__c = Date.today().addDays(30)
);

insert con;

// Change status after creation
con.Agent_Status__c = 'Active';
update con;
        
        Test.startTest();

        Database.executeBatch(
            new EOInsuranceExpiryBatch(),
            1
        );

        Test.stopTest();

        Contact result = [

            SELECT Id,
                   E_O_Termination_Date__c

            FROM Contact

            WHERE Id = :con.Id
        ];

        System.assertEquals(
            Date.today().addDays(30),
            result.E_O_Termination_Date__c
        );
    }


    @isTest
    static void testScheduler() {

        Test.startTest();

        String cronExp =
            '0 0 0 1 1 ? 2099';

        System.schedule(

            'EO Insurance Scheduler Test',

            cronExp,

            new EOInsuranceExpiryScheduler()

        );

        Test.stopTest();

        CronTrigger ct = [

            SELECT Id,
                   CronJobDetail.Name

            FROM CronTrigger

            WHERE CronJobDetail.Name =
                'EO Insurance Scheduler Test'

            LIMIT 1
        ];

        System.assertNotEquals(
            null,
            ct
        );
    }

}