//Apex from FND
@isTest
public class BudgetsOfAmount_Test {
@isTest
    public static void test(){
        
        Account acc = new Account();
        acc.name =  'Test';
        insert acc;
        Monthly_Budget__c obj = new Monthly_Budget__c();
        obj.PPC_Budget_Sales__c = 10;
        obj.Account__c = acc.id;
        insert obj;
         Test.startTest();
        BudgetsOfAmount budCls = new BudgetsOfAmount();
        budCls.mediaId = obj.Id;
        Monthly_Budget__c obj1 = new Monthly_Budget__c();
        obj1 = budCls.MediaObj;
         Test.stopTest();
    }
}