@isTest
public class OnboardingStepSubscriberTest {

    /*
     * Use Agency Director Record Type instead of Agent.
     * This avoids Agent-specific automation such as
     * Agent_Created__e / AgentCreatedEventSubscriber.
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


    /*
     * Creates a Contact for testing.
     */
    private static Contact createContact(String uniqueNumber) {

        Contact con = new Contact(
            RecordTypeId = getNonAgentContactRecordTypeId(),
            LastName = 'Onboarding Test Contact ' + uniqueNumber,
            Email = 'onboarding.test.' + uniqueNumber + '@test.com',
            NPN__c = '91000' + uniqueNumber,
            Agent_Status__c = 'Onboarding'
        );

        insert con;

        return con;
    }


    /*
     * Test 1:
     * Email Validated should update both:
     * - Onboarding_Step__c
     * - Onboarding_Started__c
     */
    @isTest
    static void testEmailValidatedEvent() {

        Contact con = createContact('001');

        Test.startTest();

        Onboarding_Step__e evt = new Onboarding_Step__e(
            Contact_ID__c = con.Id,
            New_Step__c = 'Email Validated'
        );

        Database.SaveResult result = EventBus.publish(evt);

        System.assertEquals(
            true,
            result.isSuccess(),
            'Onboarding Step event should be published successfully.'
        );

        Test.getEventBus().deliver();

        Test.stopTest();


        Contact updated = [
            SELECT Id,
                   Onboarding_Step__c,
                   Onboarding_Started__c
            FROM Contact
            WHERE Id = :con.Id
        ];


        System.assertEquals(
            'Email Validated',
            updated.Onboarding_Step__c,
            'Onboarding Step should be updated to Email Validated.'
        );

        System.assertEquals(
            Date.today(),
            updated.Onboarding_Started__c,
            'Onboarding Started date should be set for Email Validated.'
        );
    }


    /*
     * Test 2:
     * A valid step other than Email Validated should
     * update only Onboarding_Step__c.
     */
    @isTest
    static void testValidStepUpdatesOnlyStep() {

        Contact con = createContact('002');

        Test.startTest();

        Onboarding_Step__e evt = new Onboarding_Step__e(
            Contact_ID__c = con.Id,
            New_Step__c = 'EPA Pending'
        );

        Database.SaveResult result = EventBus.publish(evt);

        System.assertEquals(
            true,
            result.isSuccess(),
            'Onboarding Step event should be published successfully.'
        );

        Test.getEventBus().deliver();

        Test.stopTest();


        Contact updated = [
            SELECT Id,
                   Onboarding_Step__c,
                   Onboarding_Started__c
            FROM Contact
            WHERE Id = :con.Id
        ];


        System.assertEquals(
            'EPA Pending',
            updated.Onboarding_Step__c,
            'Onboarding Step should be updated to EPA Pending.'
        );

        System.assertEquals(
            null,
            updated.Onboarding_Started__c,
            'Onboarding Started date should remain null.'
        );
    }


    /*
     * Test 3:
     * An unsupported onboarding step should be ignored.
     */
    @isTest
    static void testInvalidStepIgnored() {

        Contact con = createContact('003');

        Test.startTest();

        Onboarding_Step__e evt = new Onboarding_Step__e(
            Contact_ID__c = con.Id,
            New_Step__c = 'Completed'
        );

        Database.SaveResult result = EventBus.publish(evt);

        System.assertEquals(
            true,
            result.isSuccess(),
            'Invalid-step event should still be published successfully.'
        );

        Test.getEventBus().deliver();

        Test.stopTest();


        Contact updated = [
            SELECT Id,
                   Onboarding_Step__c,
                   Onboarding_Started__c
            FROM Contact
            WHERE Id = :con.Id
        ];


        System.assertEquals(
            null,
            updated.Onboarding_Step__c,
            'Invalid onboarding step should not update the Contact.'
        );

        System.assertEquals(
            null,
            updated.Onboarding_Started__c,
            'Onboarding Started date should remain null.'
        );
    }


    /*
     * Test 4:
     * Event without Contact_ID__c should be ignored.
     */
    @isTest
    static void testNullContactIgnored() {

        Test.startTest();

        Onboarding_Step__e evt = new Onboarding_Step__e(
            Contact_ID__c = null,
            New_Step__c = 'Email Validated'
        );

        Database.SaveResult result = EventBus.publish(evt);

        System.assertEquals(
            true,
            result.isSuccess(),
            'Event without Contact ID should be published successfully.'
        );

        Test.getEventBus().deliver();

        Test.stopTest();


        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Contact
                WHERE Onboarding_Step__c = 'Email Validated'
            ],
            'No Contact should be updated when Contact_ID__c is null.'
        );
    }


    /*
     * Test 5:
     * When multiple valid events are received for the same Contact
     * in the same transaction, the last event should win.
     */
    @isTest
    static void testLastEventWins() {

        Contact con = createContact('004');

        Test.startTest();

        Onboarding_Step__e firstEvent = new Onboarding_Step__e(
            Contact_ID__c = con.Id,
            New_Step__c = 'Email Validated'
        );

        Onboarding_Step__e secondEvent = new Onboarding_Step__e(
            Contact_ID__c = con.Id,
            New_Step__c = 'Checklist Pending'
        );


        List<Database.SaveResult> results =
            EventBus.publish(
                new List<Onboarding_Step__e>{
                    firstEvent,
                    secondEvent
                }
            );


        for (Database.SaveResult result : results) {

            System.assertEquals(
                true,
                result.isSuccess(),
                'Onboarding Step event should be published successfully.'
            );
        }


        Test.getEventBus().deliver();

        Test.stopTest();


        Contact updated = [
            SELECT Id,
                   Onboarding_Step__c,
                   Onboarding_Started__c
            FROM Contact
            WHERE Id = :con.Id
        ];


        System.assertEquals(
            'Checklist Pending',
            updated.Onboarding_Step__c,
            'The last onboarding event should win.'
        );

        System.assertEquals(
            null,
            updated.Onboarding_Started__c,
            'Onboarding Started should not be set because the final event is Checklist Pending.'
        );
    }
}