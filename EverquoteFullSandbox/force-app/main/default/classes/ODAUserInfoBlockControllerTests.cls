@isTest
public class ODAUserInfoBlockControllerTests {
  private static final String LEAD_LASTNAME = 'Test ODA Lead';
  private static final String USER_EMAIL = 'TestODAUser@everquote.ai';

  @testSetup
  private static void testSetup() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());

    RecordType r = [SELECT Id FROM RecordType WHERE DeveloperName = 'Life_Leads'];

    // Create a lead to associated tasks to
    Lead testLead = new Lead(
      LastName = LEAD_LASTNAME,
      FirstName = 'Test',
      Date_of_Birth__c = Date.newInstance(1960, 2, 17),
      Use_Tobacco__c = true,
      State = 'GA',
      Gender__c = 'Male',
      Phone = '+12345678901',
      Major_Condition_Past_Year__c = 'No',
      Street = '123 main st',
      PostalCode = '30002',
      City = 'Avondale Estates',
      Email = 'odalead@test.com',
      Weight__c = '123',
      Height__c = '5\'5"',
      EqLeadUuid__c = '4ebb405e-1cb2-5507-855f-5b2616fd2d13',
      Marital_Status__c = 'Married',
      RecordTypeId = r.id,
      Modified__c = false
    );

    insert testLead;
  }

  private static Lead getTestLead() {
    return [
      SELECT
        Id,
        FirstName,
        LastName,
        Coverage_Amount__c,
        Date_of_Birth__c,
        Use_Tobacco__c,
        State,
        Phone,
        Gender__c,
        Major_Condition_Past_Year__c,
        Age__c,
        Street,
        PostalCode,
        City,
        Email,
        Weight__C,
        Height__c,
        EqLeadUuid__c,
        Marital_Status__c,
        Lumico_Quote_ID__c,
        Modified__c
      FROM Lead
      WHERE LastName = :LEAD_LASTNAME
      LIMIT 1
    ];
  }

  @isTest
  private static void testGetLeadUserInfo() {
    Lead testLead = getTestLead();

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());
    OdaUserInfoBlockController.LeadAndFieldSet l = OdaUserInfoBlockController.getLeadUserInfo(
      testLead.Id
    );

    System.debug(l.lead.Id);
    Test.stopTest();
    system.assertEquals(testLead.Id, l.lead.Id, 'We were not returned the correct lead.');
  }
}