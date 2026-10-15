@isTest
public class CompanyPriceTotalBatch_test {
    @isTest
    public static void test(){
        Account newAccount = new Account (Name = 'AcName',
                                          BillingCity ='TestCity',
                                          BillingCountry ='US',
                                          BillingStreet ='TestStreet',
                                          BillingState = 'TN',
                                          BillingPostalCode ='t3stcd3'
                                         );
        insert newAccount;
        Marketing_Reward__c reward = new Marketing_Reward__c();
        reward.Name__c  = 'Premier Partner A - 2022';
        reward.Start_Date__c = Date.valueOf(system.today().adddays(-9));
        reward.End_Date__c =Date.valueOf(system.today().adddays(100));
        //reward.Status__c = 'Active';
        insert reward;
        Marketing_Reward_Association__c mark = new Marketing_Reward_Association__c();
        mark.Effective_Date__c = Date.valueOf(system.today().adddays(-9));
        mark.End_Date__c = Date.valueOf(system.today().adddays(100));
        mark.RecordTypeId = '0126g000000bOBUAA2';
        mark.Company__c = newAccount.Id;
        mark.Marketing_Program__c = reward.id;
        insert mark;
        uLab_Case__c cas = new uLab_Case__c();
        cas.Account__c = newAccount.id;
        insert cas;
        uLab_Order__c order = new uLab_Order__c();
        order.Total_Aligner_Price__c = 100;
        order.Total_Custom_Box_Price__c = 200;
        order.Total_Retainer_Price__c = 300;
        order.of_Lower_Stages__c = 30;
        order.of_Upper_Stages__c = 80;
        order.Total_Retainer_Count__c = 40;
        order.Order_Status__c = 'Processed';
        order.OrderDate__c = Date.valueOf(system.today());
        order.Name = 'test';
        order.uLab_Case__c = cas.id;
         order.of_Lower_Stages__c = 30;
        order.of_Upper_Stages__c = 80;
        order.Total_Retainer_Count__c = 40;
        order.Order_Type__c = 'uLab Aligner';
        insert order;
        CompanyTotalPriceBatch obj = new CompanyTotalPriceBatch(newAccount.Id);
        database.executeBatch(obj);
        CompanyTotalPriceHelper com = new CompanyTotalPriceHelper();
        CompanyTotalPriceHelper.callBatch(newAccount.Id);
        
    }
    @isTest
    public static void test1(){
        Account newAccount = new Account (Name = 'AcName',
                                          BillingCity ='TestCity',
                                          BillingCountry ='US',
                                          BillingState = 'TN',
                                          BillingStreet ='TestStreet',
                                          BillingPostalCode ='t3stcd3'
                                         );
        insert newAccount;
        Marketing_Reward__c reward = new Marketing_Reward__c();
        reward.Name__c  = 'New Start - 2022';
        reward.Start_Date__c = Date.valueOf(system.today().adddays(-9));
        reward.End_Date__c =Date.valueOf(system.today().adddays(100));
        // reward.Status__c = 'Active';
        insert reward;
        Marketing_Reward_Association__c mark = new Marketing_Reward_Association__c();
        mark.Effective_Date__c = Date.valueOf(system.today().adddays(-9));
        mark.End_Date__c = Date.valueOf(system.today().adddays(100));
        mark.RecordTypeId = '0126g000000bOBUAA2';
        mark.Company__c = newAccount.Id;
        mark.Marketing_Program__c = reward.id;
        insert mark;
        uLab_Case__c cas = new uLab_Case__c();
        cas.Account__c = newAccount.id;
        insert cas;
        uLab_Order__c order = new uLab_Order__c();
        order.Total_Aligner_Price__c = 100;
        order.Total_Custom_Box_Price__c = 200;
        order.Total_Retainer_Price__c = 300;
        order.Order_Status__c = 'Processed';
        order.OrderDate__c = Date.valueOf(system.today());
        order.Name = 'test';
        order.uLab_Case__c = cas.id;
        order.Order_Type__c = 'uLab Aligner';
        insert order;
        uLab_Order__c order1 = new uLab_Order__c();
        order1.Total_Aligner_Price__c = 100;
        order1.Total_Custom_Box_Price__c = 200;
        order1.Total_Retainer_Price__c = 300;
        order1.Order_Status__c = 'Processed';
        order1.OrderDate__c = Date.valueOf(system.today());
        order1.Name = 'test';
        order1.uLab_Case__c = cas.id;
        order1.of_Lower_Stages__c = 30;
        order1.of_Upper_Stages__c = 80;
        order1.Total_Retainer_Count__c = 40;
        order1.Order_Type__c = 'uLab Aligner';
        insert order1;
        CompanyTotalPriceBatch obj = new CompanyTotalPriceBatch(newAccount.Id);
        database.executeBatch(obj);
        
    }
    @isTest
    public static void test2(){
        Account newAccount = new Account (Name = 'AcName',
                                          BillingCity ='TestCity',
                                          BillingCountry ='US',
                                          BillingState = 'TN',
                                          BillingStreet ='TestStreet',
                                          BillingPostalCode ='t3stcd3'
                                         );
        insert newAccount;
        Marketing_Reward__c reward = new Marketing_Reward__c();
        reward.Name__c  = 'uPP A - 2022';
        reward.Start_Date__c = Date.valueOf(system.today().adddays(-9));
        reward.End_Date__c =Date.valueOf(system.today().adddays(100));
        //reward.Status__c = 'Active';
        insert reward;
        Marketing_Reward_Association__c mark = new Marketing_Reward_Association__c();
        mark.Effective_Date__c = Date.valueOf(system.today().adddays(-9));
        mark.End_Date__c = Date.valueOf(system.today().adddays(100));
        mark.RecordTypeId = '0126g000000bOBUAA2';
        mark.Company__c = newAccount.Id;
        mark.Marketing_Program__c = reward.id;
        insert mark;
        uLab_Case__c cas = new uLab_Case__c();
        cas.Account__c = newAccount.id;
        insert cas;
        uLab_Order__c order = new uLab_Order__c();
        order.Total_Aligner_Price__c = 100;
        order.Total_Custom_Box_Price__c = 200;
        order.Total_Retainer_Price__c = 300;
        order.Order_Status__c = 'Processed';
        order.OrderDate__c = Date.valueOf(system.today());
        order.Name = 'test';
        order.uLab_Case__c = cas.id;
        order.of_Lower_Stages__c = 30;
        order.of_Upper_Stages__c = 80;
        order.Total_Retainer_Count__c = 40;
        order.Order_Type__c = 'uLab Aligner';
        insert order;
        uLab_Order__c order1 = new uLab_Order__c();
        order1.Total_Aligner_Price__c = 100;
        order1.Total_Custom_Box_Price__c = 200;
        order1.Total_Retainer_Price__c = 300;
        order.of_Lower_Stages__c = 30;
        order.of_Upper_Stages__c = 80;
        order.Total_Retainer_Count__c = 40;
        order1.Order_Status__c = 'Processed';
        order1.OrderDate__c = Date.valueOf(system.today());
        order1.Name = 'test';
        order1.uLab_Case__c = cas.id;
        order1.Order_Type__c = 'uLab Aligner';
        insert order1;
        
        CompanyTotalPriceBatch obj = new CompanyTotalPriceBatch(newAccount.Id);
        database.executeBatch(obj);
        CompanyTotalPriceHelper sh1 = new CompanyTotalPriceHelper();
         String sch = '0 0 23 * * ?'; 
        system.schedule('Test Territory Check', sch, sh1); 
        
    }
}