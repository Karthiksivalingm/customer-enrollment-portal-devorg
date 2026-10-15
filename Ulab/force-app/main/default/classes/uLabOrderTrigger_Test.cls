@isTest
public class uLabOrderTrigger_Test {
    @istest
    public static void test(){
        Account acc = new Account();
        acc.Name = 'test';
        insert acc;
        uLab_Case__c uLabCase = new uLab_Case__c();
        uLabCase.Account__c = acc.Id;
        insert uLabCase;
        uLab_Order__c uLabObj = new uLab_Order__c();
        uLabObj.uLab_Case__c = uLabCase.Id;
        uLabObj.Order_Type__c = 'uLab Aligner';
        insert uLabObj;
        uLab_Order__c uLabObj1 = new uLab_Order__c();
        uLabObj1.uLab_Case__c = uLabCase.Id;
        uLabObj1.Order_Type__c = 'uLab Aligner';
        insert uLabObj1;
        
        uLab_Order__c uLabObj2 = new uLab_Order__c();
        uLabObj2.uLab_Case__c = uLabCase.Id;
        uLabObj2.Order_Type__c =  'In Office STL';
        insert uLabObj2;
        uLabOrder_Batch batch = new uLabOrder_Batch();
        database.executeBatch(batch);
        
    }
}