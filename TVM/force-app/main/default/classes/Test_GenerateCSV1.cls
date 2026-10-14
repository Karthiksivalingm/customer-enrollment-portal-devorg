// Test class from FND
@isTest
public class Test_GenerateCSV1 {

    // helper method to generate a random suffix
    private static String uniqueSuffix() {
        Integer rnd = Math.abs(Math.mod(Math.abs(Crypto.getRandomInteger()), 1000000));
        return String.valueOf(rnd);
    }
   
    public static void testGenerateCSVForOnboarding() {

        // declare suf before using it
        String suf = uniqueSuffix();
       
        RecordType oppRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Foundation_Dealership' LIMIT 1];
        
        Account objAccount = new Account();
        objAccount.Name = 'Test_' + suf;
        objAccount.recordtypeid = oppRT.id;
        
        INSERT objAccount;
        
        RecordType oppRT1 = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND DeveloperName = 'Foundation_Opportunity' LIMIT 1];
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Cancellation',
            CloseDate = Date.today(),
            RecordTypeId =oppRT1.id,
            AccountId = objAccount.Id
           
        );
        INSERT testOpp;
        
        Account accRecord2=new account();
        accRecord2.Name='Test Acc2';
        accRecord2.Quickbase_Record_ID__c = suf +1;
        insert accRecord2;
        
        Contact objContact = new Contact();
        objContact.LastName = 'Test';
        objContact.AccountId = accRecord2.Id;
        INSERT objContact;
        
        // Create test data for Onboarding__c records
        List<Foundation_Onboarding__c> testOnboardingList = new List<Foundation_Onboarding__c>();
        // Add test data for Business Intelligence Onboarding
        testOnboardingList.add(new Foundation_Onboarding__c(
            Opportunity__c = testOpp.Id,
            Account__c = objAccount.Id
        ));
        // Add test data for Digital Advertising Onboarding
        testOnboardingList.add(new Foundation_Onboarding__c(
            Opportunity__c = testOpp.Id,
            Account__c = accRecord2.Id
        ));
        
        insert testOnboardingList;
        
        // Create test data for Contact records
        List<Contact> testContactList = new List<Contact>();
        testContactList.add(new Contact(
            AccountId = testOnboardingList[0].Account__c,
            LastName = 'Test'
        ));
        testContactList.add(new Contact(
            AccountId = testOnboardingList[1].Account__c,
            LastName = 'Test'
        ));
        
        insert testContactList;
        
        AccountContactRelation  accCon = new AccountContactRelation ();
        accCon.AccountId = accRecord2.id;
        accCon.ContactId = testContactList[0].Id;
        accCon.Roles = 'Onboarding';
       
        insert accCon;
        
        Foundation_Onboarding__c obj = new Foundation_Onboarding__c();
     /*   obj.Facebook_Request_Accepted__c = 'Not Started';
        obj.Facebook_Request_Sent__c = 'Needs Followup';
        obj.Facebook_Request_Accepted__c = 'Needs Followup';
        obj.GMB_Request_Sent__c = 'Needs Followup';
        obj.GMB_Request_Received__c = 'Needs Followup';
        obj.Turn_Sitelinks_Off_in_Apollo__c = 'Needs Followup';
        obj.Add_Sitelinks_to_Google_Ads__c = 'Needs Followup';
        obj.Budgets_Updated_in_Apollo__c = 'Needs Followup'; 
        obj.Send_Advertised_Payments_for_Approval__c = 'Needs Followup';
        obj.Verify_Inventory_Pricing__c = 'Needs Followup';
        // obj.Credit_Card_Received__c = 'Needs Followup';
        obj.Zipcodes_Received__c = 'Needs Followup';
        obj.Budgets_Confirmed__c = 'Needs Followup';
        obj.Send_Geo_targeting_for_Approval__c = 'Needs Followup';
        obj.Send_Advertised_Payments_for_Approval__c = 'Needs Followup';
        obj.Confirm_Launch_Date_with_Client__c = 'Needs Followup';
        obj.Add_CC_to_Google__c= 'Needs Followup';  */
        obj.Opportunity__c = testOpp.Id;
                
        INSERT obj;
        
        testOpp.stageName = 'Cancellation';
        
        UPDATE testOpp;
    }
     /*   Test.startTest();
        String cronExp = '0 1 * ? * * *'; 
        System.schedule('MyScheduledJob', cronExp, new Schedule_Onboarding_Account_Contact1());
        Test.stopTest();  */
    
      static testMethod void testCallout(){
        
        testGenerateCSVForOnboarding();
        
        Test.startTest();
        String cronExp = '0 1 * ? * * *'; 
        System.schedule('MyScheduledJob', cronExp, new Schedule_Onboarding_Account_Contact1());
        Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());
        Integer callouts = Limits.getCallouts();
        Test.stopTest();
    }
}