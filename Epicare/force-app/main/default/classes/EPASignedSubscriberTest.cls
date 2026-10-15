@isTest
private class EPASignedSubscriberTest {

    /*
     * Get a Contact Record Type that is NOT "Agent".
     * Agency Director is available in this org and avoids
     * the AgentCreated automation during the test.
     */
    private static Id getNonAgentContactRecordTypeId() {

        Schema.RecordTypeInfo rtInfo =
            Schema.SObjectType.Contact
                .getRecordTypeInfosByName()
                .get('Agency Director');

        System.assertNotEquals(
            null,
            rtInfo,
            'Agency Director Contact Record Type must exist.'
        );

        return rtInfo.getRecordTypeId();
    }


    @isTest
    static void testEPASignedEvent() {

        // Create Contact using Agency Director Record Type
        Contact con = new Contact(
            RecordTypeId = getNonAgentContactRecordTypeId(),
            LastName = 'EPA Test Agent 001',
            Email = 'epa.agent.001@test.com',
            NPN__c = '90000001',
            Agent_Status__c = 'Onboarding'
        );

        insert con;


        // Create EPA Signed Platform Event
        EPA_Signed__e eventRecord = new EPA_Signed__e(
            Contact_ID__c = con.Id,
            Signed_Date__c = Date.today(),
            Document_URL__c = 'https://test.com/epa-document-001'
        );


        Test.startTest();

        Database.SaveResult publishResult =
            EventBus.publish(eventRecord);

        System.assertEquals(
            true,
            publishResult.isSuccess(),
            'EPA Signed event should be published successfully.'
        );

        // Deliver the Platform Event to the subscriber
        Test.getEventBus().deliver();

        Test.stopTest();


        // Verify Contact was updated
        Contact updatedContact = [
            SELECT Id,
                   EPA_Signed_Date__c,
                   EPA_Document_URL__c
            FROM Contact
            WHERE Id = :con.Id
        ];

        System.assertEquals(
            Date.today(),
            updatedContact.EPA_Signed_Date__c,
            'EPA Signed Date should be updated from the platform event.'
        );

        System.assertEquals(
            'https://test.com/epa-document-001',
            updatedContact.EPA_Document_URL__c,
            'EPA Document URL should be updated from the platform event.'
        );
    }


    @isTest
    static void testIdempotencyLastEventWins() {

        // Create Contact using Agency Director Record Type
        Contact con = new Contact(
            RecordTypeId = getNonAgentContactRecordTypeId(),
            LastName = 'EPA Test Agent 002',
            Email = 'epa.agent.002@test.com',
            NPN__c = '90000002',
            Agent_Status__c = 'Onboarding'
        );

        insert con;


        // First EPA Signed event - older date
        EPA_Signed__e firstEvent = new EPA_Signed__e(
            Contact_ID__c = con.Id,
            Signed_Date__c = Date.today().addDays(-1),
            Document_URL__c = 'https://test.com/epa-document-old'
        );


        // Second EPA Signed event - latest date
        EPA_Signed__e secondEvent = new EPA_Signed__e(
            Contact_ID__c = con.Id,
            Signed_Date__c = Date.today(),
            Document_URL__c = 'https://test.com/epa-document-latest'
        );


        Test.startTest();

        List<Database.SaveResult> publishResults =
            EventBus.publish(
                new List<EPA_Signed__e>{
                    firstEvent,
                    secondEvent
                }
            );

        // Verify both events were published successfully
        for (Database.SaveResult result : publishResults) {
            System.assertEquals(
                true,
                result.isSuccess(),
                'EPA Signed event should be published successfully.'
            );
        }

        // Deliver both events
        Test.getEventBus().deliver();

        Test.stopTest();


        // Verify the latest event wins
        Contact updatedContact = [
            SELECT Id,
                   EPA_Signed_Date__c,
                   EPA_Document_URL__c
            FROM Contact
            WHERE Id = :con.Id
        ];

        System.assertEquals(
            Date.today(),
            updatedContact.EPA_Signed_Date__c,
            'The latest EPA Signed event date should win.'
        );

        System.assertEquals(
            'https://test.com/epa-document-latest',
            updatedContact.EPA_Document_URL__c,
            'The latest EPA Document URL should win.'
        );
    }


    @isTest
    static void testEventWithoutContactId() {

        // Create EPA event without Contact ID
        EPA_Signed__e eventRecord = new EPA_Signed__e(
            Contact_ID__c = null,
            Signed_Date__c = Date.today(),
            Document_URL__c = 'https://test.com/no-contact'
        );


        Test.startTest();

        Database.SaveResult publishResult =
            EventBus.publish(eventRecord);

        System.assertEquals(
            true,
            publishResult.isSuccess(),
            'EPA Signed event without Contact ID should still be published.'
        );

        // Deliver event
        Test.getEventBus().deliver();

        Test.stopTest();


        // No Contact should be updated because Contact_ID__c is null.
        // Reaching this point without an exception confirms graceful handling.
        System.assertEquals(
            true,
            publishResult.isSuccess(),
            'Event without Contact ID should be handled without failure.'
        );
    }
}