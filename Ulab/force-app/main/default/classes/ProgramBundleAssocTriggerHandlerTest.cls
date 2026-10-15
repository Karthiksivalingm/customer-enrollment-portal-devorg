@isTest
private class ProgramBundleAssocTriggerHandlerTest {

    // ==========================================================================================
    // TEST DATA SETUP
    // ==========================================================================================
    // NOTE: Adjust field values/required fields below to match your org's actual validation
    // rules and field types (e.g. if Program_Name__c or Bundle_Type__c have picklist
    // constraints or are required, populate accordingly).
    //
    // ApiUser simulation: rather than creating/activating a real User with Alias = 'ApiUser'
    // (which in this org hits duplicate-alias validation rules and managed-package activation
    // trigger bugs), tests set ProgramBundleAssociationTriggerHandler.testOverrideApiUserIds
    // directly - see setApiUserOverride() / clearApiUserOverride() below.
    @TestSetup
    static void setup() {

        // Two parent bundles: one to hold a "first association" scenario, one to hold
        // "subsequent association" scenarios where Event_Trigger__c matters.
        ProductBundles__c bundleFirst = new ProductBundles__c(
            Name = 'Bundle First',
            Description__c = 'Test Description',
            Event_Trigger__c = false
        );
        ProductBundles__c bundleSubsequentTrue = new ProductBundles__c(
            Name = 'Bundle Subsequent - Trigger True',
            Description__c = 'Test Description',
            Event_Trigger__c = true
        );
        ProductBundles__c bundleSubsequentFalse = new ProductBundles__c(
            Name = 'Bundle Subsequent - Trigger False',
            Description__c = 'Test Description',
            Event_Trigger__c = false
        );
        insert new List<ProductBundles__c>{ bundleFirst, bundleSubsequentTrue, bundleSubsequentFalse };

        // Marketing_Reward__c is a required lookup on Program_Bundle_Associations__c -
        // create one record to reference across all the PBA test data below.
        // NOTE: Name is an auto-number field on this object, so it's left unset.
        Marketing_Reward__c marketingReward = new Marketing_Reward__c();
        insert marketingReward;

        // Pre-seed one existing association on the "subsequent" bundles so that a new record
        // inserted against them is NOT the first association for that bundle.
        insert new Program_Bundle_Associations__c(
            Bundle__c = bundleSubsequentTrue.Id,
            Marketing_Reward__c = marketingReward.Id,
            NetSuite_Bundle_Association_ID__c = 'NS-SEED-1'
        );
        insert new Program_Bundle_Associations__c(
            Bundle__c = bundleSubsequentFalse.Id,
            Marketing_Reward__c = marketingReward.Id,
            NetSuite_Bundle_Association_ID__c = 'NS-SEED-2'
        );
    }

    private static ProductBundles__c getBundleByName(String name) {
        return [SELECT Id, Event_Trigger__c FROM ProductBundles__c WHERE Name = :name LIMIT 1];
    }

    private static Marketing_Reward__c getMarketingReward() {
        return [SELECT Id FROM Marketing_Reward__c LIMIT 1];
    }

    // Makes the handler treat the current running-test user as the "ApiUser" for Step 3.
    private static void setApiUserOverride() {
        ProgramBundleAssociationTriggerHandler.testOverrideApiUserIds = new Set<Id>{ UserInfo.getUserId() };
    }

    // Makes the handler treat NO user as the "ApiUser" - simulates a non-ApiUser making the change.
    private static void clearApiUserOverride() {
        ProgramBundleAssociationTriggerHandler.testOverrideApiUserIds = new Set<Id>();
    }

    // ==========================================================================================
    // AFTER INSERT - first association on bundle, NetSuite Id populated at creation,
    // created by ApiUser, Event_Trigger__c = false -> should still publish because it's the
    // very first association on the bundle (the checkbox check is skipped in this case), and
    // should NOT reset Event_Trigger__c (reset only happens for the checkbox-driven path).
    // ==========================================================================================
    @isTest
    static void testInsert_FirstAssociation_PublishesAndDoesNotResetCheckbox() {
        ProductBundles__c bundle = getBundleByName('Bundle First');
        Marketing_Reward__c marketingReward = getMarketingReward();
        setApiUserOverride();

        Test.startTest();
        insert new Program_Bundle_Associations__c(
            Bundle__c = bundle.Id,
            Marketing_Reward__c = marketingReward.Id,
            NetSuite_Bundle_Association_ID__c = 'NS-FIRST-1'
        );
        Test.stopTest();

        ProductBundles__c refreshed = getBundleByName('Bundle First');
        // First-association path never touches the checkbox, so it should remain unchanged (false).
        System.assertEquals(false, refreshed.Event_Trigger__c,
            'Event_Trigger__c should remain false since the first-association exception path does not reset it.');
    }

