/**
 * CommissionRecordTriggerHandler_Test
 * ------------------------------------------------------------------
 * ASSUMPTIONS / THINGS TO VERIFY IN YOUR ORG (see handler's own header
 * comments for the schema assumptions it already documents):
 *
 *  1. Contact creation follows the same org validation rule pattern seen in
 *     PaymentBatchTriggerHandler_Test: Agent_Status__c must be 'Onboarding'
 *     on insert, then can be updated. NPN__c max length 10.
 *
 *  1b. Upline_Policy__c.Upline_Source__c is a RESTRICTED picklist. 'Carrier'
     is NOT a valid value in this org — 'Platform' is confirmed valid (it's
     the value the handler itself checks for). This test class now uses
     'Platform' for all Upline_Policy__c records; this is safe everywhere
     because Underpaid/Overpaid only fires when a matching Estimated
     Commission_Record__c exists, which most tests don't create.

  2. Commission_Record__c may have required fields beyond what this
 *     handler reads directly (e.g. Agency__c, Payment_Batch__c,
 *     Payment_Flow__c — these were required in the sibling
 *     PaymentBatchTriggerHandler flow). This test's
 *     createCommissionRecordCsvRow() helper populates them defensively.
 *     If your org doesn't require them, feel free to strip them out.
 *
 *  3. CommissionRecordTrigger ALSO calls
 *     CommissionPaymentBatchRollupHandler.updatePaymentBatchTotals() on
 *     every insert/update of Commission_Record__c. That class isn't shown
 *     to me, so if it has its own requirements (e.g. a non-null
 *     Payment_Batch__c, specific rollup fields), inserts below could fail
 *     for reasons unrelated to CommissionRecordTriggerHandler itself. If
 *     you see failures NOT matching the exception-type assertions in this
 *     file, they're most likely coming from that rollup handler — share
 *     it and I'll extend this test class.
 *
 *  4. Commission_Exception_Event__e is a platform event. Publishing it is
 *     synchronous; DELIVERY to its subscriber trigger
 *     (CommissionExceptionEventTrigger, not shown to me) only happens in
 *     test context if Test.stopTest() is called. To keep these tests
 *     scoped to CommissionRecordTriggerHandler only, Test.startTest()/
 *     Test.stopTest() are used ONLY around the DML being verified, and we
 *     deliberately do NOT assert anything about Commission_Exception__c
 *     records or event delivery — only about whether the triggering DML
 *     succeeded/failed and its error message. If CommissionExceptionEventTrigger
 *     has a bug, it may surface here as an unrelated failure at
 *     Test.stopTest() — that would point to a bug in that class, not this one.
 *
 *  5. Upline_Policy__c field assumptions per the handler's own header:
 *     Agent_Code__c (Text), Agent__c (Contact), Agent__r.NPN__c reachable.
 */
@IsTest
public class CommissionRecordTriggerHandler_Test {

    // ──────────────────────────────────────────────────────────────
    // TEST DATA HELPERS
    // ──────────────────────────────────────────────────────────────

    static Integer counter = 1000;

    static Account createAgency(String name) {
        Account agency = new Account(
            Name = name,
            Agency_Status__c = 'Active'  // ASSUMPTION: same field as PaymentBatchTriggerHandler org
        );
        insert agency;
        return agency;
    }

    // Mirrors the pattern from PaymentBatchTriggerHandler_Test: Contact
    // must be created with Agent_Status__c = 'Onboarding' first.
    static Contact createAgent(String firstName, String npn, Id agencyId) {
        counter++;
        Contact agent = new Contact(
            FirstName = firstName,
            LastName = 'Agent',
            Email = firstName.toLowerCase() + counter + '@test.com',
            NPN__c = npn,                 // caller controls exact value for match/mismatch tests
            AccountId = agencyId,
            Agent_Status__c = 'Onboarding'
        );
        insert agent;
        agent.Agent_Status__c = 'Active';
        update agent;
        return agent;
    }

