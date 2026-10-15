@isTest
public with sharing class ODAEAppControllerTests {
  private static final String LEAD_LASTNAME = 'Test ODA Lead';
  private static final String USER_EMAIL = 'TestODAUser@everquote.ai';

  @testSetup
  static void testSetup() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());
    createTestLead();
  }

  @isTest
  static void getEAppTest() {
    OdieRequestCalloutMock calloutMock = new OdieRequestCalloutMock();
    Test.setMock(HttpCalloutMock.class, calloutMock);

    Lead testLead = getTestLead();
    String quoteId = 'quote123123';
    Integer faceAmount = 15000;
    String carrier = 'lumico';
    String product = 'sife';

    Test.startTest();
    ODAEAppController.getEApp(testLead, quoteId, faceAmount, carrier, product);
    Test.stopTest();

    System.assertEquals(true, calloutMock.urlsRequestBody.containsKey('e_apps'));

    Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(
      calloutMock.urlsRequestBody.get('e_apps')
    );

    System.assertEquals((String) requestBody.get('eq_lead_uuid'), testLead.EqLeadUuid__c);
    System.assertEquals((String) requestBody.get('quote_id'), quoteId);
    System.assertEquals((String) requestBody.get('carrier'), carrier);
    System.assertEquals((String) requestBody.get('product_name'), product);
    System.assertEquals((String) requestBody.get('client'), 'salesforce');
  }

  @isTest
  static void loadPreviousApplications_no_oda_policy_throw_exception() {
    OdieRequestCalloutMock calloutMock = new OdieRequestCalloutMock();
    Test.setMock(HttpCalloutMock.class, calloutMock);

    Lead testLead = getTestLead();
    String carrier = 'lumico';
    String product = 'sife';

    Test.startTest();

    try {
      ODAEAppController.loadPreviousApplications(testLead, carrier, product);
    } catch (ODAException ex) {
      System.assertEquals('No previous application was found.', ex.getMessage());
    }

    Test.stopTest();
  }

  @isTest
  static void loadPreviousApplications_valid_request() {
    String quoteId = 'quote123123' + System.currentTimeMillis();

    OdieRequestCalloutMock calloutMock = new OdieRequestCalloutMock();
    List<Map<String, String>> response = new List<Map<String, String>>();
    response.add(new Map<String, String>{ 'face_amount' => '15000', 'quote_id' => quoteId });
    calloutMock.setMockStatusAndBody(200, JSON.serialize(response));
    Test.setMock(HttpCalloutMock.class, calloutMock);

    Test.setMock(HttpCalloutMock.class, calloutMock);

    Lead testLead = getTestLead();
    String carrier = 'lumico';
    String product = 'sife';

    ODA_Policy__c policy = new ODA_Policy__c(
      Name = 'N/A',
      Lead__c = testLead.Id,
      Carrier__c = carrier,
      Product__c = product,
      Quote_Id__c = quoteId,
      Coverage_Amount__c = 10000
    );

    Test.startTest();
    insert policy;
    Test.stopTest();

    List<Map<String, Object>> result = ODAEAppController.loadPreviousApplications(
      testLead,
      carrier,
      product
    );

    System.assertEquals(
      true,
      calloutMock.urlsRequestBody.containsKey(ODAEAppController.PREV_E_APPS_PATH)
    );

    Map<String, Object> requestParams = (Map<String, Object>) JSON.deserializeUntyped(
      calloutMock.urlsRequestBody.get(ODAEAppController.PREV_E_APPS_PATH)
    );

    List<String> quotesId = new List<String>();
    quotesId.add(policy.Quote_Id__c);

    System.assertEquals(carrier, (String) requestParams.get('carrier'));
    System.assertEquals(product, (String) requestParams.get('product'));
    System.assertEquals(testLead.EqLeadUuid__c, (String) requestParams.get('eq_lead_uuid'));
    System.assertEquals(JSON.serialize(quotesId), JSON.serialize(requestParams.get('quotes')));
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
        Modified__c,
        Height_new__c,
        Weight_new__c
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

    return testLead;
  }
}