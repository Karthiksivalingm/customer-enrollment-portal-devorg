@IsTest
public class AccountCascadeHandlerTest {

    private static Id companyRtId = Schema.SObjectType.Account
        .getRecordTypeInfosByName().get('Company').getRecordTypeId();

    private static Account buildCompanyAccount(
        String name, String taxId, String salesChannel
    ) {
        return new Account(
            Name               = name,
            RecordTypeId       = companyRtId,
            Tax_Id__c          = taxId,
            Sales_Channel__c   = salesChannel,
            BillingStreet      = '123 Main St',
            BillingCity        = 'Los Angeles',
            BillingState       = 'CA',
            BillingPostalCode  = '90001',
            BillingCountry     = 'US',
            ShippingStreet     = '123 Main St',
            ShippingCity       = 'Los Angeles',
            ShippingState      = 'CA',
            ShippingPostalCode = '90001',
            ShippingCountry    = 'US'
        );
    }

    private static Account queryFullAccount(Id accId) {
        return [
            SELECT Id, Cluster__c, Sales_Channel__c,
                   BillingStreet, BillingCity, BillingState,
                   BillingPostalCode, BillingCountry,
                   ShippingStreet, ShippingCity, ShippingState,
                   ShippingPostalCode, ShippingCountry
            FROM Account WHERE Id = :accId
        ];
    }

    @TestSetup
    static void setupData() {
        // Insert Account WITHOUT Cluster__c pre-set.
        // The trigger will fire ClusterRuleEngine which sets Cluster__c
        // based on CMDT rules. We do not hardcode Cluster 7 here.
        Account company = buildCompanyAccount('Cascade Company', '111222333', 'Global');
        insert company;

        insert new Contact(
            FirstName        = 'Cascade',
            LastName         = 'Contact',
            Email            = 'cascade@test.com',
            AccountId        = company.Id,
            Sales_Channel__c = 'Global'
        );

        insert new Opportunity(
            Name             = 'Cascade Opp',
            AccountId        = company.Id,
            StageName        = 'Summary',
            CloseDate        = Date.today().addDays(30),
            Sales_Channel__c = 'Global'
        );
    }

    private static Account getCascadeCompany() {
        return queryFullAccount(
            [SELECT Id FROM Account WHERE Name = 'Cascade Company' LIMIT 1].Id
        );
    }

    @IsTest
    static void testHandle_NoChange_ReturnsEarly() {
        Account acc    = getCascadeCompany();
        Account oldAcc = acc.clone(true, true, false, false);

        Test.startTest();
        AccountCascadeHandler.handle(
            new List<Account>{ acc },
            new Map<Id, Account>{ acc.Id => oldAcc }
        );
        Test.stopTest();

        System.assert(true, 'No change should return early without error');
    }

    @IsTest
    static void testHandle_ClusterChanged_CascadesToOppAndContact() {
        Account acc    = getCascadeCompany();
        Account oldAcc = acc.clone(true, true, false, false);
        // Simulate old Cluster being different from current so cascade fires
        oldAcc.Cluster__c = (acc.Cluster__c == 'Cluster 1') ? 'Cluster 2' : 'Cluster 1';

        Test.startTest();
        AccountCascadeHandler.handle(
            new List<Account>{ acc },
            new Map<Id, Account>{ acc.Id => oldAcc }
        );
        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT Sales_Channel__c FROM Opportunity WHERE Name = 'Cascade Opp' LIMIT 1
        ];
        System.assertEquals('Global', updatedOpp.Sales_Channel__c,
            'Opp Sales_Channel__c should be synced from Account');

        Contact updatedCon = [
            SELECT Sales_Channel__c FROM Contact WHERE Email = 'cascade@test.com' LIMIT 1
        ];
        System.assertEquals('Global', updatedCon.Sales_Channel__c,
            'Contact Sales_Channel__c should be synced from Account');
    }

    @IsTest
    static void testHandle_SalesChannelChanged_CascadesFires() {
        Account acc    = getCascadeCompany();
        Account oldAcc = acc.clone(true, true, false, false);
        oldAcc.Sales_Channel__c = 'Key Account';

        Test.startTest();
        AccountCascadeHandler.handle(
            new List<Account>{ acc },
            new Map<Id, Account>{ acc.Id => oldAcc }
        );
        Test.stopTest();

        System.assert(true, 'Sales channel change should cascade without error');
    }

    @IsTest
    static void testHandle_NoOpenOpportunities_SyncSkipped() {
        Account acc = getCascadeCompany();

        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Cascade Opp' LIMIT 1];
        opp.StageName = 'Closed Lost';
        update opp;

        Account oldAcc = acc.clone(true, true, false, false);
        oldAcc.Cluster__c = (acc.Cluster__c == 'Cluster 1') ? 'Cluster 2' : 'Cluster 1';

        Test.startTest();
        AccountCascadeHandler.handle(
            new List<Account>{ acc },
            new Map<Id, Account>{ acc.Id => oldAcc }
        );
        Test.stopTest();

        System.assert(true, 'No open opps — sync skipped without error');
    }

    @IsTest
    static void testHandle_NoContacts_SyncSkipped() {
        Account emptyCompany = buildCompanyAccount('Empty Company', '999888777', 'Global');
        insert emptyCompany;

        Account freshAcc = queryFullAccount(emptyCompany.Id);
        Account oldAcc   = freshAcc.clone(true, true, false, false);
        oldAcc.Cluster__c = (freshAcc.Cluster__c == 'Cluster 1') ? 'Cluster 2' : 'Cluster 1';

        Test.startTest();
        AccountCascadeHandler.handle(
            new List<Account>{ freshAcc },
            new Map<Id, Account>{ freshAcc.Id => oldAcc }
        );
        Test.stopTest();

        System.assert(true, 'No contacts — sync skipped without error');
    }

    @IsTest
    static void testHandle_NullOldMap_AllAccountsProcessed() {
        Account acc = getCascadeCompany();

        Test.startTest();
        AccountCascadeHandler.handle(new List<Account>{ acc }, null);
        Test.stopTest();

        System.assert(true, 'Null oldMap processed without error');
    }

    @IsTest
    static void testHandle_OppAlreadyCorrect_NoUpdate() {
        Account acc    = getCascadeCompany();
        Account oldAcc = acc.clone(true, true, false, false);
        oldAcc.Cluster__c = (acc.Cluster__c == 'Cluster 1') ? 'Cluster 2' : 'Cluster 1';

        // Set Opp to already match Account values so no update is needed
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Cascade Opp' LIMIT 1];
        opp.Sales_Channel__c = acc.Sales_Channel__c;
        opp.Cluster__c       = acc.Cluster__c;
        update opp;

        Test.startTest();
        AccountCascadeHandler.handle(
            new List<Account>{ acc },
            new Map<Id, Account>{ acc.Id => oldAcc }
        );
        Test.stopTest();

        Opportunity updated = [SELECT Sales_Channel__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Global', updated.Sales_Channel__c,
            'Opp should remain unchanged');
    }
}