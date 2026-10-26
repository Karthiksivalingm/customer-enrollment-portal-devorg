/**
 * Proves the Skip_Shopify_Sync__c guard in AccountTriggerHandler and ContactTriggerHandler:
 * records created by Create NetSuite (flag ticked) are not queued for Shopify, while normal
 * records (flag unticked, the default) are queued exactly as before.
 */
@IsTest
private class ShopifySkipGuardTest {

    private static Id companyRtId =
        Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Company').getRecordTypeId();

    private class OkMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }

    private static Account company(String name, String taxId, Boolean skip) {
        return new Account(
            Name = name,
            RecordTypeId = companyRtId,
            Tax_Id__c = taxId,
            Sales_Channel__c = 'Specialty',
            BillingCountryCode = 'US',
            Skip_Shopify_Sync__c = skip
        );
    }

    private static Contact contact(Id accountId, String email, Boolean skip) {
        return new Contact(
            FirstName = 'Guard',
            LastName = 'Test',
            Email = email,
            AccountId = accountId,
            Sales_Channel__c = 'Specialty',
            Manual_Approval_Status__c = 'Approved',
            Tax_Id__c = '123456789',
            Skip_Shopify_Sync__c = skip
        );
    }

    @IsTest
    static void flaggedCompanyIsNotSentToShopify() {
        Test.setMock(HttpCalloutMock.class, new OkMock());

        Integer before = Limits.getQueueableJobs();
        insert company('NetSuite Only Co', '123456789', true);
        Integer flaggedJobs = Limits.getQueueableJobs() - before;

        before = Limits.getQueueableJobs();
        insert company('Normal Shopify Co', '987654321', false);
        Integer normalJobs = Limits.getQueueableJobs() - before;

        Assert.areEqual(normalJobs - 1, flaggedJobs,
            'A flagged Company must queue exactly one job less (no Shopify company sync)');
    }

    @IsTest
    static void flaggedContactIsNotSentToShopifyOnInsertOrUpdate() {
        Test.setMock(HttpCalloutMock.class, new OkMock());
        Account acc = company('Guard Contact Co', '123456789', true);
        insert acc;

        Integer before = Limits.getQueueableJobs();
        Contact flagged = contact(acc.Id, 'netsuite.only@test.com', true);
        insert flagged;
        Integer flaggedInsertJobs = Limits.getQueueableJobs() - before;

        before = Limits.getQueueableJobs();
        Contact normal = contact(acc.Id, 'normal.shopify@test.com', false);
        insert normal;
        Integer normalInsertJobs = Limits.getQueueableJobs() - before;

        Assert.areEqual(normalInsertJobs - 1, flaggedInsertJobs,
            'A flagged Contact must queue exactly one job less on insert (no Shopify contact sync)');

        // Phone correction on an Approved contact without a Shopify ID normally re-sends it to Shopify
        before = Limits.getQueueableJobs();
        update new Contact(Id = flagged.Id, Phone = '5551234567');
        Integer flaggedUpdateJobs = Limits.getQueueableJobs() - before;

        before = Limits.getQueueableJobs();
        update new Contact(Id = normal.Id, Phone = '5557654321');
        Integer normalUpdateJobs = Limits.getQueueableJobs() - before;

        Assert.areEqual(normalUpdateJobs - 1, flaggedUpdateJobs,
            'A flagged Contact must queue exactly one job less on update (no Shopify retry)');
    }
}
