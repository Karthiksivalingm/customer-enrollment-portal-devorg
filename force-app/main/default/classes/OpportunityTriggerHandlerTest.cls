/* Class:       OpportunityTriggerHandlerTest
 * Created On:  Feb 2018
 * Created by:  J. Pipkin (OpFocus, Inc)
 * Description: Test class for OpportunityTriggerHandler
 */

@isTest
public class OpportunityTriggerHandlerTest {
  @testSetup
  static void buildData() {
    DataFactory.setOnboardingDefaults();
    Carrier__c car = new Carrier__c();
    car.Name = 'test';
    insert car;
    Account a = DataFactory.buildAccount('Test Acct');
    a.Carrier__c = car.Id;
    insert a;
    List<Customer_Success_Rep__c> lstCSRs = new List<Customer_Success_Rep__c>();
    User ru = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    Id rid = [SELECT Id FROM UserRole WHERE Name = 'Customer Support Rep'].Id;
    System.runAs(ru) {
      User u1 = new User(
        ProfileId = UserInfo.getProfileId(),
        LastName = 'last1',
        Email = 'puser001+test@everquote.ai',
        Username = 'puser001+test@everquote.ai' + System.currentTimeMillis(),
        CompanyName = 'TEST',
        Title = 'title',
        Alias = 'alias',
        TimeZoneSidKey = 'America/Los_Angeles',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        UserRoleId = rid,
        Odie_Agent_ID__c = Integer.valueof((Math.random() * 10000))
      );

      User u2 = new User(
        ProfileId = UserInfo.getProfileId(),
        LastName = 'last2',
        Email = 'puser002+test@everquote.ai',
        Username = 'puser002+test@everquote.ai' + System.currentTimeMillis(),
        CompanyName = 'TEST',
        Title = 'title',
        Alias = 'alias',
        TimeZoneSidKey = 'America/Los_Angeles',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        UserRoleId = rid,
        Odie_Agent_ID__c = Integer.valueof((Math.random() * 10000))
      );

      User u3 = new User(
        ProfileId = UserInfo.getProfileId(),
        LastName = 'last3',
        Email = 'puser003+test@everquote.ai',
        Username = 'puser003+test@everquote.ai' + System.currentTimeMillis(),
        CompanyName = 'TEST',
        Title = 'title',
        Alias = 'alias',
        TimeZoneSidKey = 'America/Los_Angeles',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        UserRoleId = rid,
        Odie_Agent_ID__c = Integer.valueof((Math.random() * 10000))
      );

      User u4 = new User(
        ProfileId = UserInfo.getProfileId(),
        LastName = 'last4',
        Email = 'puser004+test@everquote.ai',
        Username = 'puser004+test@everquote.ai' + System.currentTimeMillis(),
        CompanyName = 'TEST',
        Title = 'title',
        Alias = 'alias',
        TimeZoneSidKey = 'America/Los_Angeles',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        UserRoleId = rid,
        Odie_Agent_ID__c = Integer.valueof((Math.random() * 10000))
      );

      User u5 = new User(
        ProfileId = UserInfo.getProfileId(),
        LastName = 'last5',
        Email = 'puser005+test@everquote.ai',
        Username = 'puser005+test@everquote.ai' + System.currentTimeMillis(),
        CompanyName = 'TEST',
        Life_Buyer__c = true,
        Title = 'title',
        Alias = 'alias',
        TimeZoneSidKey = 'America/Los_Angeles',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        UserRoleId = UserInfo.getUserRoleId(),
        Odie_Agent_ID__c = Integer.valueof((Math.random() * 10000))
      );

      User u6 = new User(
        ProfileId = UserInfo.getProfileId(),
        LastName = 'last6',
        Email = 'puser006+test@everquote.ai',
        Username = 'puser006+test@everquote.ai' + System.currentTimeMillis(),
        CompanyName = 'TEST',
        Life_Buyer__c = true,
        Title = 'title',
        Alias = 'alias',
        TimeZoneSidKey = 'America/Los_Angeles',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        UserRoleId = rid,
        Odie_Agent_ID__c = Integer.valueof((Math.random() * 10000))
      );

      User u7 = new User(
        ProfileId = UserInfo.getProfileId(),
        LastName = 'last7',
        Email = 'puser007+test@everquote.ai',
        Username = 'puser007+test@everquote.ai' + System.currentTimeMillis(),
        CompanyName = 'TEST',
        Life_Buyer__c = true,
        Title = 'title',
        Alias = 'alias',
        TimeZoneSidKey = 'America/Los_Angeles',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        UserRoleId = rid,
        Odie_Agent_ID__c = Integer.valueof((Math.random() * 10000))
      );

      insert new List<User>{ u1, u2, u3, u4, u5, u6, u7 };
    }
    Boolean nextUpSet1 = false, nextUpSet2 = false, nextUpSet3 = false;
    String[] ots = new List<String>{
      'IA/Growth',
      'IA/Growth',
      'Farmers',
      'Farmers',
      'Allstate',
      'Allstate'
    };
    Integer indx = 0;
    for (User u : [
      SELECT Id
      FROM User
      WHERE IsActive = true AND UserRole.Name = 'Customer Support Rep'
      ORDER BY LastName
      LIMIT 6
    ]) {
      Customer_Success_Rep__c csr = new Customer_Success_Rep__c();
      csr.User__c = u.Id;
      csr.Available__c = true;
      csr.Onboarding_Type__c = ots[indx];

      if (!nextUpSet1 && ots[indx] == 'IA/Growth') {
        csr.NextUp__c = true;
        nextUpSet1 = true;
      } else if (!nextUpSet2 && ots[indx] == 'Farmers') {
        csr.NextUp__c = true;
        nextUpSet2 = true;
      } else if (!nextUpSet2 && ots[indx] == 'Allstate') {
        csr.NextUp__c = true;
        nextUpSet3 = true;
      }
      lstCSRs.add(csr);
      indx++;
    }
    User lb = [SELECT Id FROM User WHERE Email = 'puser005+test@everquote.ai'];
    Customer_Success_Rep__c csr = new Customer_Success_Rep__c();
    csr.User__c = lb.Id;
    csr.Available__c = true;
    csr.Onboarding_Type__c = 'Life Buyer';
    csr.NextUp__c = true;
    lstCSRs.add(csr);
    insert lstCSRs;
  }