    static Upline_Policy__c createUplinePolicy(
        String policyNumber,
        String status,
        String uplineSource,
        Id agentId,
        String agentCode
    ) {
        Upline_Policy__c policy = new Upline_Policy__c(
            Policy_Number__c = policyNumber,
            Status__c = status,
            Upline_Source__c = uplineSource,
            Agent__c = agentId,
            Agent_Code__c = agentCode
        );
        insert policy;
        return policy;
    }

    // Estimated commission record used as the Underpaid/Overpaid comparison
    // baseline. Status__c = 'Estimated' per the handler's SOQL filter.
    static Commission_Record__c createEstimatedRecord(
        String policyNumber,
        String paymentPeriod,
        String agentCode,
        Decimal expectedAmount
    ) {
        Commission_Record__c est = new Commission_Record__c(
            Policy_Number__c = policyNumber,
            Payment_Period__c = paymentPeriod,
            Agent_Code__c = agentCode,
            Expected_Amount__c = expectedAmount,
            Status__c = 'Estimated'
            // ASSUMPTION: Estimated records don't need Upline_Source__c set
            // to 'Carepoint'/'Claro Insurance', since they skip validation
            // entirely (not a CSV row) and are only ever read, not written,
            // by beforeSave().
        );
        insert est;
        return est;
    }

    // The record type actually exercising CommissionRecordTriggerHandler's
    // validation — must have Upline_Source__c = 'Carepoint' or
    // 'Claro Insurance' to NOT be skipped.
    static Commission_Record__c buildCsvRow(
        String uplineSource,
        Decimal grossAmount,
        String policyNumber,
        String paymentPeriod,
        String agentCode,
        Id agentId
    ) {
        return new Commission_Record__c(
            Upline_Source__c = uplineSource,
            Gross_Amount__c = grossAmount,
            Policy_Number__c = policyNumber,
            Payment_Period__c = paymentPeriod,
            Agent_Code__c = agentCode,
            Agent__c = agentId,
            Status__c = 'Paid' // ASSUMPTION: any non-'Estimated' value works; adjust to a real picklist value in your org
        );
    }

    // ──────────────────────────────────────────────────────────────
    // TEST 1: Non-CSV source skips validation entirely
    // ──────────────────────────────────────────────────────────────
    @IsTest
    static void testNonCsvSourceSkipsValidation() {
        // Deliberately invalid data (blank Policy_Number__c would normally
        // trip Unknown_Policy) but Upline_Source__c is NOT Carepoint/Claro,
        // so beforeSave() should skip this row entirely and let it insert.
        Commission_Record__c rec = new Commission_Record__c(
            Upline_Source__c = 'Platform', // not 'Carepoint' or 'Claro Insurance'
            Gross_Amount__c = 0,           // would trip Blocked_Unpaid_Bill if evaluated
            Policy_Number__c = 'DOES-NOT-EXIST',
            Status__c = 'Paid'
        );

        Test.startTest();
        insert rec; // should NOT throw
        Test.stopTest();

        Commission_Record__c saved = [SELECT Id FROM Commission_Record__c WHERE Id = :rec.Id];
        System.assertNotEquals(null, saved.Id, 'Non-CSV-source row should have inserted without validation');
    }

