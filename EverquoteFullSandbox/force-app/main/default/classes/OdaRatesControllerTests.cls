@isTest
public with sharing class OdaRatesControllerTests {
  @testSetup
  static void testSetup() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());
    addTestLead();
  }

  @isTest
  private static void requestBuilder_faceAmountsTest() {
    // Validate that face amounts is an empty list for the following products
    // Test added to increase builders files coverage
    OdaLumicoWlRatesRequestBuilder wlBuilder = new OdaLumicoWlRatesRequestBuilder();
    System.assertEquals(new List<Integer>(), wlBuilder.faceAmounts());

    OdaReliashieldRateRequestBuilder reliashieldBuilder = new OdaReliashieldRateRequestBuilder();
    System.assertEquals(new List<Integer>(), reliashieldBuilder.faceAmounts());
  }

  @isTest
  private static void missingCarrierTest() {
    Lead testLead = getTestLead();

    try {
      OdaRateLookupData rateLookup = new OdaRateLookupData();
      rateLookup.carrier = '';
      rateLookup.product = 'giwl';
      rateLookup.lead = testLead;

      commonRatesTest(testLead, rateLookup);
    } catch (ODAException ex) {
      System.assertEquals(
        'Unable to create rates request path. Missing carrier or product. carrier: "", product: "giwl"',
        ex.getMessage()
      );
    }
  }

  @isTest
  private static void getLumicoAdRatesTest() {
    OdieRequestCalloutMock calloutMock = new OdieRequestCalloutMock();
    Test.setMock(HttpCalloutMock.class, calloutMock);

    Lead testLead = getTestLead();

    OdaRateLookupData rateLookup = new OdaRateLookupData();
    rateLookup.lead = testLead;
    rateLookup.carrier = 'lumico';
    rateLookup.product = 'ad';

    Test.startTest();
    OdaRatesController.getRates(rateLookup);

    String requestPath = getRequestPath(rateLookup.carrier, rateLookup.product);
    Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(
      calloutMock.urlsRequestBody.get(requestPath)
    );
  }

  @isTest
  private static void getLumicoWlRatesTest() {
    OdieRequestCalloutMock calloutMock = new OdieRequestCalloutMock();
    Test.setMock(HttpCalloutMock.class, calloutMock);

    Lead testLead = getTestLead();

    OdaRateLookupData rateLookup = new OdaRateLookupData();
    rateLookup.lead = testLead;
    rateLookup.carrier = 'lumico';
    rateLookup.product = 'wl';
    rateLookup.amounts = new List<Integer>{ 30000, 50000, 100000 };
    rateLookup.riskClass = 'STD';

    Test.startTest();
    OdaRatesController.getRates(rateLookup);

    String requestPath = getRequestPath(rateLookup.carrier, rateLookup.product);
    Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(
      calloutMock.urlsRequestBody.get(requestPath)
    );

    System.assertEquals((String) requestBody.get('state'), testLead.State);
    System.assertEquals((String) requestBody.get('risk_class'), rateLookup.riskClass);

    String amountBandString = JSON.serialize(requestBody.get('amount_band'));
    List<Integer> amounts = (List<Integer>) JSON.deserialize(amountBandString, List<Integer>.class);
    System.assertEquals(amounts, rateLookup.amounts);

    Test.stopTest();
  }

  @isTest
  private static void getAigRatesTest() {
    Lead testLead = getTestLead();

    OdaRateLookupData rateLookup = new OdaRateLookupData();
    rateLookup.carrier = 'aig';
    rateLookup.product = 'giwl';
    rateLookup.lead = testLead;

    commonRatesTest(testLead, rateLookup);
  }

  @isTest
  private static void getGerberRatesTest() {
    Lead testLead = getTestLead();

    OdaRateLookupData rateLookup = new OdaRateLookupData();
    rateLookup.carrier = 'gerber';
    rateLookup.product = 'gife';
    rateLookup.lead = testLead;

    commonRatesTest(testLead, rateLookup);
  }

  @isTest
  private static void getReliashieldRatesTest() {
    OdieRequestCalloutMock calloutMock = new OdieRequestCalloutMock();
    Test.setMock(HttpCalloutMock.class, calloutMock);

    Lead testLead = getTestLead();

    OdaRateLookupData rateLookup = new OdaRateLookupData();
    rateLookup.carrier = 'reliashield';
    rateLookup.product = 'essential-individual';
    rateLookup.lead = testLead;

    Test.startTest();
    OdaRatesController.getRates(rateLookup);

    String requestPath = getRequestPath(rateLookup.carrier, rateLookup.product);

    Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(
      calloutMock.urlsRequestBody.get(requestPath)
    );

    System.assertEquals((String) requestBody.get('product'), rateLookup.product);

    Test.stopTest();
  }

  private static void commonRatesTest(Lead tetLead, OdaRateLookupData rateLookup) {
    OdieRequestCalloutMock calloutMock = new OdieRequestCalloutMock();
    Test.setMock(HttpCalloutMock.class, calloutMock);

    Test.startTest();
    OdaRatesController.getRates(rateLookup);

    String requestPath = getRequestPath(rateLookup.carrier, rateLookup.product);

    Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(
      calloutMock.urlsRequestBody.get(requestPath)
    );

    System.assertEquals((Integer) requestBody.get('age'), (Integer) rateLookup.lead.Age__c);
    System.assertEquals((String) requestBody.get('gender'), 'Male');
    System.assertEquals((String) requestBody.get('product'), rateLookup.product);

    String faceAmountsString = JSON.serialize(requestBody.get('face_amounts'));
    List<Integer> faceAmounts = (List<Integer>) JSON.deserialize(
      faceAmountsString,
      List<Integer>.class
    );
    System.assertEquals(new List<Integer>{ 5000, 10000, 15000, 20000, 25000 }, faceAmounts);
    Test.stopTest();
  }

  private static void addTestLead() {
    RecordType r = [SELECT Id FROM RecordType WHERE DeveloperName = 'Life_Leads'];

    Lead testLead = new Lead(
      LastName = 'OdaRatesControllerTests',
      FirstName = 'Test',
      Date_of_Birth__c = Date.newInstance(1960, 2, 17),
      Use_Tobacco__c = true,
      Phone = '+13336668888',
      State = 'GA',
      Gender__c = 'Male',
      Street = '123 main st',
      PostalCode = '30002',
      City = 'Avondale Estates',
      Email = 'odalead@test.com',
      Weight__c = '123',
      Height__c = '5\'5"',
      Height_new__c = '78',
      Weight_new__c = 240,
      EqLeadUuid__c = '4ebb405e-1cb2-5507-855f-5b2616fd2d13',
      Marital_Status__c = 'Married',
      RecordTypeId = r.id,
      Modified__c = false,
      Major_Condition_Past_Year__c = 'Yes'
    );

    insert testLead;
  }

  private static String getRequestPath(String carrier, String product) {
    return 'carriers/' + carrier + '/products/' + product + '/rate_lookup';
  }

  private static Lead getTestLead() {
    return [
      SELECT
        Id,
        Date_of_Birth__c,
        Gender__c,
        Age__c,
        EqLeadUuid__c,
        State,
        Use_Tobacco__c,
        Modified__c,
        Major_Condition_Past_Year__c,
        Height_new__c,
        Weight_new__c
      FROM Lead
      WHERE LastName = 'OdaRatesControllerTests'
      LIMIT 1
    ];
  }
}