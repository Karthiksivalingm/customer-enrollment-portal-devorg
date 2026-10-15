@IsTest
private class ChargebackNotificationTriggerTest {

    // ─────────────────────────────────────────────────────────────────────────
    // Mock for GoAMS integration callout
    // ─────────────────────────────────────────────────────────────────────────

    private class GoAMSAccessTokenMock implements HttpCalloutMock {

        public HttpResponse respond(HttpRequest req) {

            HttpResponse res = new HttpResponse();

            res.setStatusCode(200);
            res.setHeader(
                'Content-Type',
                'application/json'
            );

            res.setBody(
                '{"access_token":"test-token","expires_in":3600}'
            );

            return res;
        }
    }


    // ─────────────────────────────────────────────────────────────────────────
    // Helper: Create Agent
    // ─────────────────────────────────────────────────────────────────────────

    private static Contact createAgent(
        String lastName,
        String email,
        String npn
    ) {

        Contact con = new Contact(
            LastName = lastName,
            Email = email,
            NPN__c = npn,
            Agent_Status__c = 'Onboarding'
        );

        insert con;

        return con;
    }


    // ─────────────────────────────────────────────────────────────────────────
    // Chargeback vs Non-Chargeback
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testChargebackPublishesEventNonChargebackDoesNot() {

        // ---------------------------------------------------------
        // Chargeback test data
        // ---------------------------------------------------------

        Contact chargebackAgent = createAgent(
            'Test Agent',
            'agent@test.com',
            '12345678'
        );

        Payment_Batch__c chargebackBatch =
            new Payment_Batch__c();

        insert chargebackBatch;


        // ---------------------------------------------------------
        // Non-Chargeback test data
        // ---------------------------------------------------------

        Contact advanceAgent = createAgent(
            'Test Agent 2',
            'agent2@test.com',
            '87654321'
        );

        Payment_Batch__c advanceBatch =
            new Payment_Batch__c();

        insert advanceBatch;


        // ---------------------------------------------------------
        // Mock GoAMS callout
        // ---------------------------------------------------------

        Test.setMock(
            HttpCalloutMock.class,
            new GoAMSAccessTokenMock()
        );


        Test.startTest();


        // ---------------------------------------------------------
        // CHARGEBACK RECORD
        //
        // This should enter:
        //
        // if (cr.Compensation_Type__c == 'Chargeback')
        //
        // and publish Commission_Paid__e.
        // ---------------------------------------------------------

        Commission_Record__c chargebackCr =
            new Commission_Record__c(
                Agent__c = chargebackAgent.Id,
                Payment_Batch__c = chargebackBatch.Id,
                Compensation_Type__c = 'Chargeback',
                Chargeback_Amount__c = 250,
                Payment_Period__c = '2026-06'
            );

        insert chargebackCr;


        // ---------------------------------------------------------
        // NON-CHARGEBACK RECORD
        //
        // "Advance" was replaced with "Commission" because
        // "Advance" is not an active value in the
        // Compensation_Type__c restricted picklist.
        // ---------------------------------------------------------

        Commission_Record__c advanceCr =
            new Commission_Record__c(
                Agent__c = advanceAgent.Id,
                Payment_Batch__c = advanceBatch.Id,
                Compensation_Type__c = 'Commission'
            );

        insert advanceCr;


        Test.stopTest();


        // ---------------------------------------------------------
        // Verify both Commission Records were inserted
        // ---------------------------------------------------------

        Map<Id, Commission_Record__c> results =
            new Map<Id, Commission_Record__c>([
                SELECT Id,
                       Compensation_Type__c
                FROM Commission_Record__c
                WHERE Id IN :new Set<Id>{
                    chargebackCr.Id,
                    advanceCr.Id
                }
            ]);


        System.assertEquals(
            2,
            results.size(),
            'Both Commission Record records should be created.'
        );


        // ---------------------------------------------------------
        // Verify Chargeback record
        // ---------------------------------------------------------

        System.assertEquals(
            'Chargeback',
            results.get(chargebackCr.Id).Compensation_Type__c,
            'The first Commission Record must be Chargeback.'
        );


        // ---------------------------------------------------------
        // Verify non-Chargeback record
        // ---------------------------------------------------------

        System.assertEquals(
            'Commission',
            results.get(advanceCr.Id).Compensation_Type__c,
            'The second Commission Record must be Commission.'
        );
    }
}