//Apex from FND
@isTest
public class OnboardingQACheckList_Test {
 
    public static account testMthd(){
        
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator']; // Replace 'Standard User' with the actual profile name
        User testUser = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'uniquewuser@example.com'
        );
        insert testUser;
        
        Account acc = new Account();
        System.runAs(testUser) {
            RecordType oppRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Foundation_Dealership' LIMIT 1];
           
            acc.Name = 'test';
            acc.Regional_performance_manager__c = testUser.id;
            acc.RecordTypeId = oppRT.id;
            insert acc;
            
            Foundation_Onboarding__c obj = new Foundation_Onboarding__c();
            // obj.Facebook_Request_Accepted__c = 'Not Started';
            obj.Regional_Performance_Manager__c = testUser.id;
            obj.Account__c = acc.Id;
            insert obj;
            
            task tsk = new task();
            tsk.Subject = '14 Day launch QA';
            tsk.WhatId = acc.Id;
            
            insert tsk;
            
            task tsk1 = new task();
            tsk1.Subject = 'Performance Max';
            tsk1.WhatId = acc.Id;
            
            insert tsk1;
            OnboardingQACheckList.getCheckbox(obj.Id);
            OnboardingQACheckList.saveOnboarding(obj,true,'14 day launch QA');
            OnboardingQACheckList.saveOnboarding(obj,true,'7 day launch QA');
            OnboardingQACheckList.saveOnboarding(obj,true,'Launch Day QA');
            OnboardingQACheckList.saveOnboarding(obj,true,'Performance Max');
        }
        return acc;
    }
    
     static testMethod void testCallout(){
    	Account acctToCreate = testMthd();
    	Test.startTest();
    	Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());
        Integer callouts = Limits.getCallouts();
    	Test.stopTest();
  	}

}