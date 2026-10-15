@IsTest
private class CommissionExceptionEventTriggerTest {

    private static Id agencyId;
    private static Id agentId;
    private static Id carrierId;

    @TestSetup
    static void setupData() {

        Account agency = new Account(
            Name = 'Commission Exception Event Test Agency'
        );
        insert agency;

        Contact agent = new Contact(
            LastName = 'Commission Event Test Agent',
            AccountId = agency.Id,
            Email = 'commissioneventagent@test.com',
            NPN__c = '1234567890',
            Agent_Status__c = 'Onboarding',
            Insurance_Types__c = 'Medicare',
            Bypass_VR__c = true
        );
        insert agent;

        Carrier__c carrier = new Carrier__c(
            Name = 'Commission Event Test Carrier',
            Supported_Lines_of_Business__c = 'Medicare',
            Supports_Medicare__c = true
        );
        insert carrier;
    }

    private static void loadIds() {

        if (agentId != null) {
            return;
        }

        agencyId = [
            SELECT Id
            FROM Account
            WHERE Name = 'Commission Exception Event Test Agency'
            LIMIT 1
        ].Id;

        agentId = [
            SELECT Id
            FROM Contact
            WHERE Email = 'commissioneventagent@test.com'
            LIMIT 1
        ].Id;

        carrierId = [
            SELECT Id
            FROM Carrier__c
            WHERE Name = 'Commission Event Test Carrier'
            LIMIT 1
        ].Id;
    }

    private static Commission_Exception_Event__e buildEvent(
        String policyNumber,
        Decimal expectedAmount,
        Decimal actualAmount
    ) {
        loadIds();

        return new Commission_Exception_Event__e(
            Exception_Type__c = 'Underpaid',
            Policy_Number__c = policyNumber,
            Agent_Id__c = String.valueOf(agentId),
            Carrier_Id__c = String.valueOf(carrierId),
            Expected_Amount__c = expectedAmount,
            Actual_Amount__c = actualAmount,
            Payload__c = '{"Payment_Period__c":"2024-01"}'
        );
    }

    @IsTest
    static void testSingleEventCreatesCommissionException() {

        String policyNumber = 'POL-EVENT-001';

        Commission_Exception_Event__e eventRecord = buildEvent(
            policyNumber,
            100.00,
            75.00
        );

        Test.startTest();

        Database.SaveResult publishResult = EventBus.publish(
            eventRecord
        );

        Test.stopTest();

        System.assertEquals(
            true,
            publishResult.isSuccess(),
            'Platform Event must be published successfully.'
        );

        List<Commission_Exception__c> exceptions = [
            SELECT Id,
                   Exception_Type__c,
                   Policy_Number__c,
                   Agent__c,
                   Carrier__c,
                   Expected_Amount__c,
                   Actual_Amount__c,
                   Status__c,
                   Payload__c
            FROM Commission_Exception__c
            WHERE Policy_Number__c = :policyNumber
        ];

        System.assertEquals(
            1,
            exceptions.size(),
            'One Commission Exception record must be created.'
        );

        Commission_Exception__c exceptionRecord = exceptions[0];

        System.assertEquals(
            'Underpaid',
            exceptionRecord.Exception_Type__c,
            'Exception Type must come from the Platform Event.'
        );

        System.assertEquals(
            policyNumber,
            exceptionRecord.Policy_Number__c,
            'Policy Number must come from the Platform Event.'
        );

        System.assertEquals(
            agentId,
            exceptionRecord.Agent__c,
            'Agent must come from the Platform Event.'
        );

        System.assertEquals(
            carrierId,
            exceptionRecord.Carrier__c,
            'Carrier must come from the Platform Event.'
        );

        System.assertEquals(
            Decimal.valueOf('100.00'),
            exceptionRecord.Expected_Amount__c,
            'Expected Amount must come from the Platform Event.'
        );

        System.assertEquals(
            Decimal.valueOf('75.00'),
            exceptionRecord.Actual_Amount__c,
            'Actual Amount must come from the Platform Event.'
        );

        System.assertEquals(
            'Open',
            exceptionRecord.Status__c,
            'The trigger must set the exception status to Open.'
        );

        System.assertEquals(
            '{"Payment_Period__c":"2024-01"}',
            exceptionRecord.Payload__c,
            'Payload must come from the Platform Event.'
        );
    }

    @IsTest
    static void testBulkEventsCreateMultipleCommissionExceptions() {

        List<Commission_Exception_Event__e> eventRecords =
            new List<Commission_Exception_Event__e>();

        for (Integer i = 0; i < 10; i++) {
            eventRecords.add(
                buildEvent(
                    'POL-EVENT-BULK-' + i,
                    100.00,
                    Decimal.valueOf(90 - i)
                )
            );
        }

        Test.startTest();

        List<Database.SaveResult> publishResults = EventBus.publish(
            eventRecords
        );

        Test.stopTest();

        for (Database.SaveResult publishResult : publishResults) {
            System.assertEquals(
                true,
                publishResult.isSuccess(),
                'Every Platform Event must be published successfully.'
            );
        }

        Integer exceptionCount = [
            SELECT COUNT()
            FROM Commission_Exception__c
            WHERE Policy_Number__c LIKE 'POL-EVENT-BULK-%'
        ];

        System.assertEquals(
            10,
            exceptionCount,
            'Ten Platform Events must create ten Commission Exception records.'
        );
    }
}