  //test methods
  static testMethod void testCreateNewOppWhenClosed() {
    Account a = [SELECT Id, Carrier__c FROM Account];

    Opportunity o1 = DataFactory.buildOpportunity('Test Opp 1', a.Id, 'Enrichment');
    o1.of_Apps__c = 1;
    insert o1;

    o1.StageName = 'Closed Won';
    update o1;

    System.assertEquals(2, [SELECT COUNT() FROM Opportunity WHERE AccountId = :a.Id]);
  }

  static testMethod void testCreateNewOppWhenClosed2() {
    Account a = [SELECT Id, Carrier__c FROM Account];

    Opportunity o1 = DataFactory.buildOpportunity('Test Opp 1', a.Id, 'Life');
    o1.of_Apps__c = 1;
    insert o1;

    o1.StageName = 'Closed Won';
    update o1;

    System.assertEquals(1, [SELECT COUNT() FROM Opportunity WHERE AccountId = :a.Id]);
  }

  static testMethod void testCreateNewOppWhenClosed3() {
    Account a = [SELECT Id, Carrier__c FROM Account];

    Opportunity o1 = DataFactory.buildOpportunity('Test Opp 1', a.Id, 'Enrichment');
    o1.of_Apps__c = 1;
    Opportunity o2 = DataFactory.buildOpportunity('Test Opp 1', a.Id, 'Enrichment');
    o2.of_Apps__c = 1;
    insert new List<Opportunity>{ o1, o2 };

    o1.StageName = 'Closed Won';
    update o1;

    System.assertEquals(2, [SELECT COUNT() FROM Opportunity WHERE AccountId = :a.Id]);
  }

  //static testMethod void singleOpp() {
  //	OnboardingSettings__c setting = OnboardingSettings__c.getOrgDefaults();
  //	setting.Onboard_Next_Opp__c = true;
  //	update setting;

  //	Customer_Success_Rep__c[] lstCSRs = [Select Id, User__c, NextUp__c from Customer_Success_Rep__c where Onboarding_Type__c = 'IA/Growth' Order By User__r.LastName];

