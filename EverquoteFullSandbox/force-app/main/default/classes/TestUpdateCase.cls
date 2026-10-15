@isTest
public class TestUpdateCase {
	static testMethod void insertTask() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Account dummy_acc = new Account();
        dummy_acc.Name = 'dummy';
        insert dummy_acc;
        
        List<Account> accs = [SELECT Id FROM Account WHERE Name = 'dummy'];
        String dummy_acc_id = accs[0].Id;
        
        Group excludedQueue = [SELECT Id FROM Group WHERE DeveloperName = 'nyk_dawn_Opp_Case' AND Type = 'Queue' LIMIT 1];
       
        Case the_case = new Case();
        the_case.Subject = 'dummy';
        the_case.AccountId = dummy_acc_id;
        the_case.OwnerId = excludedQueue.Id;
        insert the_case;
        
        List<Case> cases = [SELECT Id FROM Case WHERE Subject = 'dummy'];
        String dummy_case_id = cases[0].Id;
        
        Task task = new Task();
        task.Subject = 'Outbound Call';
        task.WhatId = dummy_case_id;
        insert task;
    }
}