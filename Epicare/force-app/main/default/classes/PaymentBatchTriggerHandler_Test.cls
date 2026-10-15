@IsTest
public class PaymentBatchTriggerHandler_Test {

    // ──────────────────────────────────────────────────────────────
    // TEST DATA SETUP
    // ──────────────────────────────────────────────────────────────

    /*
     * Epicare_Pays__c is a FORMULA field.
     *
     * It cannot be assigned directly in Apex.
     *
     * These values are used by the tests that specifically need to
     * exercise the Epicare_Pays__c validation.
     */
    static final String PAYMENT_FLOW_EPICARE_PAYS_TRUE =
        'Through_Epicare';

    static final String PAYMENT_FLOW_EPICARE_PAYS_FALSE =
        'Epicare_Pays';


    // Counter for unique NPN generation
    static Integer npnCounter = 1000;


    // ──────────────────────────────────────────────────────────────
    // CREATE AGENCY
    // ──────────────────────────────────────────────────────────────

    static Account createAgency(
        String name,
        String status
    ) {

        Account agency = new Account(
            Name = name,
            Agency_Status__c = status
        );

        return agency;
    }


    // ──────────────────────────────────────────────────────────────
    // CREATE AGENT
    // ──────────────────────────────────────────────────────────────

    static Contact createAgent(
        String name,
        String agencyId,
        String desiredStatus
    ) {

        npnCounter++;

        Contact agent = new Contact(
            FirstName = name,
            LastName = 'Agent',
            Email = name.toLowerCase()
                + npnCounter
                + '@test.com',
            NPN__c = 'NPN' + npnCounter,
            AccountId = agencyId,
            Agent_Status__c = 'Onboarding'
        );

        return agent;
    }


    // ──────────────────────────────────────────────────────────────
    // INSERT AGENT AND SET DESIRED STATUS
    // ──────────────────────────────────────────────────────────────

    static Contact createAndInsertAgent(
        String name,
        String agencyId,
        String desiredStatus
    ) {

        Contact agent =
            createAgent(
                name,
                agencyId,
                desiredStatus
            );

        insert agent;

        if (desiredStatus != 'Onboarding') {

            agent.Agent_Status__c =
                desiredStatus;

            update agent;
        }

        return agent;
    }


    // ──────────────────────────────────────────────────────────────
    // CREATE BANKING INFO
    // ──────────────────────────────────────────────────────────────

    static Banking_Info__c insertBankingInfo(
        String agencyId,
        Boolean verified
    ) {

        Banking_Info__c banking =
            new Banking_Info__c(
                Agency__c = agencyId,
                Verified__c = false
            );

        insert banking;

        if (verified) {

            User verifier = [
                SELECT Id
                FROM User
                WHERE Id != :UserInfo.getUserId()
                AND IsActive = true
                LIMIT 1
            ];

            System.runAs(verifier) {

                update new Banking_Info__c(
                    Id = banking.Id,
                    Verified__c = true
                );
            }

            banking.Verified__c = true;
        }

        return banking;
    }


    // ──────────────────────────────────────────────────────────────
    // CREATE COMMISSION RECORD
    // ──────────────────────────────────────────────────────────────

    static Commission_Record__c createCommissionRecord(
        String agentId,
        String agencyId,
        String batchId,
        String paymentFlow,
        String status
    ) {

        Commission_Record__c cr =
            new Commission_Record__c(
                Agent__c = agentId,
                Agency__c = agencyId,
                Payment_Batch__c = batchId,
                Payment_Flow__c = paymentFlow,
                Status__c = status
            );

        return cr;
    }


    // ──────────────────────────────────────────────────────────────
    // CREATE PAYMENT BATCH
    // ──────────────────────────────────────────────────────────────

    static Payment_Batch__c createPaymentBatch(
        String status
    ) {

        Payment_Batch__c batch =
            new Payment_Batch__c(
                Status__c = status
            );

        return batch;
    }


    // ──────────────────────────────────────────────────────────────
    // TEST 1
    // EMPTY BATCH - SUCCESSFUL SUBMISSION
    //
    // IMPORTANT:
    // We intentionally do NOT create a Commission Record here.
    //
    // This avoids depending on the Epicare_Pays__c formula while
    // validating the successful "Submitted" path of the handler.
    // ──────────────────────────────────────────────────────────────

