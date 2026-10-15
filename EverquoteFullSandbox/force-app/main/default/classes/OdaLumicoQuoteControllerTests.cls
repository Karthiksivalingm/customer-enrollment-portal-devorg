@isTest
public class OdaLumicoQuoteControllerTests {
  private static final String LEAD_LASTNAME = 'Test ODA Lead';
  private static final String USER_EMAIL = 'TestODAUser@everquote.ai';

  @testSetup
  static void testSetup() {
    createTestUser(USER_EMAIL);
  }

  @isTest
  static void lumico_getQuotes_product_not_supported() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());
    Test.startTest();
    createTestLead();
    Test.stopTest();

    try {
      OdaQuoteRequestData quoteRequestData = new OdaQuoteRequestData();
      quoteRequestData.product = 'dummy';
      OdaLumicoQuoteController.getQuotes(quoteRequestData);
    } catch (ODAException ex) {
      System.assertEquals('Lumico product not yet supported', ex.getMessage());
    }
  }

  @isTest
  static void lumico_ad_getQuotes() {
    OdieRequestCalloutMock calloutMock = new OdieRequestCalloutMock();
    Test.setMock(HttpCalloutMock.class, calloutMock);

    Test.startTest();
    createTestLead();
    Test.stopTest();

    Lead testLead = getTestLead();
    OdaQuoteRequestData quoteRequestData = new OdaQuoteRequestData();

    quoteRequestData.lead = testLead;
    quoteRequestData.faceAmount = 1000;
    quoteRequestData.carrier = 'lumico';
    quoteRequestData.product = 'ad';

    OdaLumicoQuoteController.getQuotes(quoteRequestData);

    System.assertEquals(true, calloutMock.urlsRequestBody.containsKey('quotes'));

    Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(
      calloutMock.urlsRequestBody.get('quotes')
    );

    Map<String, Object> consumerData = (Map<String, Object>) requestBody.get('consumer_data');

    System.assertEquals((String) consumerData.get('eq_lead_uuid'), testLead.EqLeadUuid__c);
    System.assertEquals((Integer) consumerData.get('face_amount'), quoteRequestData.faceAmount);
    System.assertEquals((String) consumerData.get('carrier'), quoteRequestData.carrier);
    System.assertEquals((String) consumerData.get('product_name'), quoteRequestData.product);
    System.assertEquals((String) requestBody.get('client'), 'salesforce');
  }

  @isTest
  static void lumico_wl_getQuotes() {
    OdieRequestCalloutMock calloutMock = new OdieRequestCalloutMock();
    Test.setMock(HttpCalloutMock.class, calloutMock);

    Test.startTest();
    createTestLead();
    Test.stopTest();

    Lead testLead = getTestLead();
    OdaQuoteRequestData quoteRequestData = new OdaQuoteRequestData();

    quoteRequestData.lead = testLead;
    quoteRequestData.faceAmount = 1000;
    quoteRequestData.carrier = 'lumico';
    quoteRequestData.product = 'wl';
    quoteRequestData.riskClass = 'STD';

    Rider rider = new Rider();
    rider.product = 'dc';
    rider.amount = 1000;
    rider.units = 3;

    quoteRequestData.riders = new List<Rider>{ rider };

    OdaLumicoQuoteController.getQuotes(quoteRequestData);

    System.assertEquals(true, calloutMock.urlsRequestBody.containsKey('quotes'));

    Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(
      calloutMock.urlsRequestBody.get('quotes')
    );

    String consumerDataString = JSON.serialize(requestBody.get('consumer_data'));
    Map<String, Object> consumerData = (Map<String, Object>) JSON.deserializeUntyped(
      consumerDataString
    );

    System.assertEquals((String) consumerData.get('eq_lead_uuid'), testLead.EqLeadUuid__c);
    System.assertEquals((Integer) consumerData.get('face_amount'), quoteRequestData.faceAmount);
    System.assertEquals((String) consumerData.get('carrier'), quoteRequestData.carrier);
    System.assertEquals((String) consumerData.get('product_name'), quoteRequestData.product);
    System.assertEquals((String) requestBody.get('client'), 'salesforce');
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
      Modified__c = false
    );

    insert testLead;

    return testLead;
  }
}