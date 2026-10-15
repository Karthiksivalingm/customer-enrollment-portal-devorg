@IsTest
private class MissingPaymentBatchTest {

    private static final String TEST_PERIOD = '2024-01';


    @TestSetup
    static void setupData() {

        Upline_Policy__c missingPaymentPolicy =
            new Upline_Policy__c(
                Policy_Number__c = 'POL-MISSING-001',
                Status__c = 'Active'
            );

        Upline_Policy__c rejectedRowPolicy =
            new Upline_Policy__c(
                Policy_Number__c = 'POL-REJECTED-001',
                Status__c = 'Active'
            );

        insert new List<Upline_Policy__c>{
            missingPaymentPolicy,
            rejectedRowPolicy
        };


        Map<String, Object> rejectedPayload =
            new Map<String, Object>{
                'Payment_Period__c' => TEST_PERIOD,
                'Details' => 'Carrier row received but rejected.'
            };


        Commission_Exception__c rejectedRowException =
            new Commission_Exception__c(
                Exception_Type__c = 'Unknown_Policy',
                Policy_Number__c = 'POL-REJECTED-001',
                Status__c = 'Open',
                Payload__c = JSON.serialize(rejectedPayload)
            );

        insert rejectedRowException;
    }


    /*
     * Helper method to get Missing Payment exceptions
     */
    private static List<Commission_Exception__c> getMissingPayments(
        String policyNumber
    ) {

        return [
            SELECT Id,
                   Exception_Type__c,
                   Policy_Number__c,
                   Status__c,
                   Payload__c
            FROM Commission_Exception__c
            WHERE Policy_Number__c = :policyNumber
            AND Exception_Type__c = 'Missing_Payment'
        ];
    }


    /*
     * Test that Missing Payment exception is created
     */
    @IsTest
    static void testMissingPaymentExceptionCreated() {

        Test.startTest();

        Id batchJobId = Database.executeBatch(
            new MissingPaymentBatch(TEST_PERIOD),
            200
        );

        Test.stopTest();


        AsyncApexJob batchJob = [
            SELECT Id,
                   Status,
                   NumberOfErrors
            FROM AsyncApexJob
            WHERE Id = :batchJobId
        ];


        System.assertEquals(
            'Completed',
            batchJob.Status,
            'Missing Payment batch must complete successfully.'
        );


        System.assertEquals(
            0,
            batchJob.NumberOfErrors,
            'Missing Payment batch must not have errors.'
        );


        List<Commission_Exception__c> missingPaymentExceptions =
            getMissingPayments('POL-MISSING-001');


        System.assertEquals(
            1,
            missingPaymentExceptions.size(),
            'One Missing Payment exception must be created.'
        );


        System.assertEquals(
            'Open',
            missingPaymentExceptions[0].Status__c,
            'Missing Payment exception status must be Open.'
        );


        Map<String, Object> payload =
            (Map<String, Object>) JSON.deserializeUntyped(
                missingPaymentExceptions[0].Payload__c
            );


        System.assertNotEquals(
            null,
            payload.get('Upline_Policy_Id'),
            'Exception payload must contain the Upline Policy Id.'
        );


        System.assert(
            String.valueOf(
                payload.get('Details')
            ).contains(TEST_PERIOD),
            'Exception payload Details must mention the Payment Period.'
        );
    }


    /*
     * Test that a rejected CSV row does not create
     * an additional Missing Payment exception.
     */
    @IsTest
    static void testRejectedCsvRowDoesNotCreateMissingPaymentException() {

        Test.startTest();

        Database.executeBatch(
            new MissingPaymentBatch(TEST_PERIOD),
            200
        );

        Test.stopTest();


        List<Commission_Exception__c> missingPaymentExceptions =
            getMissingPayments('POL-REJECTED-001');


        System.assertEquals(
            0,
            missingPaymentExceptions.size(),
            'A policy with a rejected CSV row must not also receive '
            + 'a Missing Payment exception.'
        );
    }


    /*
     * Test that an already existing Missing Payment exception
     * prevents another Missing Payment exception from being created.
     */
    @IsTest
    static void testExistingMissingPaymentPreventsDuplicate() {

        Upline_Policy__c policy = [
            SELECT Id,
                   Policy_Number__c
            FROM Upline_Policy__c
            WHERE Policy_Number__c = 'POL-MISSING-001'
            LIMIT 1
        ];


        Map<String, Object> existingPayload =
            new Map<String, Object>{
                'Upline_Policy_Id' => policy.Id,
                'Payment_Period__c' => TEST_PERIOD,
                'Details' =>
                    'Existing Missing Payment for '
                    + TEST_PERIOD
            };


        Commission_Exception__c existingException =
            new Commission_Exception__c(
                Exception_Type__c = 'Missing_Payment',
                Policy_Number__c = policy.Policy_Number__c,
                Status__c = 'Open',
                Payload__c = JSON.serialize(existingPayload)
            );


        insert existingException;


        Test.startTest();

        Database.executeBatch(
            new MissingPaymentBatch(TEST_PERIOD),
            200
        );

        Test.stopTest();


        List<Commission_Exception__c> missingPaymentExceptions =
            getMissingPayments('POL-MISSING-001');


        System.assertEquals(
            1,
            missingPaymentExceptions.size(),
            'An existing Missing Payment exception must prevent '
            + 'a duplicate from being created.'
        );
    }


    /*
     * Test the Scheduler class.
     */
    @IsTest
    static void testSchedulerRunsSuccessfully() {

        Test.startTest();

        String scheduledJobId = System.schedule(
            'Missing Payment Scheduler Test',
            '0 0 0 1 1 ? 2099',
            new MissingPaymentScheduler()
        );

        Test.stopTest();


        System.assertNotEquals(
            null,
            scheduledJobId,
            'Scheduler must return a valid scheduled job Id.'
        );
    }
}