/**
 * UplinePolicyTriggerHandler_Test
 * ------------------------------------------------------------------
 * Tests UplinePolicyTriggerHandler.beforeInsert().
 *
 * UplinePolicyTrigger:
 *   - before insert  -> UplinePolicyTriggerHandler.beforeInsert()
 *   - after insert   -> UplinePolicyToCommissionHandler.afterInsert()
 *   - after update   -> UplinePolicyToCommissionHandler.afterUpdate()
 *
 * Test assumptions:
 *   - Policy_Year__c is a Number field.
 *   - Reactivated_From__c is a self-lookup to Upline_Policy__c.
 *   - Upline_Source__c = 'Manual' is a valid value.
 *   - Status__c can be blank.
 *   - Manual + blank Status__c produces Source_Type__c = 'Manual'.
 *
 * IMPORTANT:
 *   This test runs as the normal test user, NOT the GO AMS API user.
 *   Therefore UplinePolicyToCommissionHandler does NOT publish the
 *   Upline_Policy_Created__e event and no Commission_Record__c is
 *   expected to be created.
 */
@IsTest
private class UplinePolicyTriggerHandler_Test {

    private static Id agencyId;
    private static Id agentId;
    private static Id carrierId;

    // ============================================================
    // TEST DATA
    // ============================================================

    @TestSetup
    static void setupData() {

        Account agency = new Account(
            Name = 'Upline Trigger Test Agency'
        );
        insert agency;

        Contact agent = new Contact(
            LastName = 'Upline Trigger Test Agent',
            AccountId = agency.Id,
            Email = 'uplinetriggertest@test.com',
            NPN__c = '1234567890',
            Agent_Status__c = 'Onboarding',
            Bypass_VR__c = true
        );
        insert agent;

        Carrier__c carrier = new Carrier__c(
            Name = 'Upline Trigger Test Carrier',
            Supported_Lines_of_Business__c = 'Medicare',
            Supports_Medicare__c = true
        );
        insert carrier;
    }

    // ============================================================
    // LOAD TEST IDS
    // ============================================================

    private static void loadIds() {

        if (agencyId != null) {
            return;
        }

        agencyId = [
            SELECT Id
            FROM Account
            WHERE Name = 'Upline Trigger Test Agency'
            LIMIT 1
        ].Id;

        agentId = [
            SELECT Id
            FROM Contact
            WHERE Email = 'uplinetriggertest@test.com'
            LIMIT 1
        ].Id;

        carrierId = [
            SELECT Id
            FROM Carrier__c
            WHERE Name = 'Upline Trigger Test Carrier'
            LIMIT 1
        ].Id;
    }

    // ============================================================
    // BUILD UPLINE POLICY
    // ============================================================

    private static Upline_Policy__c buildPolicy(
        String policyNumber,
        Decimal policyYear,
        Id reactivatedFromId
    ) {

        loadIds();

        return new Upline_Policy__c(
            Agent_Code__c = 'AGT-001',
            Agent__c = agentId,
            Agency__c = agencyId,
            Carrier__c = carrierId,
            Policy_Number__c = policyNumber,
            Effective_Date__c = Date.today(),
            Premium__c = 250.00,
            Policy_Year__c = policyYear,
            MBI__c = '12345678901',
            Upline_Source__c = 'Manual',
            Status__c = null,
            Reactivated_From__c = reactivatedFromId
        );
    }