  //Account a = [Select Id,Carrier__c from Account];

  //Opportunity o1 = DataFactory.buildOpportunity('Test Opp 1', a.Id, 'Agency');
  //insert o1;

  //	lstCSRs = [Select Id, User__c, NextUp__c from Customer_Success_Rep__c where Onboarding_Type__c = 'IA/Growth' Order By User__r.LastName];

  //	setting = OnboardingSettings__c.getOrgDefaults();

  //	o1 = [Select Id, Onboarding_Treatment__c,Onboarding_Owner__c,Customer_Success_Rep__c from Opportunity where Id=:o1.Id];
  //	System.assert(!setting.Onboard_Next_Opp__c,'Trigger did not update setting');
  //	System.assertEquals('Yes',o1.Onboarding_Treatment__c,'Trigger did not update opp correctly');
  //	System.assertEquals(lstCSRs[0].User__c, o1.Onboarding_Owner__c);
  //	System.assertEquals(lstCSRs[0].Id, o1.Customer_Success_Rep__c);
  //	System.assertEquals(true,lstCSRs[1].NextUp__c);
  //	System.assertEquals(false,lstCSRs[0].NextUp__c);
  //	Customer_Success_Rep__c[] lstOthers = [Select Id, User__c, NextUp__c from Customer_Success_Rep__c where Onboarding_Type__c = 'Farmers' Order By User__r.LastName];
  //	System.assert(lstOthers[0].NextUp__c);
  //}

  //static testMethod void singleOpp_lifebuyer() {
  //	OnboardingSettings__c setting = OnboardingSettings__c.getOrgDefaults();
  //	setting.Onboard_Next_Opp__c = true;
  //	update setting;

  //	Customer_Success_Rep__c[] lstCSRs = [Select Id, User__c, NextUp__c from Customer_Success_Rep__c where Onboarding_Type__c = 'Life Buyer' Order By User__r.LastName];

  //	Account a = [Select Id,Carrier__c from Account];

  //	Opportunity o1 = DataFactory.buildOpportunity('Test Opp 1', a.Id, 'Agency');
  //	o1.OwnerId = [Select Id from User where Email = 'puser005@testeverquote.com'].Id;
  //	insert o1;

  //	lstCSRs = [Select Id, User__c, NextUp__c from Customer_Success_Rep__c where Onboarding_Type__c = 'Life Buyer' Order By User__r.LastName];

  //	setting = OnboardingSettings__c.getOrgDefaults();

  //	o1 = [Select Id, Onboarding_Treatment__c,Onboarding_Owner__c,Customer_Success_Rep__c from Opportunity where Id=:o1.Id];
  //	System.assert(!setting.Onboard_Next_Opp__c,'Trigger did not update setting');
  //	System.assertEquals('Yes',o1.Onboarding_Treatment__c,'Trigger did not update opp correctly');
  //	System.assertEquals(lstCSRs[0].User__c, o1.Onboarding_Owner__c);
  //	System.assertEquals(lstCSRs[0].Id, o1.Customer_Success_Rep__c);
  //	System.assertEquals(true,lstCSRs[0].NextUp__c);
  //	Customer_Success_Rep__c[] lstOthers = [Select Id, User__c, NextUp__c from Customer_Success_Rep__c where Onboarding_Type__c = 'IA/Growth' Order By User__r.LastName];
  //	System.assert(lstOthers[0].NextUp__c);
  //}

  //static testMethod void singleOppLastOnboardOwner() {
  //	OnboardingSettings__c setting = OnboardingSettings__c.getOrgDefaults();
  //	setting.Onboard_Next_Opp__c = true;
  //	update setting;

  //	Customer_Success_Rep__c[] lstCSRs = [Select Id, User__c, NextUp__c from Customer_Success_Rep__c where Onboarding_Type__c = 'Farmers' Order By User__r.LastName];
  //	lstCSRs[0].NextUp__c = false;
  //	lstCSRs[1].NextUp__c = true;
  //	update lstCSRs;