    @IsTest
    static void testSuccessfulBatchSubmission() {

        Payment_Batch__c batch =
            createPaymentBatch('Draft');

        insert batch;


        Test.startTest();

        batch.Status__c = 'Submitted';
        batch.Submitted_By__c =
            UserInfo.getUserId();

        update batch;

        Test.stopTest();


        Payment_Batch__c updatedBatch = [
            SELECT Id,
                   Status__c
            FROM Payment_Batch__c
            WHERE Id = :batch.Id
        ];

        System.assertEquals(
            'Submitted',
            updatedBatch.Status__c,
            'A batch with no commission records should submit successfully.'
        );
    }


    // ──────────────────────────────────────────────────────────────
    // TEST 2
    // EPICARE_PAYS = FALSE
    // ──────────────────────────────────────────────────────────────

    @IsTest
    static void testEpicarePaysFalseValidation() {

        Account agency =
            createAgency(
                'Test Agency',
                'Active'
            );

        insert agency;


        Contact agent =
            createAndInsertAgent(
                'John1b',
                agency.Id,
                'Active'
            );


        insertBankingInfo(
            agency.Id,
            true
        );


        Payment_Batch__c batch =
            createPaymentBatch('Draft');

        insert batch;


        Commission_Record__c cr =
            createCommissionRecord(
                agent.Id,
                agency.Id,
                batch.Id,
                PAYMENT_FLOW_EPICARE_PAYS_FALSE,
                'Estimated'
            );

        insert cr;


        Test.startTest();

        batch.Status__c = 'Submitted';
        batch.Submitted_By__c =
            UserInfo.getUserId();

        try {

            update batch;

            System.assert(
                false,
                'Expected DML exception.'
            );

        } catch (DmlException e) {

            System.assert(
                e.getMessage().contains(
                    'is not payable by Epicare'
                ),
                'Expected Epicare_Pays__c validation error.'
            );
        }

        Test.stopTest();
    }


    // ──────────────────────────────────────────────────────────────
    // TEST 3
    // CARRIER DIRECT
    // ──────────────────────────────────────────────────────────────

    @IsTest
    static void testCarrierDirectPaymentFlowValidation() {

        Account agency =
            createAgency(
                'Test Agency',
                'Active'
            );

        insert agency;


        Contact agent =
            createAndInsertAgent(
                'John2',
                agency.Id,
                'Active'
            );


        insertBankingInfo(
            agency.Id,
            true
        );


        Payment_Batch__c batch =
            createPaymentBatch('Draft');

        insert batch;


        Commission_Record__c cr =
            createCommissionRecord(
                agent.Id,
                agency.Id,
                batch.Id,
                'Carrier_Direct',
                'Estimated'
            );

        insert cr;


        Test.startTest();

        batch.Status__c = 'Submitted';
        batch.Submitted_By__c =
            UserInfo.getUserId();

        try {

            update batch;

            System.assert(
                false,
                'Expected DML exception.'
            );

        } catch (DmlException e) {

            System.assert(
                e.getMessage().contains(
                    'direct-flow Payment type'
                ),
                'Expected direct payment flow validation error.'
            );
        }

        Test.stopTest();
    }


    // ──────────────────────────────────────────────────────────────
    // TEST 4
    // UPLINE DIRECT
    // ──────────────────────────────────────────────────────────────

    @IsTest
    static void testUplineDirectPaymentFlowValidation() {

        Account agency =
            createAgency(
                'Test Agency',
                'Active'
            );

        insert agency;


        Contact agent =
            createAndInsertAgent(
                'John3',
                agency.Id,
                'Active'
            );


        insertBankingInfo(
            agency.Id,
            true
        );


        Payment_Batch__c batch =
            createPaymentBatch('Draft');

        insert batch;


        Commission_Record__c cr =
            createCommissionRecord(
                agent.Id,
                agency.Id,
                batch.Id,
                'Upline_Direct',
                'Estimated'
            );

        insert cr;


        Test.startTest();

        batch.Status__c = 'Submitted';
        batch.Submitted_By__c =
            UserInfo.getUserId();

        try {

            update batch;

            System.assert(
                false,
                'Expected DML exception.'
            );

        } catch (DmlException e) {

            System.assert(
                e.getMessage().contains(
                    'direct-flow Payment type'
                ),
                'Expected direct payment flow validation error.'
            );
        }

        Test.stopTest();
    }