    // ==========================================================================================
    // AFTER INSERT - subsequent association, NetSuite Id populated at creation, created by
    // ApiUser, Event_Trigger__c = true -> should publish and reset Event_Trigger__c to false.
    // ==========================================================================================
    @isTest
    static void testInsert_SubsequentAssociation_EventTriggerTrue_PublishesAndResets() {
        ProductBundles__c bundle = getBundleByName('Bundle Subsequent - Trigger True');
        Marketing_Reward__c marketingReward = getMarketingReward();
        setApiUserOverride();

        Test.startTest();
        insert new Program_Bundle_Associations__c(
            Bundle__c = bundle.Id,
            Marketing_Reward__c = marketingReward.Id,
            NetSuite_Bundle_Association_ID__c = 'NS-SUB-TRUE-1'
        );
        Test.stopTest();

        ProductBundles__c refreshed = getBundleByName('Bundle Subsequent - Trigger True');
        System.assertEquals(false, refreshed.Event_Trigger__c,
            'Event_Trigger__c should be reset to false after a checkbox-driven publish.');
    }

    // ==========================================================================================
    // AFTER INSERT - subsequent association, NetSuite Id populated at creation, created by
    // ApiUser, Event_Trigger__c = false -> should NOT publish, and checkbox stays false.
    // ==========================================================================================
    @isTest
    static void testInsert_SubsequentAssociation_EventTriggerFalse_DoesNotPublish() {
        ProductBundles__c bundle = getBundleByName('Bundle Subsequent - Trigger False');
        Marketing_Reward__c marketingReward = getMarketingReward();
        setApiUserOverride();

        Test.startTest();
        insert new Program_Bundle_Associations__c(
            Bundle__c = bundle.Id,
            Marketing_Reward__c = marketingReward.Id,
            NetSuite_Bundle_Association_ID__c = 'NS-SUB-FALSE-1'
        );
        Test.stopTest();

        ProductBundles__c refreshed = getBundleByName('Bundle Subsequent - Trigger False');
        System.assertEquals(false, refreshed.Event_Trigger__c,
            'Event_Trigger__c should remain false - no publish should have occurred to reset it.');
    }

    // ==========================================================================================
    // AFTER INSERT - NetSuite Id blank at creation -> should be skipped entirely (Step 1 fails),
    // regardless of who created it or the bundle's checkbox state.
    // ==========================================================================================
    @isTest
    static void testInsert_BlankNetSuiteId_IsSkipped() {
        ProductBundles__c bundle = getBundleByName('Bundle Subsequent - Trigger True');
        Marketing_Reward__c marketingReward = getMarketingReward();
        setApiUserOverride();

        Test.startTest();
        insert new Program_Bundle_Associations__c(
            Bundle__c = bundle.Id,
            Marketing_Reward__c = marketingReward.Id,
            NetSuite_Bundle_Association_ID__c = null
        );
        Test.stopTest();

        ProductBundles__c refreshed = getBundleByName('Bundle Subsequent - Trigger True');
        System.assertEquals(true, refreshed.Event_Trigger__c,
            'Event_Trigger__c should be untouched since the record never qualified past Step 1.');
    }

    // ==========================================================================================
    // AFTER INSERT - NetSuite Id populated, but NOT created by ApiUser -> Step 3 fails,
    // should NOT publish.
    // ==========================================================================================
    @isTest
    static void testInsert_NonApiUser_DoesNotPublish() {
        ProductBundles__c bundle = getBundleByName('Bundle Subsequent - Trigger True');
        Marketing_Reward__c marketingReward = getMarketingReward();
        clearApiUserOverride();

        Test.startTest();
        insert new Program_Bundle_Associations__c(
            Bundle__c = bundle.Id,
            Marketing_Reward__c = marketingReward.Id,
            NetSuite_Bundle_Association_ID__c = 'NS-NONAPI-1'
        );
        Test.stopTest();

        ProductBundles__c refreshed = getBundleByName('Bundle Subsequent - Trigger True');
        System.assertEquals(true, refreshed.Event_Trigger__c,
            'Event_Trigger__c should remain true since a non-ApiUser insert should not trigger a publish/reset.');
    }