  //	Account a = [Select Id from Account];
  //	Carrier__c car = new Carrier__c();
  //	car.Name = 'Farmers';
  //	insert car;
  //	a.Carrier__c = car.Id;
  //	update a;

  //	Opportunity o1 = DataFactory.buildOpportunity('Test Opp 1', a.Id, 'Agency');
  //	insert o1;

  //	lstCSRs = [Select Id, User__c, NextUp__c from Customer_Success_Rep__c where Onboarding_Type__c = 'Farmers' Order By User__r.LastName];

  //	setting = OnboardingSettings__c.getOrgDefaults();

  //	o1 = [Select Id, Onboarding_Treatment__c,Onboarding_Owner__c,Customer_Success_Rep__c from Opportunity where Id=:o1.Id];
  //	System.assert(!setting.Onboard_Next_Opp__c,'Trigger did not update setting');
  //	System.assertEquals('Yes',o1.Onboarding_Treatment__c,'Trigger did not update opp correctly');
  //	System.assertEquals(lstCSRs[lstCSRs.size() - 1].User__c, o1.Onboarding_Owner__c);
  //	System.assertEquals(lstCSRs[lstCSRs.size() - 1].Id, o1.Customer_Success_Rep__c);
  //	System.assertEquals(true,lstCSRs[0].NextUp__c);
  //	System.assertEquals(false,lstCSRs[lstCSRs.size() - 1].NextUp__c);
  //	a = [Select Id, Support_Rep__c from Account where Id =:a.Id];
  //	System.assertEquals(o1.Onboarding_Owner__c,a.Support_Rep__c);
  //}

  //static testMethod void singleOppLastOnboardOwner_allstate() {
  //	OnboardingSettings__c setting = OnboardingSettings__c.getOrgDefaults();
  //	setting.Onboard_Next_Opp__c = true;
  //	update setting;

  //	Customer_Success_Rep__c[] lstCSRs = [Select Id, User__c, NextUp__c from Customer_Success_Rep__c where Onboarding_Type__c = 'Allstate' Order By User__r.LastName];
  //	lstCSRs[0].NextUp__c = false;
  //	lstCSRs[1].NextUp__c = true;
  //	update lstCSRs;

  //	Account a = [Select Id from Account];
  //	Carrier__c car = new Carrier__c();
  //	car.Name = 'Allstate';
  //	insert car;
  //	a.Carrier__c = car.Id;
  //	update a;

  //	Opportunity o1 = DataFactory.buildOpportunity('Test Opp 1', a.Id, 'Agency');
  //	insert o1;

  //	lstCSRs = [Select Id, User__c, NextUp__c from Customer_Success_Rep__c where Onboarding_Type__c = 'Allstate' Order By User__r.LastName];

  //	setting = OnboardingSettings__c.getOrgDefaults();

  //	o1 = [Select Id, Onboarding_Treatment__c,Onboarding_Owner__c,Customer_Success_Rep__c from Opportunity where Id=:o1.Id];
  //	System.assert(!setting.Onboard_Next_Opp__c,'Trigger did not update setting');
  //	System.assertEquals('Yes',o1.Onboarding_Treatment__c,'Trigger did not update opp correctly');
  //	System.assertEquals(lstCSRs[lstCSRs.size() - 1].User__c, o1.Onboarding_Owner__c);
  //	System.assertEquals(lstCSRs[lstCSRs.size() - 1].Id, o1.Customer_Success_Rep__c);
  //	System.assertEquals(true,lstCSRs[0].NextUp__c);
  //	System.assertEquals(false,lstCSRs[lstCSRs.size() - 1].NextUp__c);
  //	a = [Select Id, Support_Rep__c from Account where Id =:a.Id];
  //	System.assertEquals(o1.Onboarding_Owner__c,a.Support_Rep__c);
  //}

  //static testMethod void singleUnqualifiedOpp() {

  //	Account a = [Select Id from Account];
  //	Opportunity o1 = DataFactory.buildOpportunity('Test Opp 1', a.Id, 'Life');
  //	insert o1;

  //	Customer_Success_Rep__c[] lstCSRs = [Select Id, User__c, NextUp__c from Customer_Success_Rep__c where Onboarding_Type__c = 'IA/Growth' Order By User__r.LastName];

