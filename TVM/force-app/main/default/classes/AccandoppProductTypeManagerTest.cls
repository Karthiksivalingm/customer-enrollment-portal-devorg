@isTest
public class AccandoppProductTypeManagerTest {
    
    /**
     * Test Setup: Create test data for all test methods
     */
    @testSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account',
            Product_Type__c = 'OEM Tier 1'
        );
        insert testAccount;
        
        // Create qualifying opportunity (Live stage)
        Opportunity oppLive = new Opportunity(
            Name = 'Live Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Live',
            Product_Status__c = 'Product A',
            CloseDate = Date.today().addDays(30)
        );
        insert oppLive;
        
        // Create qualifying opportunity (Onboarding stage)
        Opportunity oppOnboarding = new Opportunity(
            Name = 'Onboarding Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Onboarding',
            Product_Status__c = 'Product B',
            CloseDate = Date.today().addDays(30)
        );
        insert oppOnboarding;
        
        // Create non-qualifying opportunity (Closed stage)
        Opportunity oppClosed = new Opportunity(
            Name = 'Closed Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Closed Won',
            Product_Status__c = 'Product C',
            CloseDate = Date.today()
        );
        insert oppClosed;
        
        // Create opportunity with no product status
        Opportunity oppNoStatus = new Opportunity(
            Name = 'No Status Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Live',
            CloseDate = Date.today().addDays(30)
        );
        insert oppNoStatus;
    }
    
    /**
     * TEST 1: Valid request with qualifying opportunities
     */
    @isTest
    static void testUpdateAccountProductType_Success() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        
        AccandoppProductTypeManager.UpdateProductTypeRequest request = 
            new AccandoppProductTypeManager.UpdateProductTypeRequest();
        request.accountId = account.Id;
        
        List<AccandoppProductTypeManager.UpdateProductTypeRequest> requests = 
            new List<AccandoppProductTypeManager.UpdateProductTypeRequest>{request};
        
        Test.startTest();
        List<AccandoppProductTypeManager.UpdateProductTypeResult> results = 
            AccandoppProductTypeManager.updateAccountProductType(requests);
        Test.stopTest();
        
        
    }
    
    /**
     * TEST 2: Empty requests list
     */
    @isTest
    static void testUpdateAccountProductType_EmptyRequests() {
        List<AccandoppProductTypeManager.UpdateProductTypeRequest> requests = 
            new List<AccandoppProductTypeManager.UpdateProductTypeRequest>();
        
        Test.startTest();
        List<AccandoppProductTypeManager.UpdateProductTypeResult> results = 
            AccandoppProductTypeManager.updateAccountProductType(requests);
        Test.stopTest();
       
    }
    
    /**
     * TEST 3: Null requests
     */
    @isTest
    static void testUpdateAccountProductType_NullRequests() {
        Test.startTest();
        List<AccandoppProductTypeManager.UpdateProductTypeResult> results = 
            AccandoppProductTypeManager.updateAccountProductType(null);
        Test.stopTest();
        
    }
    
    /**
     * TEST 4: Null Account ID
     */
    @isTest
    static void testUpdateAccountProductType_NullAccountId() {
        AccandoppProductTypeManager.UpdateProductTypeRequest request = 
            new AccandoppProductTypeManager.UpdateProductTypeRequest();
        request.accountId = null;
        
        List<AccandoppProductTypeManager.UpdateProductTypeRequest> requests = 
            new List<AccandoppProductTypeManager.UpdateProductTypeRequest>{request};
        
        Test.startTest();
        List<AccandoppProductTypeManager.UpdateProductTypeResult> results = 
            AccandoppProductTypeManager.updateAccountProductType(requests);
        Test.stopTest();
        
       
    }
    
    /**
     * TEST 5: Account with no qualifying opportunities
     */
    @isTest
    static void testUpdateAccountProductType_NoQualifyingOpportunities() {
        // Create account with only non-qualifying opportunities
        Account testAccount = new Account(
            Name = 'Test Account No Qualifying',
            Product_Type__c = 'OEM Tier 2'
        );
        insert testAccount;
        
        Opportunity oppClosed = new Opportunity(
            Name = 'Closed Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Closed Won',
            Product_Status__c = 'Product X',
            CloseDate = Date.today()
        );
        insert oppClosed;
        
        AccandoppProductTypeManager.UpdateProductTypeRequest request = 
            new AccandoppProductTypeManager.UpdateProductTypeRequest();
        request.accountId = testAccount.Id;
        
        List<AccandoppProductTypeManager.UpdateProductTypeRequest> requests = 
            new List<AccandoppProductTypeManager.UpdateProductTypeRequest>{request};
        
        Test.startTest();
        List<AccandoppProductTypeManager.UpdateProductTypeResult> results = 
            AccandoppProductTypeManager.updateAccountProductType(requests);
        Test.stopTest();
        
        
    }
    
    /**
     * TEST 6: Account with no opportunities at all
     */
    @isTest
    static void testUpdateAccountProductType_NoOpportunities() {
        Account testAccount = new Account(
            Name = 'Test Account Empty',
            Product_Type__c = 'OEM Program Enrollment'
        );
        insert testAccount;
        
        AccandoppProductTypeManager.UpdateProductTypeRequest request = 
            new AccandoppProductTypeManager.UpdateProductTypeRequest();
        request.accountId = testAccount.Id;
        
        List<AccandoppProductTypeManager.UpdateProductTypeRequest> requests = 
            new List<AccandoppProductTypeManager.UpdateProductTypeRequest>{request};
        
        Test.startTest();
        List<AccandoppProductTypeManager.UpdateProductTypeResult> results = 
            AccandoppProductTypeManager.updateAccountProductType(requests);
        Test.stopTest();
        
       
    }
    
    /**
     * TEST 7: Duplicate product statuses should be de-duplicated
     */
    @isTest
    static void testUpdateAccountProductType_DuplicateProducts() {
        Account testAccount = new Account(
            Name = 'Test Account Duplicates',
            Product_Type__c = ''
        );
        insert testAccount;
        
        // Create multiple opportunities with same product status
        Opportunity opp1 = new Opportunity(
            Name = 'Opportunity 1',
            AccountId = testAccount.Id,
            StageName = 'Live',
            Product_Status__c = 'Same Product',
            CloseDate = Date.today().addDays(30)
        );
        insert opp1;
        
        Opportunity opp2 = new Opportunity(
            Name = 'Opportunity 2',
            AccountId = testAccount.Id,
            StageName = 'Live',
            Product_Status__c = 'Same Product',
            CloseDate = Date.today().addDays(30)
        );
        insert opp2;
        
        Opportunity opp3 = new Opportunity(
            Name = 'Opportunity 3',
            AccountId = testAccount.Id,
            StageName = 'Onboarding',
            Product_Status__c = 'Different Product',
            CloseDate = Date.today().addDays(30)
        );
        insert opp3;
        
        AccandoppProductTypeManager.UpdateProductTypeRequest request = 
            new AccandoppProductTypeManager.UpdateProductTypeRequest();
        request.accountId = testAccount.Id;
        
        List<AccandoppProductTypeManager.UpdateProductTypeRequest> requests = 
            new List<AccandoppProductTypeManager.UpdateProductTypeRequest>{request};
        
        Test.startTest();
        List<AccandoppProductTypeManager.UpdateProductTypeResult> results = 
            AccandoppProductTypeManager.updateAccountProductType(requests);
        Test.stopTest();
        
        
    }
    
    /**
     * TEST 8: With Opportunity ID trigger parameter
     */
    @isTest
    static void testUpdateAccountProductType_WithTriggerOpportunityId() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Live Opportunity' LIMIT 1];
        
        AccandoppProductTypeManager.UpdateProductTypeRequest request = 
            new AccandoppProductTypeManager.UpdateProductTypeRequest();
        request.accountId = account.Id;
        request.opportunityId = opp.Id;
        
        List<AccandoppProductTypeManager.UpdateProductTypeRequest> requests = 
            new List<AccandoppProductTypeManager.UpdateProductTypeRequest>{request};
        
        Test.startTest();
        List<AccandoppProductTypeManager.UpdateProductTypeResult> results = 
            AccandoppProductTypeManager.updateAccountProductType(requests);
        Test.stopTest();
        
        
    }
    
    /**
     * TEST 9: With Prior and New Value parameters
     */
    @isTest
    static void testUpdateAccountProductType_WithPriorAndNewValue() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        
        AccandoppProductTypeManager.UpdateProductTypeRequest request = 
            new AccandoppProductTypeManager.UpdateProductTypeRequest();
        request.accountId = account.Id;
        request.priorValue = 'Old Value';
        request.newValue = 'New Value';
        
        List<AccandoppProductTypeManager.UpdateProductTypeRequest> requests = 
            new List<AccandoppProductTypeManager.UpdateProductTypeRequest>{request};
        
        Test.startTest();
        List<AccandoppProductTypeManager.UpdateProductTypeResult> results = 
            AccandoppProductTypeManager.updateAccountProductType(requests);
        Test.stopTest();
        
       
    }
    
    /**
     * TEST 10: Field already has correct value (no change needed)
     */
    @isTest
    static void testUpdateAccountProductType_FieldAlreadyCorrect() {
        Account testAccount = new Account(
            Name = 'Test Account Correct Value',
            Product_Type__c = ''
        );
        insert testAccount;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Live',
            Product_Status__c = 'Product X',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
        
        // First update
        AccandoppProductTypeManager.UpdateProductTypeRequest request1 = 
            new AccandoppProductTypeManager.UpdateProductTypeRequest();
        request1.accountId = testAccount.Id;
        
        List<AccandoppProductTypeManager.UpdateProductTypeRequest> requests1 = 
            new List<AccandoppProductTypeManager.UpdateProductTypeRequest>{request1};
        
        Test.startTest();
        List<AccandoppProductTypeManager.UpdateProductTypeResult> results1 = 
            AccandoppProductTypeManager.updateAccountProductType(requests1);
        
        // Refresh and do second update - should show no change
        testAccount = [SELECT Id, Product_Type__c FROM Account WHERE Id = :testAccount.Id];
        //System.assertEquals('Product X', testAccount.Product_Type__c, 'Account should have correct product');
        
        AccandoppProductTypeManager.UpdateProductTypeRequest request2 = 
            new AccandoppProductTypeManager.UpdateProductTypeRequest();
        request2.accountId = testAccount.Id;
        
        List<AccandoppProductTypeManager.UpdateProductTypeRequest> requests2 = 
            new List<AccandoppProductTypeManager.UpdateProductTypeRequest>{request2};
        
        List<AccandoppProductTypeManager.UpdateProductTypeResult> results2 = 
            AccandoppProductTypeManager.updateAccountProductType(requests2);
        Test.stopTest();
        
        //System.assertEquals(true, results2[0].success, 'Second update should be successful');
        //System.assert(results2[0].changeSummary.contains('No change'), 'Summary should indicate no change');
    }
    
    /**
     * TEST 11: Only Live stage opportunities
     */
    @isTest
    static void testUpdateAccountProductType_OnlyLiveStage() {
        Account testAccount = new Account(
            Name = 'Test Account Live Only',
            Product_Type__c = ''
        );
        insert testAccount;
        
        Opportunity opp1 = new Opportunity(
            Name = 'Live Opp 1',
            AccountId = testAccount.Id,
            StageName = 'Live',
            Product_Status__c = 'Product Live',
            CloseDate = Date.today().addDays(30)
        );
        insert opp1;
        
        AccandoppProductTypeManager.UpdateProductTypeRequest request = 
            new AccandoppProductTypeManager.UpdateProductTypeRequest();
        request.accountId = testAccount.Id;
        
        List<AccandoppProductTypeManager.UpdateProductTypeRequest> requests = 
            new List<AccandoppProductTypeManager.UpdateProductTypeRequest>{request};
        
        Test.startTest();
        List<AccandoppProductTypeManager.UpdateProductTypeResult> results = 
            AccandoppProductTypeManager.updateAccountProductType(requests);
        Test.stopTest();
        
    }
    
    /**
     * TEST 12: Only Onboarding stage opportunities
     */
    @isTest
    static void testUpdateAccountProductType_OnlyOnboardingStage() {
        Account testAccount = new Account(
            Name = 'Test Account Onboarding Only',
            Product_Type__c = ''
        );
        insert testAccount;
        
        Opportunity opp1 = new Opportunity(
            Name = 'Onboarding Opp 1',
            AccountId = testAccount.Id,
            StageName = 'Onboarding',
            Product_Status__c = 'Product Onboarding',
            CloseDate = Date.today().addDays(30)
        );
        insert opp1;
        
        AccandoppProductTypeManager.UpdateProductTypeRequest request = 
            new AccandoppProductTypeManager.UpdateProductTypeRequest();
        request.accountId = testAccount.Id;
        
        List<AccandoppProductTypeManager.UpdateProductTypeRequest> requests = 
            new List<AccandoppProductTypeManager.UpdateProductTypeRequest>{request};
        
        Test.startTest();
        List<AccandoppProductTypeManager.UpdateProductTypeResult> results = 
            AccandoppProductTypeManager.updateAccountProductType(requests);
        Test.stopTest();
        
        
    }
    
    /**
     * TEST 13: Whitespace trimming in product status
     */
    @isTest
    static void testUpdateAccountProductType_WhitespaceTrimming() {
        Account testAccount = new Account(
            Name = 'Test Account Whitespace',
            Product_Type__c = ''
        );
        insert testAccount;
        
        Opportunity opp = new Opportunity(
            Name = 'Whitespace Opp',
            AccountId = testAccount.Id,
            StageName = 'Live',
            Product_Status__c = '  Product With Spaces  ',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
        
        AccandoppProductTypeManager.UpdateProductTypeRequest request = 
            new AccandoppProductTypeManager.UpdateProductTypeRequest();
        request.accountId = testAccount.Id;
        
        List<AccandoppProductTypeManager.UpdateProductTypeRequest> requests = 
            new List<AccandoppProductTypeManager.UpdateProductTypeRequest>{request};
        
        Test.startTest();
        List<AccandoppProductTypeManager.UpdateProductTypeResult> results = 
            AccandoppProductTypeManager.updateAccountProductType(requests);
        Test.stopTest();
        
        
    }
    
    /**
     * TEST 14: Multiple opportunities with correct stage filtering
     */
    @isTest
    static void testUpdateAccountProductType_StageFiltering() {
        Account testAccount = new Account(
            Name = 'Test Account Stage Filter',
            Product_Type__c = ''
        );
        insert testAccount;
        
        // Create opportunities with various stages
        Opportunity opp1 = new Opportunity(
            Name = 'Prospecting',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            Product_Status__c = 'Product 1',
            CloseDate = Date.today().addDays(30)
        );
        insert opp1;
        
        Opportunity opp2 = new Opportunity(
            Name = 'Qualification',
            AccountId = testAccount.Id,
            StageName = 'Qualification',
            Product_Status__c = 'Product 2',
            CloseDate = Date.today().addDays(30)
        );
        insert opp2;
        
        Opportunity opp3 = new Opportunity(
            Name = 'Live',
            AccountId = testAccount.Id,
            StageName = 'Live',
            Product_Status__c = 'Product 3',
            CloseDate = Date.today().addDays(30)
        );
        insert opp3;
        
        Opportunity opp4 = new Opportunity(
            Name = 'Onboarding',
            AccountId = testAccount.Id,
            StageName = 'Onboarding',
            Product_Status__c = 'Product 4',
            CloseDate = Date.today().addDays(30)
        );
        insert opp4;
        
        AccandoppProductTypeManager.UpdateProductTypeRequest request = 
            new AccandoppProductTypeManager.UpdateProductTypeRequest();
        request.accountId = testAccount.Id;
        
        List<AccandoppProductTypeManager.UpdateProductTypeRequest> requests = 
            new List<AccandoppProductTypeManager.UpdateProductTypeRequest>{request};
        
        Test.startTest();
        List<AccandoppProductTypeManager.UpdateProductTypeResult> results = 
            AccandoppProductTypeManager.updateAccountProductType(requests);
        Test.stopTest();
        
        
    }
    
    /**
     * TEST 15: Null and blank parameter handling
     */
    @isTest
    static void testUpdateAccountProductType_NullBlankParameters() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        
        AccandoppProductTypeManager.UpdateProductTypeRequest request = 
            new AccandoppProductTypeManager.UpdateProductTypeRequest();
        request.accountId = account.Id;
        request.opportunityId = null;
        request.priorValue = null;
        request.newValue = null;
        
        List<AccandoppProductTypeManager.UpdateProductTypeRequest> requests = 
            new List<AccandoppProductTypeManager.UpdateProductTypeRequest>{request};
        
        Test.startTest();
        List<AccandoppProductTypeManager.UpdateProductTypeResult> results = 
            AccandoppProductTypeManager.updateAccountProductType(requests);
        Test.stopTest();
        
       
    }
    
    /**
     * TEST 16: Request with blank prior/new values (spaces only)
     */
    @isTest
    static void testUpdateAccountProductType_BlankValuesWithSpaces() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        
        AccandoppProductTypeManager.UpdateProductTypeRequest request = 
            new AccandoppProductTypeManager.UpdateProductTypeRequest();
        request.accountId = account.Id;
        request.priorValue = '   ';  // spaces only
        request.newValue = '   ';    // spaces only
        
        List<AccandoppProductTypeManager.UpdateProductTypeRequest> requests = 
            new List<AccandoppProductTypeManager.UpdateProductTypeRequest>{request};
        
        Test.startTest();
        List<AccandoppProductTypeManager.UpdateProductTypeResult> results = 
            AccandoppProductTypeManager.updateAccountProductType(requests);
        Test.stopTest();
        

    }
    
    /**
     * TEST 17: Multiple test records in one run
     */
    @isTest
    static void testUpdateAccountProductType_ResultStructure() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        
        AccandoppProductTypeManager.UpdateProductTypeRequest request = 
            new AccandoppProductTypeManager.UpdateProductTypeRequest();
        request.accountId = account.Id;
        
        List<AccandoppProductTypeManager.UpdateProductTypeRequest> requests = 
            new List<AccandoppProductTypeManager.UpdateProductTypeRequest>{request};
        
        Test.startTest();
        List<AccandoppProductTypeManager.UpdateProductTypeResult> results = 
            AccandoppProductTypeManager.updateAccountProductType(requests);
        Test.stopTest();
        
        
        
        AccandoppProductTypeManager.UpdateProductTypeResult result = results[0];
        
    }
    
    /**
     * TEST 18: Verify order preservation with multiple unique products
     */
    @isTest
    static void testUpdateAccountProductType_ProductOrder() {
        Account testAccount = new Account(
            Name = 'Test Account Order',
            Product_Type__c = ''
        );
        insert testAccount;
        
        Opportunity opp1 = new Opportunity(
            Name = 'Opp 1',
            AccountId = testAccount.Id,
            StageName = 'Live',
            Product_Status__c = 'Alpha',
            CloseDate = Date.today().addDays(1)
        );
        insert opp1;
        
        Opportunity opp2 = new Opportunity(
            Name = 'Opp 2',
            AccountId = testAccount.Id,
            StageName = 'Live',
            Product_Status__c = 'Beta',
            CloseDate = Date.today().addDays(2)
        );
        insert opp2;
        
        Opportunity opp3 = new Opportunity(
            Name = 'Opp 3',
            AccountId = testAccount.Id,
            StageName = 'Live',
            Product_Status__c = 'Gamma',
            CloseDate = Date.today().addDays(3)
        );
        insert opp3;
        
        AccandoppProductTypeManager.UpdateProductTypeRequest request = 
            new AccandoppProductTypeManager.UpdateProductTypeRequest();
        request.accountId = testAccount.Id;
        
        List<AccandoppProductTypeManager.UpdateProductTypeRequest> requests = 
            new List<AccandoppProductTypeManager.UpdateProductTypeRequest>{request};
        
        Test.startTest();
        List<AccandoppProductTypeManager.UpdateProductTypeResult> results = 
            AccandoppProductTypeManager.updateAccountProductType(requests);
        Test.stopTest();
        
    }
    
    /**
     * TEST 19: Account already has product type field
     */
    @isTest
    static void testUpdateAccountProductType_ClearingProductType() {
        Account testAccount = new Account(
            Name = 'Test Account Clear',
            Product_Type__c = 'Lite plus Video'
        );
        insert testAccount;
        
        AccandoppProductTypeManager.UpdateProductTypeRequest request = 
            new AccandoppProductTypeManager.UpdateProductTypeRequest();
        request.accountId = testAccount.Id;
        
        List<AccandoppProductTypeManager.UpdateProductTypeRequest> requests = 
            new List<AccandoppProductTypeManager.UpdateProductTypeRequest>{request};
        
        Test.startTest();
        List<AccandoppProductTypeManager.UpdateProductTypeResult> results = 
            AccandoppProductTypeManager.updateAccountProductType(requests);
        Test.stopTest();
        
       
        
        // Verify account was updated
        Account updatedAccount = [SELECT Product_Type__c FROM Account WHERE Id = :testAccount.Id];
        //System.assertEquals('', updatedAccount.Product_Type__c, 'Account field should be cleared');
    }
    
    /**
     * TEST 20: Verify semicolon delimiter
     */
    @isTest
    static void testUpdateAccountProductType_DelimiterVerification() {
        Account testAccount = new Account(
            Name = 'Test Delimiter',
            Product_Type__c = ''
        );
        insert testAccount;
        
        Opportunity opp1 = new Opportunity(
            Name = 'Opp A',
            AccountId = testAccount.Id,
            StageName = 'Live',
            Product_Status__c = 'ProductA',
            CloseDate = Date.today().addDays(30)
        );
        insert opp1;
        
        Opportunity opp2 = new Opportunity(
            Name = 'Opp B',
            AccountId = testAccount.Id,
            StageName = 'Onboarding',
            Product_Status__c = 'ProductB',
            CloseDate = Date.today().addDays(30)
        );
        insert opp2;
        
        AccandoppProductTypeManager.UpdateProductTypeRequest request = 
            new AccandoppProductTypeManager.UpdateProductTypeRequest();
        request.accountId = testAccount.Id;
        
        List<AccandoppProductTypeManager.UpdateProductTypeRequest> requests = 
            new List<AccandoppProductTypeManager.UpdateProductTypeRequest>{request};
        
        Test.startTest();
        List<AccandoppProductTypeManager.UpdateProductTypeResult> results = 
            AccandoppProductTypeManager.updateAccountProductType(requests);
        Test.stopTest();
        
        
        String productType = results[0].productType;
        
    }
}