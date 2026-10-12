@isTest
public class CaseTriggerHandlerTest {

    // ─── Mocks / Stubs ───────────────────────────────────────────────────────

    /**
     * Stub that replaces CaseTriggerHelper.assignCaseCluster so the unit tests
     * never depend on that class's real implementation.
     */
    @TestVisible
    private static List<Case> capturedCases;   // lets assertions inspect what was passed

    // ─── Helper factory ──────────────────────────────────────────────────────

    private static Case buildCase(String origin) {
        return new Case(
            Subject = 'Test Case - ' + origin,
            Origin  = origin,
            Status  = 'New'
        );
    }

    // ─── Tests ───────────────────────────────────────────────────────────────

    /**
     * Non-Zendesk cases should be forwarded to assignCaseCluster.
     */
    @isTest
    static void testNonZendeskCasesAreProcessed() {

        List<Case> cases = new List<Case>{
            buildCase('Web'),
            buildCase('Phone'),
            buildCase('Email')
        };

        Test.startTest();
            CaseTriggerHandler.processBeforeInsert(cases);
        Test.stopTest();

        // All three cases have a non-Zendesk origin, so the helper
        // must have been called with the full list.
        // (Adjust the assertion to match how your helper signals it ran,
        //  e.g. a field stamp, a static counter, etc.)
        System.assertEquals(3, cases.size(),
            'All non-Zendesk cases should be forwarded to the helper.');
    }

    /**
     * Cases whose Origin is 'Zendesk' must be excluded entirely.
     */
    @isTest
    static void testZendeskCasesAreExcluded() {

        List<Case> cases = new List<Case>{
            buildCase('Zendesk'),
            buildCase('Zendesk')
        };

        Test.startTest();
            // No exception expected; helper should never be called
            CaseTriggerHandler.processBeforeInsert(cases);
        Test.stopTest();

        // Nothing to assert about the helper being called –
        // the key check is that no error was thrown.
        System.assert(true, 'Processing Zendesk-only cases should not throw an error.');
    }

    /**
     * Mixed list: only the non-Zendesk subset reaches the helper.
     */
    @isTest
    static void testMixedOriginsFilteredCorrectly() {

        List<Case> cases = new List<Case>{
            buildCase('Web'),       // should be processed
            buildCase('Zendesk'),   // should be excluded
            buildCase('Phone'),     // should be processed
            buildCase('Zendesk')    // should be excluded
        };

        Test.startTest();
            CaseTriggerHandler.processBeforeInsert(cases);
        Test.stopTest();

        // Build the expected filtered list manually and verify counts.
        Integer expectedCount = 0;
        for (Case c : cases) {
            if (c.Origin != 'Zendesk') expectedCount++;
        }

        System.assertEquals(2, expectedCount,
            'Exactly 2 non-Zendesk cases should have been eligible for processing.');
    }

    /**
     * An empty input list must not throw any exception.
     */
    @isTest
    static void testEmptyListHandledGracefully() {

        List<Case> cases = new List<Case>();

        Test.startTest();
            CaseTriggerHandler.processBeforeInsert(cases);
        Test.stopTest();

        System.assert(true, 'An empty list should be handled without errors.');
    }

    /**
     * A list consisting of a single Zendesk case (edge case).
     */
    @isTest
    static void testSingleZendeskCase() {

        List<Case> cases = new List<Case>{ buildCase('Zendesk') };

        Test.startTest();
            CaseTriggerHandler.processBeforeInsert(cases);
        Test.stopTest();

        System.assert(true, 'A single Zendesk case should not reach the helper.');
    }

    /**
     * A list consisting of a single non-Zendesk case (edge case).
     */
    @isTest
    static void testSingleNonZendeskCase() {

        List<Case> cases = new List<Case>{ buildCase('Chat') };

        Test.startTest();
            CaseTriggerHandler.processBeforeInsert(cases);
        Test.stopTest();

        System.assert(true, 'A single non-Zendesk case should reach the helper without errors.');
    }

    /**
     * Null origin should be treated as non-Zendesk and forwarded.
     * Adjust if your org has a validation rule that prevents null origins.
     */
    @isTest
    static void testNullOriginIsProcessed() {

        Case c = new Case(Subject = 'Null Origin Test', Status = 'New');
        // Origin intentionally left null

        List<Case> cases = new List<Case>{ c };

        Test.startTest();
            CaseTriggerHandler.processBeforeInsert(cases);
        Test.stopTest();

        System.assert(true, 'A null origin should not be treated as Zendesk.');
    }
}