  //	OnboardingSettings__c setting = OnboardingSettings__c.getOrgDefaults();
  //	o1 = [Select Id, Onboarding_Treatment__c,Onboarding_Owner__c,Customer_Success_Rep__c from Opportunity where Id=:o1.Id];
  //	System.assert(!setting.Onboard_Next_Opp__c,'Trigger did not update setting');
  //	System.assertEquals('No',o1.Onboarding_Treatment__c,'Trigger updated unqualified opp');
  //	System.assertEquals(null, o1.Onboarding_Owner__c);
  //	System.assertEquals(null, o1.Customer_Success_Rep__c);
  //	System.assertEquals(false,lstCSRs[1].NextUp__c);
  //	System.assertEquals(true,lstCSRs[0].NextUp__c);
  //}

  //static testMethod void singleUnqualifiedOpp2() {
  //	OnboardingSettings__c setting = OnboardingSettings__c.getOrgDefaults();
  //	setting.Onboard_Next_Opp__c = true;
  //	update setting;

  //	Customer_Success_Rep__c[] lstCSRs = [Select Id, User__c, NextUp__c from Customer_Success_Rep__c where Onboarding_Type__c = 'IA/Growth' Order By User__r.LastName];

  //	Carrier__c car = [Select Id,Exclude_from_Onboarding__c from Carrier__c];
  //	car.Exclude_from_Onboarding__c = true;
  //	update car;

  //	Account a = [Select Id from Account];
  //	Opportunity o1 = DataFactory.buildOpportunity('Test Opp 1', a.Id, 'Agency');
  //	insert o1;

  //	lstCSRs = [Select Id, User__c, NextUp__c from Customer_Success_Rep__c where Onboarding_Type__c = 'IA/Growth' Order By User__r.LastName];

  //	setting = OnboardingSettings__c.getOrgDefaults();

  //	o1 = [Select Id, Onboarding_Treatment__c,Onboarding_Owner__c,Customer_Success_Rep__c from Opportunity where Id=:o1.Id];
  //	System.assert(setting.Onboard_Next_Opp__c,'Trigger did not update setting');
  //	System.assertEquals(null,o1.Onboarding_Treatment__c,'Trigger updated unqualified opp');
  //	System.assertEquals(null, o1.Onboarding_Owner__c);
  //	System.assertEquals(null, o1.Customer_Success_Rep__c);
  //	System.assertEquals(false,lstCSRs[1].NextUp__c);
  //	System.assertEquals(true,lstCSRs[0].NextUp__c);
  //}

  //static testMethod void multiTransaction() {
  //	Account a = [Select Id from Account];
  //	Opportunity o1 = DataFactory.buildOpportunity('Test Opp 1', a.Id, 'Agency');
  //	insert o1;

  //	Customer_Success_Rep__c[] lstCSRs = [Select Id, User__c, NextUp__c from Customer_Success_Rep__c where Onboarding_Type__c = 'IA/Growth' Order By User__r.LastName];

  //	OnboardingSettings__c setting = OnboardingSettings__c.getOrgDefaults();
  //	o1 = [Select Id, Onboarding_Treatment__c,Onboarding_Owner__c,Customer_Success_Rep__c from Opportunity where Id=:o1.Id];
  //	System.assert(setting.Onboard_Next_Opp__c,'Trigger did not update setting');
  //	System.assertEquals('No',o1.Onboarding_Treatment__c,'Trigger did not update opp correctly');
  //	System.assertEquals(null, o1.Onboarding_Owner__c);
  //	System.assertEquals(null, o1.Customer_Success_Rep__c);
  //	System.assertEquals(false,lstCSRs[1].NextUp__c);
  //	System.assertEquals(true,lstCSRs[0].NextUp__c);

  //	Opportunity o2 = DataFactory.buildOpportunity('Test Opp 2', a.Id, 'Agency');
  //	insert o2;

  //	lstCSRs = [Select Id, User__c, NextUp__c from Customer_Success_Rep__c where Onboarding_Type__c = 'IA/Growth' Order By User__r.LastName];

