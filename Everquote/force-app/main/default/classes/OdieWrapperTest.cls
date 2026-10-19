/*
 * OdieWrapperTest.cls
 * - Tests the wrapper around Odie endpoints
 *
 * Created By:     Jacob Murphy (jmurphy@everquote.com)
 * Created Date:    Feb 18, 2020
 */

@isTest
public class OdieWrapperTest {
  private static final String LEAD_LASTNAME = 'Test ODA Lead';
  private static final String FORM_PUBLIC_UUID = '743d8ee9-d1fd-4db0-bf87-74f436b7883a';

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
      Street = '123 Main St',
      PostalCode = '30002',
      City = 'Avondale Estates',
      Email = 'odalead@test.com',
      Weight__c = '123',
      Height__c = '5\'5"',
      Marital_Status__c = 'Married',
      RecordTypeId = r.id,
      Modified__c = false,
      Oda_New_Lead_Source__c = 'Referral from this lead'
    );

    insert testLead;
  }

  @isTest
  private static void createFormTest() {
    Lead testLead = getTestLead();

    OdieRequestCalloutMock requestMock = new OdieRequestCalloutMock();
    Map<String, Object> mockedResponse = new Map<String, Object>{
      'public_uuid' => FORM_PUBLIC_UUID
    };
    requestMock.setMockStatusAndBody(200, JSON.serialize(mockedResponse));

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, requestMock);
    Map<String, Object> formData = OdieWrapper.createForm(testLead);
    Test.stopTest();

    System.assertEquals(FORM_PUBLIC_UUID, formData.get('public_uuid'), 'Invalid form response');
  }

  @isTest
  private static void createLeadTest() {
    Lead testLead = getTestLead();
    String testEqLeadUuid = 'aaa114fc-09ae-44c6-9e6a-6604219dcb98';

    OdieRequestCalloutMock requestMock = new OdieRequestCalloutMock();
    Map<String, Object> mockedResponse = new Map<String, Object>{
      'eq_lead_uuid' => testEqLeadUuid
    };
    requestMock.setMockStatusAndBody(200, JSON.serialize(mockedResponse));

    Test.setMock(HttpCalloutMock.class, requestMock);
    Test.startTest();
    Map<String, Object> leadData = OdieWrapper.createLead(FORM_PUBLIC_UUID, testLead);
    Test.stopTest();

    System.assertEquals(testEqLeadUuid, leadData.get('eq_lead_uuid'), 'Invalid lead response');
  }

  @isTest
  private static void updateFormDispositionTest() {
    Lead testLead = getTestLead();

    OdieRequestCalloutMock requestMock = new OdieRequestCalloutMock();
    Map<String, Object> mockedResponse = new Map<String, Object>{ 'message' => 'Successful' };
    requestMock.setMockStatusAndBody(200, JSON.serialize(mockedResponse));

    Test.setMock(HttpCalloutMock.class, requestMock);
    Test.startTest();
    OdieWrapper.updateFormDisposition(testLead.Id);
    Test.stopTest();

    System.assertEquals(mockedResponse.get('message'), 'Successful', 'Invalid lead response');
  }

  @isTest
  private static void createRecordsForNewSalesforceLeadTest() {
    Lead testLead = getTestLead();
    String testEqLeadUuid = 'aaa114fc-09ae-44c6-9e6a-6604219dcb98';

    OdieRequestCalloutMock requestMock = new OdieRequestCalloutMock();
    Map<String, Object> mockedResponse = new Map<String, Object>{
      'public_uuid' => FORM_PUBLIC_UUID,
      'eq_lead_uuid' => testEqLeadUuid
    };
    requestMock.setMockStatusAndBody(200, JSON.serialize(mockedResponse));

    Test.setMock(HttpCalloutMock.class, requestMock);
    Test.startTest();
    String returnedEqLeadUuid = OdieWrapper.createRecordsForNewSalesforceLead(testLead);
    Test.stopTest();

    Lead updatedTestLead = getTestLead();

    System.assertEquals(testEqLeadUuid, returnedEqLeadUuid, 'Incorrect EqLeadUuid__c');
  }

  @isTest
  private static void processOdieRequestSuccessTest() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());
    Test.startTest();
    String result = OdieWrapper.processOdieRequest('{}', 'end-point');
    Test.stopTest();
    Map<String, Object> resultJSON = (Map<String, Object>) JSON.deserializeUntyped(result);
    System.assertEquals('test', resultJSON.get('example'), 'Invalid response');
  }

  @isTest
  private static void processOdieRequestFailureTest() {
    Integer errorStatusCode = 422;
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock(errorStatusCode));
    Test.startTest();
    String result = OdieWrapper.processOdieRequest('{}', 'end-point');
    Test.stopTest();
    System.assertEquals('{}', result, 'Invalid response');
  }

  @isTest
  private static void syncLeadOwnerToOdieTest() {
    Lead testLead = getTestLead();

    OdieRequestCalloutMock requestMock = new OdieRequestCalloutMock();
    Map<String, Object> mockedResponse = new Map<String, Object>{ 'message' => 'Successful' };
    requestMock.setMockStatusAndBody(200, JSON.serialize(mockedResponse));

    Test.setMock(HttpCalloutMock.class, requestMock);
    Test.startTest();
    OdieWrapper.syncLeadOwnerToOdieFuture(new List<Id>{ testLead.Id });
    Test.stopTest();

    System.assertEquals(mockedResponse.get('message'), 'Successful', 'Invalid lead response');
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
        Currently_Insured__c,
        DUI_Conviction__c,
        Residency__c,
        Military_Affiliation__c,
        What_is_your_major_condition__c,
        Occupation__c,
        Coverage_Type__c,
        OriginalEqLeadUuid__c,
        Owner.Email,
        Owner.Name,
        Assigned_Date__c,
        Oda_New_Lead_Source__c
      FROM Lead
      WHERE LastName = :LEAD_LASTNAME
      LIMIT 1
    ];
  }
}