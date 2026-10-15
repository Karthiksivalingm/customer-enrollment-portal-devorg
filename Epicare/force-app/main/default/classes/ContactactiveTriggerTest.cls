@isTest
private class ContactactiveTriggerTest {

    @isTest
    static void testInsertUpdateDeleteUndelete() {

        // Create Account
        Account acc = new Account(
            Name = 'Test Agency'
        );
        insert acc;

        // Insert Contact
        Contact con = new Contact(
            LastName = 'Test Agent',
            AccountId = acc.Id,
            Email = 'agent@test.com',
            NPN__c = '12345678',
            Agent_Status__c = 'Onboarding'
           
        );

        Test.startTest();

        insert con;

        // Update Contact
        con.Phone = '1234567890';
        update con;

        // Delete Contact
        delete con;

        // Undelete Contact
        undelete con;

        Test.stopTest();

        // Verify contact exists after undelete
        Contact result = [
            SELECT Id, AccountId
            FROM Contact
            WHERE Id = :con.Id
        ];

        System.assertEquals(
            acc.Id,
            result.AccountId
        );
    }


    @isTest
    static void testMultipleContacts() {

        Account acc = new Account(
            Name = 'Agency 2'
        );
        insert acc;

        List<Contact> contacts = new List<Contact>();

        for (Integer i = 0; i < 3; i++) {

            contacts.add(
                new Contact(
                    LastName = 'Agent ' + i,
                    AccountId = acc.Id,
                    Email = 'agent' + i + '@test.com',
                    NPN__c = '1234567' + i,
                    Agent_Status__c = 'Onboarding'
                                    )
            );
        }

        Test.startTest();

        insert contacts;

        Test.stopTest();

        System.assertEquals(
            3,
            [
                SELECT Count()
                FROM Contact
                WHERE AccountId = :acc.Id
            ]
        );
    }
}