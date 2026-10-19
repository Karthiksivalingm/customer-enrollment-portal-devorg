/*
 * ODANewLifeLeadControllerTest.cls
 * - Tests ODA New Life Lead Controller functionality
 *
 * Created By:      Jacob Murphy (jmurphy@everquote.com)
 * Created Date:    Feb 19, 2020
 */

@isTest
public class ODANewLifeLeadControllerTest {
  private static final String LEAD_LASTNAME = 'Test ODA Lead';
  private static final String USER_EMAIL = 'TestODAUser@test.com';
  private static final String FORM_PUBLIC_UUID = 'd27c553b-77a4-40a3-87e5-db689af2bbbc';
  private static final String EQ_LEAD_UUID = '4ebb405e-1cb2-5507-855f-5b2616fd2d13';
  private static RecordType r = [SELECT Id FROM RecordType WHERE DeveloperName = 'Life_Leads'];

  private static Lead testLead = new Lead(
    LastName = LEAD_LASTNAME,
    FirstName = 'Test',
    Date_of_Birth__c = Date.newInstance(1960, 2, 17),
    Use_Tobacco__c = true,
    State = 'GA',
    Gender__c = 'Male',
    Phone = '+12345678901',
    Major_Condition_Past_Year__c = 'No',
    Street = '123 Main St',
    PostalCode = '30002',
    City = 'Cambridge',
    Email = USER_EMAIL,
    Weight__c = '123',
    Height__c = '5\'5"',
    Marital_Status__c = 'Married',
    RecordTypeId = r.id,
    Modified__c = false,
    Oda_New_Lead_Source__c = 'Referral from this lead'
  );

  @isTest
  private static void createNewLifeLeadTest() {
    OdieRequestCalloutMock requestMock = new OdieRequestCalloutMock();
    Map<String, Object> mockedResponse = new Map<String, Object>{
      'public_uuid' => FORM_PUBLIC_UUID,
      'eq_lead_uuid' => EQ_LEAD_UUID
    };
    requestMock.setMockStatusAndBody(200, JSON.serialize(mockedResponse));
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());
    Test.startTest();
    Id newLeadId = ODANewLifeLeadController.createNewLifeLead(testLead);
    Test.stopTest();

    String newLeadIdStr = Id.valueOf(newLeadId);

    Lead l = getTestLead();
    String testLeadIdStr = Id.valueOf(l.Id);

    // must compare as strings since Id type uses object equality, not value equality
    System.assertEquals(newLeadIdStr, testLeadIdStr, 'Lead Ids do not match');
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
        Street,
        PostalCode,
        City,
        Email,
        Weight__C,
        Height__c,
        EqLeadUuid__c,
        Marital_Status__c,
        Lumico_Quote_ID__c,
        Modified__c,
        Oda_New_Lead_Source__c
      FROM Lead
      WHERE Email = :USER_EMAIL
      LIMIT 1
    ];
  }
}