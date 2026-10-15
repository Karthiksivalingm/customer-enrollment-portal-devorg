@isTest
public class RewardAssociationTrigger_Test {
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
        
        Marketing_Reward__c mr = new Marketing_Reward__c();
        mr.Name__c= 'New Start';
        //mr.Status__c =  'Active';
        mr.Start_Date__c = System.TOday() - 180;
        mr.End_Date__c = System.TOday() + 180; 
        insert mr;
        
        Marketing_Reward_Association__c mra = new Marketing_Reward_Association__c();
        mra.Company__c = acc.Id; 
        mra.Marketing_Program__c = mr.id; 
        mra.Effective_Date__c = System.TOday() - 180;
        mra.End_Date__c = System.TOday() + 180;
        insert mra;
        
    }
}