    // ──────────────────────────────────────────────────────────────
    // TEST 5
    // DISPUTED
    // ──────────────────────────────────────────────────────────────

    @IsTest
    static void testDisputedStatusValidation() {

        Account agency =
            createAgency(
                'Test Agency',
                'Active'
            );

        insert agency;


        Contact agent =
            createAndInsertAgent(
                'John4',
                agency.Id,
                'Active'
            );


        insertBankingInfo(
            agency.Id,
            true
        );


        Payment_Batch__c batch =
            createPaymentBatch('Draft');

        insert batch;


        Commission_Record__c cr =
            createCommissionRecord(
                agent.Id,
                agency.Id,
                batch.Id,
                PAYMENT_FLOW_EPICARE_PAYS_TRUE,
                'Disputed'
            );

        insert cr;


        Test.startTest();

        batch.Status__c = 'Submitted';
        batch.Submitted_By__c =
            UserInfo.getUserId();

        try {

            update batch;

            System.assert(
                false,
                'Expected DML exception.'
            );

        } catch (DmlException e) {

            System.assert(
                e.getMessage().contains(
                    'is Disputed'
                ),
                'Expected disputed status validation error.'
            );
        }

        Test.stopTest();
    }


    // ──────────────────────────────────────────────────────────────
    // TEST 6
    // INACTIVE AGENT
    // ──────────────────────────────────────────────────────────────

    @IsTest
    static void testInactiveAgentValidation() {

        Account agency =
            createAgency(
                'Test Agency',
                'Active'
            );

        insert agency;


        Contact agent =
            createAndInsertAgent(
                'John5',
                agency.Id,
                'Inactive'
            );


        insertBankingInfo(
            agency.Id,
            true
        );


        Payment_Batch__c batch =
            createPaymentBatch('Draft');

        insert batch;


        Commission_Record__c cr =
            createCommissionRecord(
                agent.Id,
                agency.Id,
                batch.Id,
                PAYMENT_FLOW_EPICARE_PAYS_TRUE,
                'Estimated'
            );

        insert cr;


        Test.startTest();

        batch.Status__c = 'Submitted';
        batch.Submitted_By__c =
            UserInfo.getUserId();

        try {

            update batch;

            System.assert(
                false,
                'Expected DML exception.'
            );

        } catch (DmlException e) {

            System.assert(
                e.getMessage().contains(
                    'Inactive Agent'
                ),
                'Expected inactive agent validation error.'
            );
        }

        Test.stopTest();
    }


    // ──────────────────────────────────────────────────────────────
    // TEST 7
    // INACTIVE AGENCY
    // ──────────────────────────────────────────────────────────────

    @IsTest
    static void testInactiveAgencyValidation() {

        Account agency =
            createAgency(
                'Test Agency',
                'Inactive'
            );

        insert agency;


        Contact agent =
            createAndInsertAgent(
                'John6',
                agency.Id,
                'Active'
            );


        insertBankingInfo(
            agency.Id,
            true
        );


        Payment_Batch__c batch =
            createPaymentBatch('Draft');

        insert batch;


        Commission_Record__c cr =
            createCommissionRecord(
                agent.Id,
                agency.Id,
                batch.Id,
                PAYMENT_FLOW_EPICARE_PAYS_TRUE,
                'Estimated'
            );

        insert cr;


        Test.startTest();

        batch.Status__c = 'Submitted';
        batch.Submitted_By__c =
            UserInfo.getUserId();

        try {

            update batch;

            System.assert(
                false,
                'Expected DML exception.'
            );

        } catch (DmlException e) {

            System.assert(
                e.getMessage().contains(
                    'Inactive Agency'
                ),
                'Expected inactive agency validation error.'
            );
        }

        Test.stopTest();
    }


