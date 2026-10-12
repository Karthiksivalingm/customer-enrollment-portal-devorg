@IsTest
private class BackfillLastShopifyOrderDateTest {

    // Tests for BackfillLastShopifyOrderDate: Last_Shopify_Order_Date__c is
    // set to the newest Shopify order on each account, cleared when the
    // account has no Shopify orders, and left alone when already correct.

    private static final Id COMPANY_RT = Schema.SObjectType.Account
        .getRecordTypeInfosByDeveloperName().get('Company').getRecordTypeId();
    private static final Id STORE_RT = Schema.SObjectType.Account
        .getRecordTypeInfosByDeveloperName().get('Store_Location').getRecordTypeId();

    private static final Date OLD_ORDER = Date.today().addMonths(-14);
    private static final Date NEW_ORDER = Date.today().addMonths(-2);

    @TestSetup
    static void setupData() {
        activatePricebook();

        Account company = new Account(
            Name                  = 'BLOD Company',
            RecordTypeId          = COMPANY_RT,
            Tax_Id__c             = '987654321',
            Shopify_Company_Id__c = 'BLODCOMPANY001',
            Sales_Channel__c      = 'Specialty'
        );
        insert company;

        insert new List<Account>{
            // Stale date (the old sync date) and two orders: newest must win
            store(company.Id, 'BLOD Store Orders', 'BLODSTORE001', Date.today()),
            // Date set but no Shopify orders: must be cleared
            store(company.Id, 'BLOD Store No Orders', 'BLODSTORE002', Date.today().addDays(-3)),
            // Already holds the right date: must be left as is
            store(company.Id, 'BLOD Store Correct', 'BLODSTORE003', NEW_ORDER)
        };

        Map<String, Id> ids = new Map<String, Id>();
        for (Account a : [SELECT Id, Name FROM Account WHERE Name LIKE 'BLOD Store%']) {
            ids.put(a.Name, a.Id);
        }

        insert new List<Order>{
            order(ids.get('BLOD Store Orders'),  OLD_ORDER, 'BLOD-001'),
            order(ids.get('BLOD Store Orders'),  NEW_ORDER, 'BLOD-002'),
            order(ids.get('BLOD Store Correct'), NEW_ORDER, 'BLOD-003')
        };
    }

    // ── Helpers ───────────────────────────────────────────────────

    private static Account store(Id companyId, String name, String shopifyId, Date lastOrder) {
        return new Account(
            Name                       = name,
            RecordTypeId               = STORE_RT,
            ParentId                   = companyId,
            Shopify_Company_Id__c      = shopifyId,
            Sales_Channel__c           = 'Specialty',
            Last_Shopify_Order_Date__c = lastOrder,
            ShippingStreet             = '123 Test St',
            ShippingCity               = 'Test City',
            ShippingPostalCode         = '12345',
            ShippingCountry            = 'US',
            Manual_Approval_Status__c  = 'Approved'
        );
    }

    private static Order order(Id accountId, Date effective, String num) {
        return new Order(
            AccountId               = accountId,
            Pricebook2Id            = Test.getStandardPricebookId(),
            EffectiveDate           = effective,
            Status                  = 'Draft',
            Name                    = num,
            Shopify_Order_Id__c     = 'gid://shopify/Order/' + num,
            Shopify_Order_Number__c = num,
            Shopify_Order_Amount__c = 100.00
        );
    }

    // Test classes running in parallel all update the standard price
    // book, so the row can be locked. Retry instead of failing the test.
    private static void activatePricebook() {
        for (Integer attempt = 1; ; attempt++) {
            try {
                update new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
                return;
            } catch (DmlException e) {
                if (attempt >= 3 || !e.getMessage().contains('UNABLE_TO_LOCK_ROW')) throw e;
            }
        }
    }

    private static Date lastOrderDate(String name) {
        return [SELECT Last_Shopify_Order_Date__c FROM Account WHERE Name = :name LIMIT 1]
            .Last_Shopify_Order_Date__c;
    }

    private static void runBatch() {
        Test.startTest();
        Database.executeBatch(new BackfillLastShopifyOrderDate(), 200);
        Test.stopTest();
    }

    // ── Tests ─────────────────────────────────────────────────────

    @IsTest
    static void setsNewestShopifyOrderDate() {
        runBatch();
        System.assertEquals(NEW_ORDER, lastOrderDate('BLOD Store Orders'),
            'Stale date replaced with the newest Shopify order date');
    }

    @IsTest
    static void clearsDateWhenNoShopifyOrders() {
        runBatch();
        System.assertEquals(null, lastOrderDate('BLOD Store No Orders'),
            'No Shopify orders, so the date is cleared');
    }

    @IsTest
    static void leavesCorrectDateUnchanged() {
        runBatch();
        System.assertEquals(NEW_ORDER, lastOrderDate('BLOD Store Correct'),
            'Already correct, so unchanged');
    }

    @IsTest
    static void ignoresOrdersWithoutShopifyId() {
        Id storeId = [SELECT Id FROM Account WHERE Name = 'BLOD Store No Orders' LIMIT 1].Id;
        insert new Order(
            AccountId     = storeId,
            Pricebook2Id  = Test.getStandardPricebookId(),
            EffectiveDate = Date.today().addDays(-1),
            Status        = 'Draft',
            Name          = 'BLOD-NON-SHOPIFY'
        );
        runBatch();
        System.assertEquals(null, lastOrderDate('BLOD Store No Orders'),
            'Orders without a Shopify Order Id do not count');
    }

    @IsTest
    static void schedulerStartsBatch() {
        Test.startTest();
        String jobId = System.schedule('BLOD schedule test', '0 0 21 ? * SUN',
                                       new BackfillLastShopifyOrderDate());
        Test.stopTest();
        System.assertEquals('0 0 21 ? * SUN',
            [SELECT CronExpression FROM CronTrigger WHERE Id = :jobId].CronExpression);
    }
}
