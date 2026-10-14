//Apex class from FND
@isTest
public class updateOppProducts_Test {

    // This is how we get the Standard PriceBook Id.  Prior to Summer '14, we needed
    // to use SeeAllData=true, so this is a big improvement
    @isTest 
    public static void test_UpdateOppProductTrigger(){
        Id pricebookId = Test.getStandardPricebookId();
        
        //Create your product
        Product2 prod = new Product2(
            Name = 'Product Test',
            ProductCode = 'Pro-001',
            MRR__c = 200,
            Set_up_Fee__c = 100,
            isActive = true
        );
        
        test.startTest();
        insert prod;
        
        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry;
        
        Date closeDt = Date.Today();

        // Create account
        Account a2 = new Account(Name = 'icrm testing acc');
        insert a2;

        // ✅ Fix 1: Match Opportunity Name with Account Name to pass validation
        Opportunity opp = new Opportunity(
            Name = a2.Name, // Must match Account Name
            AccountId = a2.Id,
            StageName = 'Prospecting',
            CloseDate = closeDt
        );
        insert opp;    
        
        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        // ✅ Fix 2: Set Quantity = 1 to pass validation
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 1, // Must always be 1
            PricebookEntryId = pbEntry.Id,
            UnitPrice = 25
        );
        insert oli;

        test.stopTest();
    }
}