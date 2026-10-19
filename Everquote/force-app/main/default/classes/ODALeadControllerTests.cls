/*
 * ODALeadControllerTests.cls
 * - Tests ODA Requestor Controller functionality
 *
 * Created By:      Daniel Bailey (dbailey@opfocus.com)
 * Created Date:    Dec 11, 2019
 */

@isTest
public class ODALeadControllerTests {
  private static final String LEAD_LASTNAME = 'Test ODA Lead';
  private static final String USER_EMAIL = 'TestODAUser@everquote.ai';

  @testSetup
  static void testSetup() {
    createTestUser(USER_EMAIL);
  }

  @isTest
  static void pauseRecordingTest() {
    OdieRequestCalloutMock calloutMock = new OdieRequestCalloutMock();
    Test.setMock(HttpCalloutMock.class, calloutMock);

    Test.startTest();
    Lead lead = createTestLead();
    Test.stopTest();

    ODALeadController.pauseRecording(lead.Id);
    System.assertEquals(true, calloutMock.urlsRequestBody.containsKey('twilio/pause_recording'));
  }

  @isTest
  static void resumeRecordingTest() {
    OdieRequestCalloutMock calloutMock = new OdieRequestCalloutMock();
    Test.setMock(HttpCalloutMock.class, calloutMock);

    Test.startTest();
    Lead lead = createTestLead();
    Test.stopTest();

    ODALeadController.resumeRecording(lead.Id);
    System.assertEquals(true, calloutMock.urlsRequestBody.containsKey('twilio/resume_recording'));
  }

