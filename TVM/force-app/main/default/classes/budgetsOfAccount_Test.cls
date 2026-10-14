@isTest(SeeAllData=true)
public class budgetsOfAccount_Test {

    // ---- MOCK CLASS (Required for callout classes) ----
    private class BudgetMockCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            return res;
        }
    }

    @isTest 
    public static void testMediabudgets() {

        Test.startTest();

        // Register mock handler before executing the callout class
        Test.setMock(HttpCalloutMock.class, new BudgetMockCallout());

        // Query existing Account from org (SeeAllData=true enabled)
        Account a2 = [
            SELECT Id, Name 
            FROM Account 
            WHERE Name = 'Test - Foundation' 
            LIMIT 1
        ];

        // Test data: Monthly Budget record
        Monthly_Budget__c mb = new Monthly_Budget__c(
            Account__c = a2.Id,
            Budget_Month__c = Datetime.now().format('MMM'),
            Budget_Year__c = Datetime.now().format('YYYY'),
            PPC_Budget_DISC__c = 3000
        );
        insert mb;

        // Instantiate and execute the class under test
        budgetsOfAccount act = new budgetsOfAccount();
        act.accountId = a2.Id;

        // Touch variables to increase test coverage
        Account acts = act.account;
        List<Monthly_Budget__c> mbList1 = act.Opps;
        List<Monthly_Budget__c> mbList2 = act.newOpps;
        String str = act.NewLine;

        Test.stopTest();
    }
}