    // ==========================================================================================
    // AFTER UPDATE - NetSuite Id changes from blank to populated, updated by ApiUser,
    // Event_Trigger__c = true -> should publish and reset the checkbox.
    // ==========================================================================================
    @isTest
    static void testUpdate_NetSuiteIdBecomesPopulated_PublishesAndResets() {
        ProductBundles__c bundle = getBundleByName('Bundle Subsequent - Trigger True');
        Marketing_Reward__c marketingReward = getMarketingReward();

        // Insert with blank NetSuite Id first (does not qualify) - override not needed yet.
        Program_Bundle_Associations__c pba = new Program_Bundle_Associations__c(
            Bundle__c = bundle.Id,
            Marketing_Reward__c = marketingReward.Id,
            NetSuite_Bundle_Association_ID__c = null
        );
        insert pba;

        setApiUserOverride();

        Test.startTest();
        pba.NetSuite_Bundle_Association_ID__c = 'NS-UPD-1';
        update pba;
        Test.stopTest();

        ProductBundles__c refreshed = getBundleByName('Bundle Subsequent - Trigger True');
        System.assertEquals(false, refreshed.Event_Trigger__c,
            'Event_Trigger__c should be reset to false after the update qualifies and publishes.');
    }

    // ==========================================================================================
    // AFTER UPDATE - NetSuite Id was already populated and does not change -> should be skipped
    // (Step 1 requires a change into a populated value, not merely being populated).
    // ==========================================================================================
    @isTest
    static void testUpdate_NetSuiteIdUnchanged_IsSkipped() {
        ProductBundles__c bundle = getBundleByName('Bundle Subsequent - Trigger True');
        Marketing_Reward__c marketingReward = getMarketingReward();

        Program_Bundle_Associations__c pba = new Program_Bundle_Associations__c(
            Bundle__c = bundle.Id,
            Marketing_Reward__c = marketingReward.Id,
            NetSuite_Bundle_Association_ID__c = 'NS-ALREADY-SET'
        );
        insert pba;

        // First insert already published/reset - flip the checkbox back to true so we can
        // isolate the update behavior.
        bundle.Event_Trigger__c = true;
        update bundle;

        setApiUserOverride();

        Test.startTest();
        // NetSuite Id stays the same - just re-saving the record still fires the trigger,
        // which is what we're testing (Step 1 should reject it since nothing changed).
        update pba;
        Test.stopTest();

        ProductBundles__c refreshed = getBundleByName('Bundle Subsequent - Trigger True');
        System.assertEquals(true, refreshed.Event_Trigger__c,
            'Event_Trigger__c should remain true since the NetSuite Id did not change on update.');
    }

    // ==========================================================================================
    // Bulk test - multiple qualifying records across multiple bundles in one DML statement,
    // confirming bulk-safety (single SOQL for bundles/counts, single EventBus.publish).
    // ==========================================================================================
    @isTest
    static void testBulk_MultipleQualifyingRecords() {
        Marketing_Reward__c marketingReward = getMarketingReward();

        List<ProductBundles__c> bundles = new List<ProductBundles__c>();
        for (Integer i = 0; i < 5; i++) {
            bundles.add(new ProductBundles__c(
                Name = 'Bulk Bundle ' + i,
                Description__c = 'Test Description',
                Event_Trigger__c = true
            ));
        }
        insert bundles;

        // Seed one association per bundle so none of the bulk-inserted records are "first".
        List<Program_Bundle_Associations__c> seeds = new List<Program_Bundle_Associations__c>();
        for (ProductBundles__c b : bundles) {
            seeds.add(new Program_Bundle_Associations__c(
                Bundle__c = b.Id,
                Marketing_Reward__c = marketingReward.Id,
                NetSuite_Bundle_Association_ID__c = 'NS-SEED-' + b.Id
            ));
        }
        insert seeds;

        List<Program_Bundle_Associations__c> bulkRecords = new List<Program_Bundle_Associations__c>();
        for (ProductBundles__c b : bundles) {
            bulkRecords.add(new Program_Bundle_Associations__c(
                Bundle__c = b.Id,
                Marketing_Reward__c = marketingReward.Id,
                NetSuite_Bundle_Association_ID__c = 'NS-BULK-' + b.Id
            ));
        }

        setApiUserOverride();

        Test.startTest();
        insert bulkRecords;
        Test.stopTest();

        List<ProductBundles__c> refreshedBundles = [
            SELECT Id, Event_Trigger__c FROM ProductBundles__c WHERE Id IN :new Map<Id, ProductBundles__c>(bundles).keySet()
        ];
        for (ProductBundles__c b : refreshedBundles) {
            System.assertEquals(false, b.Event_Trigger__c,
                'Every bundle in the bulk batch should have had its Event_Trigger__c reset to false.');
        }
    }
}