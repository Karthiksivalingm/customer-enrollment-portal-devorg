@isTest
public class OnboardingProductFieldUpdateBatchTest {
    
    @isTest
    static void testMethod1() {
        Id pricebookId = Test.getStandardPricebookId();
        
        // Step 1: Create Account
        Account acc = new Account(
            Name = 'TestAccount1'
        );
        insert acc;
        
        // Step 2: Create Opportunity (must match Account Name due to validation)
        Opportunity opp = new Opportunity(
            Name = acc.Name,
            StageName = 'Onboarding',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;
        
        // Step 3: Create Foundation_Onboarding__c record
        Foundation_Onboarding__c onbor = new Foundation_Onboarding__c(
            Opportunity__c = opp.Id
        );
        insert onbor;
        
        // Step 4: Create Product
        Product2 prod = new Product2(
            Name = 'Product X',
            ProductCode = 'Pro-X',
            IsActive = true
        );
        insert prod;
        
        // Step 5: Create Pricebook Entry
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry;
        
        // Step 6: Create Opportunity Line Item
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 1,
            PricebookEntryId = pbEntry.Id,
            TotalPrice = 1000
        );
        insert oli;
        
        // Step 7: Run batch
        Test.startTest();
        OnboardingProductFieldUpdateBatch obj = new OnboardingProductFieldUpdateBatch();
        Database.executeBatch(obj, 1);
        Test.stopTest();
        
        // Step 8: Verify that Foundation_Onboarding__c record is updated
        Foundation_Onboarding__c updatedOnboarding = [
            SELECT Opportunity_Product_Name__c, Profit_Center_New__c, Profit_Center_Used__c, Profit_Center_Service__c
            FROM Foundation_Onboarding__c
            WHERE Id = :onbor.Id
            LIMIT 1
        ];
        
        System.assertNotEquals(
            null,
            updatedOnboarding.Opportunity_Product_Name__c,
            'Expected Opportunity_Product_Name__c to be populated after batch run.'
        );
    }
}