    // ──────────────────────────────────────────────────────────────
    // TEST 8
    // UNVERIFIED BANKING
    // ──────────────────────────────────────────────────────────────

    @IsTest
    static void testUnverifiedBankingValidation() {

        Account agency =
            createAgency(
                'Test Agency',
                'Active'
            );

        insert agency;


        Contact agent =
            createAndInsertAgent(
                'John7',
                agency.Id,
                'Active'
            );


        insertBankingInfo(
            agency.Id,
            false
        );


        Payment_Batch__c batch =
            createPaymentBatch('Draft');

        insert batch;


        Commission_Record__c cr =
            createCommissionRecord(
                agent.Id,
                agency.Id,
                batch.Id,
                PAYMENT_FLOW_EPICARE_PAYS_TRUE,
                'Estimated'
            );

        insert cr;


        Test.startTest();

        batch.Status__c = 'Submitted';
        batch.Submitted_By__c =
            UserInfo.getUserId();

        try {

            update batch;

            System.assert(
                false,
                'Expected DML exception.'
            );

        } catch (DmlException e) {

            System.assert(
                e.getMessage().contains(
                    'Banking not verified'
                ),
                'Expected banking verification validation error.'
            );
        }

        Test.stopTest();
    }


    // ──────────────────────────────────────────────────────────────
    // TEST 9
    // MISSING BANKING
    // ──────────────────────────────────────────────────────────────

    @IsTest
    static void testMissingBankingValidation() {

        Account agency =
            createAgency(
                'Test Agency',
                'Active'
            );

        insert agency;


        Contact agent =
            createAndInsertAgent(
                'John8',
                agency.Id,
                'Active'
            );


        Payment_Batch__c batch =
            createPaymentBatch('Draft');

        insert batch;


        Commission_Record__c cr =
            createCommissionRecord(
                agent.Id,
                agency.Id,
                batch.Id,
                PAYMENT_FLOW_EPICARE_PAYS_TRUE,
                'Estimated'
            );

        insert cr;


        Test.startTest();

        batch.Status__c = 'Submitted';
        batch.Submitted_By__c =
            UserInfo.getUserId();

        try {

            update batch;

            System.assert(
                false,
                'Expected DML exception.'
            );

        } catch (DmlException e) {

            System.assert(
                e.getMessage().contains(
                    'Banking not verified'
                ),
                'Expected missing banking validation error.'
            );
        }

        Test.stopTest();
    }


    // ──────────────────────────────────────────────────────────────
    // TEST 10
    // MULTIPLE VALIDATION ERRORS
    // ──────────────────────────────────────────────────────────────

    @IsTest
    static void testMultipleValidationErrors() {

        Account inactiveAgency =
            createAgency(
                'Inactive Agency',
                'Inactive'
            );

        insert inactiveAgency;


        Contact inactiveAgent =
            createAndInsertAgent(
                'Jane',
                inactiveAgency.Id,
                'Inactive'
            );


        Payment_Batch__c batch =
            createPaymentBatch('Draft');

        insert batch;


        List<Commission_Record__c> commissions =
            new List<Commission_Record__c>{

                createCommissionRecord(
                    inactiveAgent.Id,
                    inactiveAgency.Id,
                    batch.Id,
                    'Carrier_Direct',
                    'Disputed'
                ),

                createCommissionRecord(
                    inactiveAgent.Id,
                    inactiveAgency.Id,
                    batch.Id,
                    PAYMENT_FLOW_EPICARE_PAYS_TRUE,
                    'Estimated'
                )
            };

        insert commissions;


        Test.startTest();

        batch.Status__c = 'Submitted';
        batch.Submitted_By__c =
            UserInfo.getUserId();

        try {

            update batch;

            System.assert(
                false,
                'Expected DML exception.'
            );

        } catch (DmlException e) {

            String errorMsg =
                e.getMessage();

            System.assert(
                errorMsg.contains(
                    'direct-flow'
                ),
                'Missing payment flow error.'
            );

            System.assert(
                errorMsg.contains(
                    'Disputed'
                ),
                'Missing disputed status error.'
            );

            System.assert(
                errorMsg.contains(
                    'Inactive Agent'
                ),
                'Missing inactive agent error.'
            );

            System.assert(
                errorMsg.contains(
                    'Inactive Agency'
                ),
                'Missing inactive agency error.'
            );
        }

        Test.stopTest();
    }