  @isTest
  static void findByIdTest() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());
    Test.startTest();
    createTestLead();
    Test.stopTest();
    Lead testLead = getTestLead();

    Lead l = ODALeadController.findById(testLead.Id);

    System.assertEquals(testLead.FirstName, l.FirstName, 'wrong lead');
  }

  @isTest
  static void saveLTInformationTest() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());
    Test.startTest();
    createTestLead();

    Lead testLead = getTestLead();
    testLead.Height_new__c = '70';
    testLead.weight_new__c = 222;
    update testLead;

    Test.stopTest();

    Lead l = ODALeadController.findById(testLead.Id);

    System.assertEquals(testLead.Height_new__c, '70');
    System.assertEquals(testLead.Weight_new__c, 222);
  }

  @isTest
  private static void saveBirthDate() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());
    Test.startTest();
    createTestLead();
    Test.stopTest();

    Lead testLead = getTestLead();
    Lead newLead = ODALeadController.saveBirthDate(testLead.Id, Date.Today());
    Lead updatedLead = getTestLead();
    system.assertEquals(
      updatedLead.Date_of_Birth__c,
      newLead.Date_of_Birth__c,
      'Birth date was not saved'
    );
  }

  @isTest
  private static void getQuotesTest() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());
    createTestLead();
    Lead testLead = getTestLead();
    Test.startTest();
    String quotes = ODALeadController.getQuotes(testLead, 'sife', null, 20000, 'standard');
    Test.stopTest();
    Map<String, Object> quotesJSON = (Map<String, Object>) JSON.deserializeUntyped(quotes);
    System.assertEquals(quotesJSON.keyset(), new Set<String>{ '19000', '20000', '21000' });
  }

  @isTest
  private static void getQuotesTest_SITERM() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());
    createTestLead();
    Lead testLead = getTestLead();

    Test.startTest();
    String quotes = ODALeadController.getQuotes(testLead, 'siterm', null, 200, null);
    Test.stopTest();
    Map<String, Object> quotesJSON = (Map<String, Object>) JSON.deserializeUntyped(quotes);
    System.assertEquals(quotesJSON.keyset(), new Set<String>{ '200' });
  }

  @isTest
  private static void getQuotesTest_TERM19() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());
    createTestLead();
    Lead testLead = getTestLead();

    Test.startTest();
    String quotes = ODALeadController.getQuotes(testLead, 'term19', null, 200, null);
    Test.stopTest();
    Map<String, Object> quotesJSON = (Map<String, Object>) JSON.deserializeUntyped(quotes);
    System.assertEquals(quotesJSON.keyset(), new Set<String>{ '200' });
  }

  @isTest
  private static void getRatesTest_SITerm() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());
    createTestLead();
    Lead testLead = getTestLead();

    Test.startTest();
    String temp = ODALeadController.getRates(testLead, 'siterm', null, null, null);
    Map<String, Object> rates = (Map<String, Object>) JSON.deserializeUntyped(temp);
    Test.stopTest();

    System.assertEquals(
      rates.keyset(),
      new Set<String>{ '25', '50', '100', '150', '200', '250', '300', '350', '400', '450', '500' }
    );
  }

  @isTest
  private static void getRatesTest_LevelTerm() {
    OdieRequestCalloutMock calloutMock = new OdieRequestCalloutMock();
    Test.setMock(HttpCalloutMock.class, calloutMock);
    createTestLead();
    Lead testLead = getTestLead();

    List<Integer> amounts = new List<Integer>{ 25000 };

    Test.startTest();
    String temp = ODALeadController.getRates(testLead, 'term19', amounts, null, null);
    Map<String, Object> rates = (Map<String, Object>) JSON.deserializeUntyped(temp);
    Test.stopTest();

    Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(
      calloutMock.urlsRequestBody.get('carriers/lumico/products/term19/rate_lookup')
    );

    String amountBandString = JSON.serialize(requestBody.get('amount_band'));

    List<Integer> amountBand = (List<Integer>) JSON.deserialize(
      amountBandString,
      List<Integer>.class
    );
    System.assertEquals(amountBand, amounts);

    System.assertEquals(testLead.State, requestBody.get('state'));
    System.assertEquals(testLead.EqLeadUuid__c, requestBody.get('eq_lead_uuid'));
    System.assertEquals(testLead.Gender__c.substring(0, 1), requestBody.get('gender'));
  }

  @isTest
  private static void getRatesTest_SIFE() {
    OdieRequestCalloutMock calloutMock = new OdieRequestCalloutMock();

    Map<String, Object> response = new Map<String, Object>{ 'rate_per_thousand' => 10 };

    calloutMock.setMockStatusAndBody(200, JSON.serialize(response));
    Test.setMock(HttpCalloutMock.class, calloutMock);
    createTestLead();
    Lead testLead = getTestLead();

    Test.startTest();
    String temp = ODALeadController.getRates(testLead, 'sife', null, null, 'modified');
    Map<String, Object> rates = (Map<String, Object>) JSON.deserializeUntyped(temp);
    Test.stopTest();

    System.assertEquals(
      true,
      calloutMock.urlsRequestBody.containsKey(
        'carriers/lumico/products/sife/rate_lookup?age=' +
        testLead.Age__c +
        '&gender=Male&tobacco=Yes&risk_class=modified'
      )
    );

    System.assertEquals(50, ((Map<String, Object>) rates.get('5000')).get('premium'));
    System.assertEquals(100, ((Map<String, Object>) rates.get('10000')).get('premium'));
    System.assertEquals(150, ((Map<String, Object>) rates.get('15000')).get('premium'));
  }

  @isTest
  private static void processOdieRequestSuccessTest() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());
    createTestLead();

    Test.startTest();
    String result = ODALeadController.processOdieRequest('{}', 'end-point');
    Test.stopTest();
    Map<String, Object> resultJSON = (Map<String, Object>) JSON.deserializeUntyped(result);
    System.assertEquals('test', resultJSON.get('example'), 'Invalid response');
  }

  @isTest
  private static void processOdieRequestFailureTest() {
    Integer errorStatusCode = 422;
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock(errorStatusCode));

    createTestLead();
    Test.startTest();
    String result = ODALeadController.processOdieRequest('{}', 'end-point');
    Test.stopTest();
    System.assertEquals('{}', result, 'Invalid response');
  }

  @isTest
  private static void saveAdditionalLevelTermInformationTest() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());
    Lead testLead = createTestLead();

    Test.startTest();
    ODALeadController.saveAdditionalLevelTermInformation(testLead.Id, '71', 150);
    Test.stopTest();
    Lead updatedLead = getTestLead();
    System.assertEquals(updatedLead.Height_new__c, '71');
    System.assertEquals(updatedLead.Weight_new__c, 150);
  }

  @isTest
  private static void saveLeadRequiredInformationTest() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());
    Lead testLead = createTestLead();

    Test.startTest();
    Lead newLead = ODALeadController.saveLeadRequiredInformation(
      testLead.Id,
      'Male',
      'CA',
      Date.Today()
    );
    Test.stopTest();
    Lead updatedLead = getTestLead();
    System.assertEquals(updatedLead.Gender__c, 'Male', 'Gender was not saved');
    System.assertEquals(updatedLead.State, 'CA', 'Sate was not saved');
    System.assertEquals(
      updatedLead.Date_of_Birth__c,
      newLead.Date_of_Birth__c,
      'Birth date was not saved'
    );
  }

  @isTest
  private static void buildLevelTermRatesRequestBodyTest() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());
    Lead testLead = new Lead(
      LastName = LEAD_LASTNAME,
      FirstName = 'Test',
      State = 'CA',
      Gender__c = 'Male',
      Date_of_Birth__c = Date.newInstance(1960, 2, 17),
      EqLeadUuid__c = 'e0aa6002-8b21-5edf-b404-0107e017c678',
      Use_Tobacco__c = true,
      Major_Condition_Past_Year__c = 'Yes',
      Height_new__c = '71',
      Weight_new__c = 150
    );

    List<Integer> amounts = new List<Integer>{ 1000, 2000, 3000 };
    String riskClass = 'riskClass';

    Map<String, Object> levelTermRatesRequest = ODALeadController.buildLevelTermRatesRequestBody(
      testLead,
      amounts,
      riskClass
    );

    System.assertEquals((String) levelTermRatesRequest.get('state'), testLead.State);
    System.assertEquals((String) levelTermRatesRequest.get('gender'), 'M');
    System.assertEquals((List<Integer>) levelTermRatesRequest.get('amount_band'), amounts);
    System.assertEquals((Boolean) levelTermRatesRequest.get('has_major_condition'), true);
    System.assertEquals((String) levelTermRatesRequest.get('risk_class'), riskClass);
  }

  @isTest
  private static void getRiderRatesTest() {
    OdieRequestCalloutMock calloutMock = new OdieRequestCalloutMock();
    Test.setMock(HttpCalloutMock.class, calloutMock);
    Integer age = 55;
    String product = 'siterm';
    Integer termLength = 10;
    Boolean tobacco = false;
    Integer faceAmount = 50000;
    Rider rider = new Rider();
    rider.product = 'dc';
    rider.amount = 1000;
    rider.units = 3;

    Test.startTest();

    ODALeadController.getRiderRates(age, product, termLength, tobacco, faceAmount, rider);

    System.assertEquals(
      true,
      calloutMock.urlsRequestBody.containsKey('riders/' + rider.product + '/rates')
    );
  }

  @isTest
  private static void processODARequestTest() {
    OdieRequestCalloutMock calloutMock = new OdieRequestCalloutMock();
    Map<String, Object> response = new Map<String, Object>{
      'business_rule' => 'Business rule 001'
    };
    calloutMock.setMockStatusAndBody(400, JSON.serialize(response));
    Test.setMock(HttpCalloutMock.class, calloutMock);

    Map<String, Object> requestParams = new Map<String, Object>{ 'data' => 'test' };
    HttpRequest req = new HttpRequest();
    req.setMethod('POST');
    req.setBody(JSON.serialize(requestParams));

    Test.startTest();
    try {
      ODALeadController.processODARequest(req, '/test');
    } catch (ODABusinessRuleException ex) {
      System.assertEquals(response.get('business_rule'), ex.getMessage());
    }

    Test.stopTest();
  }

  @IsTest
  private static void getQuoteIncludingRidersSIFETest() {
    OdieRequestCalloutMock calloutMock = new OdieRequestCalloutMock();
    Test.setMock(HttpCalloutMock.class, calloutMock);
    Lead testLead = createTestLead();
    String product = 'sife';
    Integer faceAmount = 12000;
    String riskClass = 'Standard';

    Rider rider = new Rider();
    rider.amount = 10000;
    rider.product = 'DC';
    rider.units = 8;
    List<Rider> riders = new List<Rider>{ rider };

    Test.startTest();
    ODALeadController.getQuoteIncludingRiders(
      testLead,
      product,
      null,
      faceAmount,
      riskClass,
      riders
    );
    Test.stopTest();

    Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(
      calloutMock.urlsRequestBody.get('quotes')
    );

    Map<String, Object> consumerData = (Map<String, Object>) requestBody.get('consumer_data');

    String ridersString = JSON.serialize(consumerData.get('riders'));

    List<Rider> ridersOutput = (List<Rider>) JSON.deserialize(ridersString, List<Rider>.class);
    System.assertEquals(ridersOutput[0].amount, rider.amount);
    System.assertEquals(ridersOutput[0].product, rider.product);
    System.assertEquals(ridersOutput[0].units, rider.units);
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

  // Helper method to query our test user
  private static User getTestUser() {
    return [SELECT Id, LumicoID__c FROM User WHERE Username = :USER_EMAIL LIMIT 1];
  }

  private static User createTestUser(String email) {
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
    String lastName = 'Testing ' + System.currentTimeMillis();
    User user = new User(
      Alias = 'TLTTU',
      Email = email,
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LastName = lastName,
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/New_York',
      Username = email,
      Odie_Agent_ID__c = Integer.valueof((Math.random() * 10000))
    );

    insert user;

    return user;
  }

  private static Lead createTestLead() {
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
      Modified__c = false,
      Twilio_Task_Sid__c = 'WT61d5f8963a65138209c6df474b9f052f'
    );

    insert testLead;

    return testLead;
  }
}