@isTest
public class NFATriggerTest {
    static testMethod void testUnit()
    {
         Account newAccount = new Account (Name = 'AcName',
                                          BillingCity ='TestCity',
                                          BillingState = 'GA',
                                          BillingCountry ='US',
                                          BillingStreet ='TestStreet',
                                          BillingPostalCode ='30022'
                                         );
        insert newAccount;
        
        uLab_Feature__c newuLabFeature = new uLab_Feature__c (Feature_Name__c = 'Test', 
                                                              Active__c = true       
                                                            );
        insert newuLabFeature;
             
        New_Feature_Association__c nfa = new New_Feature_Association__c();
        nfa.Effective_Date__c = System.today();
        nfa.Status__c = 'Active';
        nfa.Customer__c = newAccount.Id;
        nfa.uLab_Feature__c = newuLabFeature.Id;
        insert nfa;
    }
}