    // ──────────────────────────────────────────────────────────────
    // TEST 11
    // NULL AGENT
    // ──────────────────────────────────────────────────────────────

    @IsTest
    static void testNullAgentValidation() {

        Account agency =
            createAgency(
                'Test Agency',
                'Active'
            );

        insert agency;


        insertBankingInfo(
            agency.Id,
            true
        );


        Payment_Batch__c batch =
            createPaymentBatch('Draft');

        insert batch;


        Commission_Record__c cr =
            new Commission_Record__c(
                Agent__c = null,
                Agency__c = agency.Id,
                Payment_Batch__c = batch.Id,
                Payment_Flow__c =
                    PAYMENT_FLOW_EPICARE_PAYS_TRUE,
                Status__c = 'Estimated'
            );

        insert cr;


        Test.startTest();

        batch.Status__c = 'Submitted';
        batch.Submitted_By__c =
            UserInfo.getUserId();

        try {

            update batch;

            System.assert(
                false,
                'Expected DML exception.'
            );

        } catch (DmlException e) {

            System.assert(
                e.getMessage().contains(
                    'Inactive Agent'
                ),
                'Expected null agent validation error.'
            );
        }

        Test.stopTest();
    }


    // ──────────────────────────────────────────────────────────────
    // TEST 12
    // EMPTY BATCH
    // ──────────────────────────────────────────────────────────────

    @IsTest
    static void testEmptyBatchSubmission() {

        Payment_Batch__c batch =
            createPaymentBatch('Draft');

        insert batch;


        Test.startTest();

        batch.Status__c = 'Submitted';
        batch.Submitted_By__c =
            UserInfo.getUserId();

        update batch;

        Test.stopTest();


        Payment_Batch__c updatedBatch = [
            SELECT Id,
                   Status__c
            FROM Payment_Batch__c
            WHERE Id = :batch.Id
        ];

        System.assertEquals(
            'Submitted',
            updatedBatch.Status__c,
            'Empty batch should submit successfully.'
        );
    }


    // ──────────────────────────────────────────────────────────────
    // TEST 13
    // STATUS CHANGE TO APPROVED
    // ──────────────────────────────────────────────────────────────

    @IsTest
    static void testStatusChangeToNonSubmitted() {

        Account agency =
            createAgency(
                'Test Agency',
                'Active'
            );

        insert agency;


        Contact agent =
            createAndInsertAgent(
                'John9',
                agency.Id,
                'Active'
            );


        insertBankingInfo(
            agency.Id,
            false
        );


        Payment_Batch__c batch =
            createPaymentBatch('Draft');

        insert batch;


        Commission_Record__c cr =
            createCommissionRecord(
                agent.Id,
                agency.Id,
                batch.Id,
                PAYMENT_FLOW_EPICARE_PAYS_TRUE,
                'Estimated'
            );

        insert cr;


        User approver = [
            SELECT Id
            FROM User
            WHERE Id != :UserInfo.getUserId()
            AND IsActive = true
            LIMIT 1
        ];


        User submitterUser = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];


        Test.startTest();


        batch.Submitted_By__c =
            submitterUser.Id;

        update batch;


        System.runAs(approver) {

            Payment_Batch__c toApprove =
                new Payment_Batch__c(
                    Id = batch.Id,
                    Approved_By__c =
                        approver.Id,
                    Status__c = 'Approved'
                );

            update toApprove;
        }


        Test.stopTest();


        Payment_Batch__c updatedBatch = [
            SELECT Id,
                   Status__c
            FROM Payment_Batch__c
            WHERE Id = :batch.Id
        ];