  //	setting = OnboardingSettings__c.getOrgDefaults();
  //	o2 = [Select Id, Onboarding_Treatment__c,Onboarding_Owner__c,Customer_Success_Rep__c from Opportunity where Id=:o2.Id];
  //	System.assert(!setting.Onboard_Next_Opp__c,'Trigger did not update setting');
  //	System.assertEquals('Yes',o2.Onboarding_Treatment__c,'Trigger did not update opp correctly');
  //	System.assertEquals(lstCSRs[0].User__c, o2.Onboarding_Owner__c);
  //	System.assertEquals(lstCSRs[0].Id, o2.Customer_Success_Rep__c);
  //	System.assertEquals(true,lstCSRs[1].NextUp__c);
  //	System.assertEquals(false,lstCSRs[0].NextUp__c);
  //}

  //static testMethod void singleQualifiedOpp() {
  //	Account a = [Select Id from Account];
  //	Opportunity o1 = DataFactory.buildOpportunity('Test Opp 1', a.Id, 'Agency');
  //	Opportunity o2 = DataFactory.buildOpportunity('Test Opp 2', a.Id, 'Life');
  //	insert new Opportunity[]{o1,o2};

  //	Customer_Success_Rep__c[] lstCSRs = [Select Id, User__c, NextUp__c from Customer_Success_Rep__c where Onboarding_Type__c = 'IA/Growth' Order By User__r.LastName];

  //	OnboardingSettings__c setting = OnboardingSettings__c.getOrgDefaults();
  //	o1 = [Select Id, Onboarding_Treatment__c,Onboarding_Owner__c,Customer_Success_Rep__c from Opportunity where Id=:o1.Id];
  //	o2 = [Select Id, Onboarding_Treatment__c,Onboarding_Owner__c,Customer_Success_Rep__c from Opportunity where Id=:o2.Id];
  //	System.assert(setting.Onboard_Next_Opp__c,'Trigger did not update setting');
  //	System.assertEquals('No',o1.Onboarding_Treatment__c,'Trigger did not update opp correctly');
  //	System.assertEquals('No',o2.Onboarding_Treatment__c,'Trigger updated unqualified opp');
  //	System.assertEquals(null, o1.Onboarding_Owner__c);
  //	System.assertEquals(null, o1.Customer_Success_Rep__c);
  //	System.assertEquals(false,lstCSRs[1].NextUp__c);
  //	System.assertEquals(true,lstCSRs[0].NextUp__c);
  //}

  //static testMethod void multiQualifiedOpp() {
  //	Account a = [Select Id from Account];
  //	Opportunity o1 = DataFactory.buildOpportunity('Test Opp 1', a.Id, 'Agency');
  //	Opportunity o2 = DataFactory.buildOpportunity('Test Opp 2', a.Id, 'Agency');
  //	insert new Opportunity[]{o1,o2};

  //	Customer_Success_Rep__c[] lstCSRs = [Select Id, User__c, NextUp__c from Customer_Success_Rep__c where Onboarding_Type__c = 'IA/Growth' Order By User__r.LastName];

  //	OnboardingSettings__c setting = OnboardingSettings__c.getOrgDefaults();
  //	o1 = [Select Id, Onboarding_Treatment__c,Onboarding_Owner__c,Customer_Success_Rep__c from Opportunity where Id=:o1.Id];
  //	o2 = [Select Id, Onboarding_Treatment__c,Onboarding_Owner__c,Customer_Success_Rep__c from Opportunity where Id=:o2.Id];
  //	System.assert(!setting.Onboard_Next_Opp__c,'Trigger did not update setting');
  //	System.assertEquals('No',o1.Onboarding_Treatment__c,'Trigger did not update opp correctly');
  //	System.assertEquals('Yes',o2.Onboarding_Treatment__c,'Trigger did not update opp correctly');
  //	System.assertEquals(null, o1.Onboarding_Owner__c);
  //	System.assertEquals(null, o1.Customer_Success_Rep__c);
  //	System.assertEquals(lstCSRs[0].User__c, o2.Onboarding_Owner__c);
  //	System.assertEquals(lstCSRs[0].Id, o2.Customer_Success_Rep__c);
  //	System.assertEquals(true,lstCSRs[1].NextUp__c);
  //	System.assertEquals(false,lstCSRs[0].NextUp__c);
  //}
}