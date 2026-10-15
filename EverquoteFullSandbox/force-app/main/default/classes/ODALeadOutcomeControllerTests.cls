@isTest
public with sharing class ODALeadOutcomeControllerTests {
  private static final String LEAD_LASTNAME = 'Test ODA Lead';
  private static final String USER_EMAIL = 'TestODAUser@everquote.ai';

  @testSetup
  static void testSetup() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());
    createTestLead();
  }

  @isTest
  static void getByIdTest() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());

    Lead testLead = getTestLead();
    Test.startTest();
    Lead l = ODALeadOutcomeController.getById(testLead.Id);
    Test.stopTest();

    System.assertEquals(testLead.EqLeadUuid__c, l.EqLeadUuid__c, 'wrong lead');
  }

  @isTest
  static void getLeadOutcomeOptionsTest() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());

    Test.startTest();
    String optionsString = ODALeadOutcomeController.getLeadOutcomeOptions();
    Test.stopTest();

    List<Map<String, String>> options = (List<Map<String, String>>) JSON.deserialize(
      optionsString,
      List<Map<String, String>>.class
    );

    System.assertEquals(false, options.isEmpty(), 'No options retrieved');
    System.assertEquals(true, options[0].containsKey('label'), 'Invalid response format');
    System.assertEquals(true, options[0].containsKey('value'), 'Invalid response format');
  }

  @isTest
  static void updateLeadOutcomeTest() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());

    Lead testLead = getTestLead();
    Test.startTest();
    Lead updatedLead = ODALeadOutcomeController.updateLeadOutcome(testLead.Id, 'Do Not Call');
    Test.stopTest();

    testLead = getTestLead();

    System.assertEquals('Do Not Call', testLead.Lead_Outcome__c, 'Lead outcome not updated');
  }

  private static Lead getTestLead() {
    return [
      SELECT
        Id,
        FirstName,
        LastName,
        Date_of_Birth__c,
        Use_Tobacco__c,
        State,
        Phone,
        Gender__c,
        Street,
        PostalCode,
        City,
        Email,
        EqLeadUuid__c,
        Lead_Outcome__c,
        Policy_Number__c
      FROM Lead
      WHERE LastName = :LEAD_LASTNAME
      LIMIT 1
    ];
  }

  private static Lead createTestLead() {
    RecordType r = [SELECT Id FROM RecordType WHERE DeveloperName = 'Life_Leads'];
    Lead testLead = new Lead(
      LastName = LEAD_LASTNAME,
      FirstName = 'Test',
      Date_of_Birth__c = Date.newInstance(1960, 2, 17),
      Use_Tobacco__c = true,
      State = 'GA',
      Gender__c = 'Male',
      Phone = '+12345678901',
      Street = '123 main st',
      PostalCode = '30002',
      City = 'Avondale Estates',
      Email = 'odalead@test.com',
      EqLeadUuid__c = '4ebb405e-1cb2-5507-855f-5b2616fd2d13',
      RecordTypeId = r.id,
      Lead_Outcome__c = 'App. Completed',
      Policy_Number__c = ''
    );

    insert testLead;

    return testLead;
  }
}