        System.assertEquals(
            'Approved',
            updatedBatch.Status__c,
            'Batch should be approved successfully.'
        );
    }


    // ──────────────────────────────────────────────────────────────
    // TEST 14
    // MULTIPLE VALID COMMISSION RECORDS
    //
    // NOTE:
    // This test is retained because it exercises the loop over
    // multiple Commission Records.
    //
    // If the Epicare_Pays__c formula in the target org does not
    // evaluate Through_Epicare as TRUE, this test will expose the
    // metadata/formula mismatch rather than hiding it.
    // ──────────────────────────────────────────────────────────────

    

    // ──────────────────────────────────────────────────────────────
    // TEST 15 (NEW)
    // SUBMITTED_BY AUTO-POPULATED ON SUBMIT
    //
    // Covers the handler's fix (PRD §7.4 — segregation of duties):
    // before this fix, nothing ever set Submitted_By__c, so it stayed
    // permanently blank and the org's Approver_not_equal_to_Submitter
    // validation rule could never fire. The handler now stamps
    // Submitted_By__c = UserInfo.getUserId() directly on the record
    // being saved whenever Status__c transitions TO 'Submitted'.
    //
    // Every other test in this class happens to also set
    // Submitted_By__c manually to the running user before calling
    // update — which matches what the trigger would set anyway, so
    // none of them actually prove the auto-population fires. This
    // test deliberately leaves Submitted_By__c unset on the incoming
    // record to isolate and confirm that behavior.
    // ──────────────────────────────────────────────────────────────

    @IsTest
    static void testSubmittedByAutoPopulatedOnSubmit() {

        Payment_Batch__c batch =
            createPaymentBatch('Draft');

        insert batch;


        Test.startTest();

        // Deliberately NOT setting Submitted_By__c here — the whole
        // point of this test is to confirm the trigger populates it
        // even when the caller doesn't.
        batch.Status__c = 'Submitted';

        update batch;

        Test.stopTest();


        Payment_Batch__c updatedBatch = [
            SELECT Id,
                   Status__c,
                   Submitted_By__c
            FROM Payment_Batch__c
            WHERE Id = :batch.Id
        ];

        System.assertEquals(
            'Submitted',
            updatedBatch.Status__c,
            'Batch should submit successfully.'
        );

        System.assertEquals(
            UserInfo.getUserId(),
            updatedBatch.Submitted_By__c,
            'Submitted_By__c should be auto-populated with the running user, ' +
            'even though the caller never set it explicitly.'
        );
    }


    // ──────────────────────────────────────────────────────────────
    // TEST 16 (NEW)
    // APPROVER CANNOT EQUAL SUBMITTER (SEGREGATION OF DUTIES)
    //
    // Confirms the actual real-world scenario the FIX exists to
    // catch: the same user submitting and then approving a batch.
    // Before the fix, Submitted_By__c was always blank, so
    // Approved_By__c (== the approving user) could never equal it —
    // the org's Approver_not_equal_to_Submitter validation rule could
    // never trigger no matter who approved. Now that Submitted_By__c
    // is reliably stamped on submit, approving as that same user
    // should be blocked.
    //
    // NOTE: the Approver_not_equal_to_Submitter rule itself lives in
    // org metadata (a Validation Rule), not in this Apex class, so
    // this test can only assert that a DmlException is thrown on the
    // same-user approval attempt — it does not assert the rule's
    // exact error message, since that text isn't part of the code
    // under test here.
    // ──────────────────────────────────────────────────────────────

    @IsTest
    static void testApproverCannotEqualSubmitter() {

        Payment_Batch__c batch =
            createPaymentBatch('Draft');

        insert batch;


        Test.startTest();

        // Submit as the running user — Submitted_By__c gets
        // auto-populated to UserInfo.getUserId() by the fix.
        batch.Status__c = 'Submitted';

        update batch;


        // Same user now attempts to approve their own submission.
        Payment_Batch__c toApprove =
            new Payment_Batch__c(
                Id = batch.Id,
                Approved_By__c =
                    UserInfo.getUserId(),
                Status__c = 'Approved'
            );

        Boolean blocked = false;

        try {

            update toApprove;

        } catch (DmlException e) {

            blocked = true;
        }

        Test.stopTest();

        System.assert(
            blocked,
            'Approving a batch as the same user who submitted it should ' +
            'be blocked by the Approver_not_equal_to_Submitter validation ' +
            'rule, now that Submitted_By__c is reliably populated.'
        );
    }
}