    // ============================================================
    // TEST 1
    // ============================================================
    @IsTest
    static void testNoReactivationLeavesPolicyYearUnchanged() {

        Upline_Policy__c p = buildPolicy(
            'POLICY-100',
            1,
            null
        );

        Test.startTest();

        insert p;

        Test.stopTest();

        Upline_Policy__c saved = [
            SELECT Id,
                   Policy_Year__c,
                   Upline_Source__c,
                   Status__c,
                   Reactivated_From__c
            FROM Upline_Policy__c
            WHERE Id = :p.Id
        ];

        System.assertEquals(
            1,
            saved.Policy_Year__c,
            'Policy_Year__c should remain unchanged when Reactivated_From__c is blank.'
        );

        System.assertEquals(
            'Manual',
            saved.Upline_Source__c,
            'Upline_Source__c should be Manual.'
        );

        System.assertEquals(
            null,
            saved.Reactivated_From__c,
            'Reactivated_From__c should be blank.'
        );

        // Non-API user should NOT create a Commission Record.
        Integer commissionCount = [
            SELECT COUNT()
            FROM Commission_Record__c
            WHERE Upline_Policy__c = :p.Id
        ];

        System.assertEquals(
            0,
            commissionCount,
            'No Commission Record should be created for a non-API-user insert.'
        );

        // Verify Import Log
        List<Commission_Import_Log__c> logs = [
            SELECT Id,
                   Source_Type__c,
                   Processing_Status__c,
                   Records_Created__c,
                   Records_Updated__c
            FROM Commission_Import_Log__c
            WHERE Source_Type__c = 'Manual'
            AND Records_Created__c = 1
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(
            1,
            logs.size(),
            'One Manual Import Log should be created.'
        );

        System.assertEquals(
            'Manual',
            logs[0].Source_Type__c
        );

        System.assertEquals(
            'Completed',
            logs[0].Processing_Status__c
        );

        System.assertEquals(
            1,
            logs[0].Records_Created__c
        );

        System.assertEquals(
            0,
            logs[0].Records_Updated__c
        );
    }

    // ============================================================
    // TEST 2
    // ============================================================
    @IsTest
    static void testReactivationInheritsPolicyYear() {

        Upline_Policy__c source = buildPolicy(
            'POLICY-101',
            5,
            null
        );

        insert source;

        Upline_Policy__c reactivated = buildPolicy(
            'POLICY-101-R',
            0,
            source.Id
        );

        Test.startTest();

        insert reactivated;

        Test.stopTest();

        Upline_Policy__c saved = [
            SELECT Id,
                   Policy_Year__c,
                   Reactivated_From__c,
                   Upline_Source__c
            FROM Upline_Policy__c
            WHERE Id = :reactivated.Id
        ];

        System.assertEquals(
            5,
            saved.Policy_Year__c,
            'Policy_Year__c should be inherited from the source policy.'
        );

        System.assertEquals(
            source.Id,
            saved.Reactivated_From__c,
            'Reactivated_From__c should continue pointing to the source policy.'
        );

        System.assertEquals(
            'Manual',
            saved.Upline_Source__c,
            'Upline_Source__c should be Manual.'
        );

        // Non-API user should NOT create a Commission Record.
        Integer commissionCount = [
            SELECT COUNT()
            FROM Commission_Record__c
            WHERE Upline_Policy__c = :reactivated.Id
        ];

        System.assertEquals(
            0,
            commissionCount,
            'No Commission Record should be created for a non-API-user insert.'
        );
    }

    // ============================================================
    // TEST 3
    // ============================================================
    @IsTest
    static void testBulkMixedReactivation() {

        Upline_Policy__c source1 = buildPolicy(
            'POLICY-103',
            3,
            null
        );

        Upline_Policy__c source2 = buildPolicy(
            'POLICY-104',
            8,
            null
        );

        insert new List<Upline_Policy__c>{
            source1,
            source2
        };

        Upline_Policy__c reactivated1 = buildPolicy(
            'POLICY-103-R',
            0,
            source1.Id
        );

        Upline_Policy__c reactivated2 = buildPolicy(
            'POLICY-104-R',
            0,
            source2.Id
        );

        Upline_Policy__c freshPolicy = buildPolicy(
            'POLICY-105',
            1,
            null
        );

        Test.startTest();

        insert new List<Upline_Policy__c>{
            reactivated1,
            reactivated2,
            freshPolicy
        };

        Test.stopTest();

        Map<Id, Upline_Policy__c> savedById =
            new Map<Id, Upline_Policy__c>([
                SELECT Id,
                       Policy_Number__c,
                       Policy_Year__c,
                       Reactivated_From__c,
                       Upline_Source__c
                FROM Upline_Policy__c
                WHERE Id IN :new List<Id>{
                    reactivated1.Id,
                    reactivated2.Id,
                    freshPolicy.Id
                }
            ]);

        // Verify first reactivated policy
        System.assertEquals(
            3,
            savedById.get(reactivated1.Id).Policy_Year__c,
            'First reactivated policy should inherit Policy_Year__c = 3.'
        );

        System.assertEquals(
            source1.Id,
            savedById.get(reactivated1.Id).Reactivated_From__c
        );

        // Verify second reactivated policy
        System.assertEquals(
            8,
            savedById.get(reactivated2.Id).Policy_Year__c,
            'Second reactivated policy should inherit Policy_Year__c = 8.'
        );

        System.assertEquals(
            source2.Id,
            savedById.get(reactivated2.Id).Reactivated_From__c
        );

        // Verify fresh policy
        System.assertEquals(
            1,
            savedById.get(freshPolicy.Id).Policy_Year__c,
            'Fresh policy should retain its own Policy_Year__c.'
        );

        System.assertEquals(
            null,
            savedById.get(freshPolicy.Id).Reactivated_From__c,
            'Fresh policy should not have Reactivated_From__c.'
        );

        // Non-API user should NOT create Commission Records.
        Integer commissionCount = [
            SELECT COUNT()
            FROM Commission_Record__c
            WHERE Upline_Policy__c IN :new List<Id>{
                reactivated1.Id,
                reactivated2.Id,
                freshPolicy.Id
            }
        ];

        System.assertEquals(
            0,
            commissionCount,
            'No Commission Records should be created for a non-API-user bulk insert.'
        );
    }

    // ============================================================
    // TEST 4
    // ============================================================
    @IsTest
    static void testUpdateDoesNotTriggerReactivationLogic() {

        Upline_Policy__c source = buildPolicy(
            'POLICY-106',
            9,
            null
        );

        insert source;

        Upline_Policy__c standalone = buildPolicy(
            'POLICY-107',
            4,
            null
        );

        insert standalone;

        standalone.Reactivated_From__c = source.Id;

        Test.startTest();

        update standalone;

        Test.stopTest();

        Upline_Policy__c saved = [
            SELECT Id,
                   Policy_Year__c,
                   Reactivated_From__c,
                   Upline_Source__c
            FROM Upline_Policy__c
            WHERE Id = :standalone.Id
        ];

        System.assertEquals(
            4,
            saved.Policy_Year__c,
            'Policy_Year__c should remain 4 because beforeInsert does not run during update.'
        );

        System.assertEquals(
            source.Id,
            saved.Reactivated_From__c,
            'Reactivated_From__c should be updated to the source policy.'
        );

        System.assertEquals(
            'Manual',
            saved.Upline_Source__c
        );

        // No Commission Record should exist because this is a non-API user.
        Integer commissionCount = [
            SELECT COUNT()
            FROM Commission_Record__c
            WHERE Upline_Policy__c = :standalone.Id
        ];

        System.assertEquals(
            0,
            commissionCount,
            'No Commission Record should be created for a non-API-user insert or update.'
        );

        // Verify update Import Log
        List<Commission_Import_Log__c> updateLogs = [
            SELECT Id,
                   Source_Type__c,
                   Processing_Status__c,
                   Records_Created__c,
                   Records_Updated__c
            FROM Commission_Import_Log__c
            WHERE Source_Type__c = 'Manual'
            AND Records_Updated__c = 1
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(
            1,
            updateLogs.size(),
            'An Import Log should be created by afterUpdate.'
        );

        System.assertEquals(
            'Manual',
            updateLogs[0].Source_Type__c,
            'Source_Type__c must be the exact valid picklist value Manual.'
        );

        System.assertEquals(
            'Completed',
            updateLogs[0].Processing_Status__c
        );

        System.assertEquals(
            0,
            updateLogs[0].Records_Created__c
        );

        System.assertEquals(
            1,
            updateLogs[0].Records_Updated__c
        );
    }
}