    // ──────────────────────────────────────────────────────────────
    // TEST 2: Blocked_Unpaid_Bill — Gross_Amount__c = 0
    // ──────────────────────────────────────────────────────────────
    @IsTest
    static void testBlockedUnpaidBill() {
        Commission_Record__c rec = buildCsvRow(
            'Carepoint', 0, 'POLICY-001', '2026-01', 'AC-001', null
        );

        Test.startTest();
        try {
            insert rec;
            System.assert(false, 'Expected DmlException for Blocked Unpaid Bill');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('Blocked Unpaid Bill'),
                'Expected Blocked Unpaid Bill error, got: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    // ──────────────────────────────────────────────────────────────
    // TEST 3: Unknown_Policy — Policy_Number__c doesn't resolve
    // ──────────────────────────────────────────────────────────────
    @IsTest
    static void testUnknownPolicy() {
        Commission_Record__c rec = buildCsvRow(
            'Carepoint', 100, 'DOES-NOT-EXIST', '2026-01', 'AC-001', null
        );

        Test.startTest();
        try {
            insert rec;
            System.assert(false, 'Expected DmlException for Unknown Policy');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('Unknown Policy'),
                'Expected Unknown Policy error, got: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    // ──────────────────────────────────────────────────────────────
    // TEST 4: Agent_Mismatch — NPN on row doesn't match NPN on policy's agent
    // ──────────────────────────────────────────────────────────────
    @IsTest
    static void testAgentMismatch() {
        Account agency = createAgency('Agency Mismatch Test');
        Contact policyAgent = createAgent('PolicyAgent', 'NPN1001', agency.Id);
        Contact rowAgent = createAgent('RowAgent', 'NPN9999', agency.Id); // deliberately different NPN

        // ★ CHANGED: 'Carrier' is not a valid value for the restricted
        // picklist Upline_Source__c — 'Platform' is confirmed valid. Using
        // it here doesn't affect this test: Underpaid/Overpaid only fires
        // when a matching Estimated Commission_Record__c exists, and none
        // is created in this test, so that check is a no-op.
        Upline_Policy__c policy = createUplinePolicy(
            'POLICY-002', 'Active', 'Platform', policyAgent.Id, 'AC-002'
        );

        Commission_Record__c rec = buildCsvRow(
            'Carepoint', 100, 'POLICY-002', '2026-01', 'AC-002', rowAgent.Id
        );

        Test.startTest();
        try {
            insert rec;
            System.assert(false, 'Expected DmlException for Agent Mismatch');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('Agent Mismatch'),
                'Expected Agent Mismatch error, got: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    // ──────────────────────────────────────────────────────────────
    // TESTS 4b-4d: Agent_Mismatch on referral policies — Agent__c is the
    // AOR, Agent_Code__c is the selling agent's Contact.Agent_Code__c
    // ──────────────────────────────────────────────────────────────

    // Sets a known Agent_Code__c on the Contact and returns the stored value
    // (re-queried in case org automation normalises it).
    static String assignAgentCode(Contact agent, String agentCode) {
        agent.Agent_Code__c = agentCode;
        update agent;
        return [SELECT Agent_Code__c FROM Contact WHERE Id = :agent.Id].Agent_Code__c;
    }

    @IsTest
    static void testReferralRowPaidToSellingAgentSaves() {
        Account agency = createAgency('Agency Referral Selling Test');
        Contact aor = createAgent('AorAgent', 'NPN2001', agency.Id);
        Contact seller = createAgent('SellerAgent', 'NPN2002', agency.Id);
        String sellerCode = assignAgentCode(seller, 'REF-TEST-2002');

        createUplinePolicy('POLICY-REF-001', 'Active', 'Platform', aor.Id, sellerCode);

        Commission_Record__c rec = buildCsvRow(
            'Claro Insurance', 100, 'POLICY-REF-001', '2026-01', sellerCode, seller.Id
        );

        Test.startTest();
        insert rec; // should NOT throw — row agent is the policy's selling agent
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Commission_Record__c WHERE Id = :rec.Id],
            'Referral row paid to the selling agent should insert');
    }

    @IsTest
    static void testReferralRowPaidToAorSaves() {
        Account agency = createAgency('Agency Referral AOR Test');
        Contact aor = createAgent('AorAgent', 'NPN2003', agency.Id);
        Contact seller = createAgent('SellerAgent', 'NPN2004', agency.Id);
        String sellerCode = assignAgentCode(seller, 'REF-TEST-2004');

        createUplinePolicy('POLICY-REF-002', 'Active', 'Platform', aor.Id, sellerCode);

        Commission_Record__c rec = buildCsvRow(
            'Claro Insurance', 100, 'POLICY-REF-002', '2026-01', sellerCode, aor.Id
        );

        Test.startTest();
        insert rec; // should NOT throw — row agent is the policy's AOR (existing rule)
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Commission_Record__c WHERE Id = :rec.Id],
            'Referral row paid to the AOR should insert');
    }

    @IsTest
    static void testReferralRowPaidToUnrelatedAgentRejected() {
        Account agency = createAgency('Agency Referral Other Test');
        Contact aor = createAgent('AorAgent', 'NPN2005', agency.Id);
        Contact seller = createAgent('SellerAgent', 'NPN2006', agency.Id);
        Contact other = createAgent('OtherAgent', 'NPN2007', agency.Id);
        String sellerCode = assignAgentCode(seller, 'REF-TEST-2006');

        createUplinePolicy('POLICY-REF-003', 'Active', 'Platform', aor.Id, sellerCode);

        Commission_Record__c rec = buildCsvRow(
            'Claro Insurance', 100, 'POLICY-REF-003', '2026-01', sellerCode, other.Id
        );

        Test.startTest();
        try {
            insert rec;
            System.assert(false, 'Expected DmlException for Agent Mismatch');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('Agent Mismatch'),
                'Expected Agent Mismatch error, got: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    // ──────────────────────────────────────────────────────────────
    // TEST 5: Cancelled_Still_Paid — policy.Status__c = 'Cancelled'
    // ──────────────────────────────────────────────────────────────
    @IsTest
    static void testCancelledStillPaid() {
        Account agency = createAgency('Agency Cancelled Test');
        Contact agent = createAgent('CancelAgent', 'NPN1002', agency.Id);

        // ★ CHANGED: see note above re: 'Carrier' → 'Platform'
        Upline_Policy__c policy = createUplinePolicy(
            'POLICY-003', 'Cancelled', 'Platform', agent.Id, 'AC-003'
        );

        Commission_Record__c rec = buildCsvRow(
            'Carepoint', 100, 'POLICY-003', '2026-01', 'AC-003', agent.Id
        );

        Test.startTest();
        try {
            insert rec;
            System.assert(false, 'Expected DmlException for Cancelled Still Paid');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('Cancelled Still Paid'),
                'Expected Cancelled Still Paid error, got: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    // ──────────────────────────────────────────────────────────────
    // TEST 6: Underpaid — soft flag, row still saves (Platform source only)
    // ──────────────────────────────────────────────────────────────
    @IsTest
    static void testUnderpaidSoftFlagStillSaves() {
        Account agency = createAgency('Agency Underpaid Test');
        Contact agent = createAgent('UnderpaidAgent', 'NPN1003', agency.Id);

        // Upline_Source__c must literally be 'Platform' for this check to fire
        Upline_Policy__c policy = createUplinePolicy(
            'POLICY-004', 'Active', 'Platform', agent.Id, 'AC-004'
        );

        createEstimatedRecord('POLICY-004', '2026-01', 'AC-004', 100);

        Commission_Record__c rec = buildCsvRow(
            'Carepoint', 50, 'POLICY-004', '2026-01', 'AC-004', agent.Id // 50 < expected 100
        );

        Test.startTest();
        insert rec; // should NOT throw — soft flag only
        Test.stopTest();

        Commission_Record__c saved = [
            SELECT Id, Gross_Amount__c FROM Commission_Record__c WHERE Id = :rec.Id
        ];
        System.assertEquals(50, saved.Gross_Amount__c, 'Underpaid row should still save with actual amount');
    }

    // ──────────────────────────────────────────────────────────────
    // TEST 7: Overpaid — soft flag, row still saves (Platform source only)
    // ──────────────────────────────────────────────────────────────
    @IsTest
    static void testOverpaidSoftFlagStillSaves() {
        Account agency = createAgency('Agency Overpaid Test');
        Contact agent = createAgent('OverpaidAgent', 'NPN1004', agency.Id);

        Upline_Policy__c policy = createUplinePolicy(
            'POLICY-005', 'Active', 'Platform', agent.Id, 'AC-005'
        );

        createEstimatedRecord('POLICY-005', '2026-01', 'AC-005', 100);

        Commission_Record__c rec = buildCsvRow(
            'Carepoint', 150, 'POLICY-005', '2026-01', 'AC-005', agent.Id // 150 > expected 100
        );

        Test.startTest();
        insert rec; // should NOT throw — soft flag only
        Test.stopTest();

        Commission_Record__c saved = [
            SELECT Id, Gross_Amount__c FROM Commission_Record__c WHERE Id = :rec.Id
        ];
        System.assertEquals(150, saved.Gross_Amount__c, 'Overpaid row should still save with actual amount');
    }

    // ──────────────────────────────────────────────────────────────
    // TEST 8: Fully valid row — non-Platform source, no comparison at all
    // ──────────────────────────────────────────────────────────────
    @IsTest
    static void testFullyValidCsvRowSaves() {
        Account agency = createAgency('Agency Valid Test');
        Contact agent = createAgent('ValidAgent', 'NPN1005', agency.Id);

        // ★ CHANGED: 'Carrier' is not a valid value for the restricted
        // picklist Upline_Source__c — using 'Platform' (confirmed valid)
        // instead. Underpaid/Overpaid still won't fire here because no
        // matching Estimated Commission_Record__c is created in this test.
        Upline_Policy__c policy = createUplinePolicy(
            'POLICY-006', 'Active', 'Platform', agent.Id, 'AC-006'
        );

        Commission_Record__c rec = buildCsvRow(
            'Claro Insurance', 999, 'POLICY-006', '2026-01', 'AC-006', agent.Id
        );

        Test.startTest();
        insert rec; // should NOT throw
        Test.stopTest();

        Commission_Record__c saved = [SELECT Id FROM Commission_Record__c WHERE Id = :rec.Id];
        System.assertNotEquals(null, saved.Id, 'Fully valid CSV row should insert cleanly');
    }

    // ──────────────────────────────────────────────────────────────
    // TEST 9: Bulk — one invalid row blocks the whole insert (all-or-nothing)
    // ──────────────────────────────────────────────────────────────
    @IsTest
    static void testBulkInsertRollsBackOnAnyError() {
        Account agency = createAgency('Agency Bulk Test');
        Contact agent = createAgent('BulkAgent', 'NPN1006', agency.Id);

        // ★ CHANGED: see note above re: 'Carrier' → 'Platform'
        Upline_Policy__c policy = createUplinePolicy(
            'POLICY-007', 'Active', 'Platform', agent.Id, 'AC-007'
        );

        Commission_Record__c validRec = buildCsvRow(
            'Carepoint', 100, 'POLICY-007', '2026-01', 'AC-007', agent.Id // valid
        );
        Commission_Record__c invalidRec = buildCsvRow(
            'Carepoint', 100, 'DOES-NOT-EXIST', '2026-01', 'AC-999', agent.Id // Unknown Policy
        );

        Test.startTest();
        try {
            insert new List<Commission_Record__c>{ validRec, invalidRec };
            System.assert(false, 'Expected DmlException due to invalid row in the batch');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('Unknown Policy'),
                'Expected Unknown Policy error, got: ' + e.getMessage()
            );
        }
        Test.stopTest();

        // Because plain `insert list` is all-or-nothing, NEITHER row should
        // have been committed.
        List<Commission_Record__c> persisted = [
            SELECT Id FROM Commission_Record__c WHERE Policy_Number__c = 'POLICY-007'
        ];
        System.assertEquals(0, persisted.size(), 'All-or-nothing insert should have rolled back the valid row too');
    }
}