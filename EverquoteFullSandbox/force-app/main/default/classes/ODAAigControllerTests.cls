@isTest
public with sharing class ODAAigControllerTests {
  @testSetup
  static void testSetup() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());

    RecordType r = [SELECT Id FROM RecordType WHERE DeveloperName = 'Life_Leads'];

    Lead testLead = new Lead(
      LastName = 'ODAAigControllerTests',
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
      EqLeadUuid__c = '4ebb405e-1cb2-5507-855f-5b2616fd2d13',
      Marital_Status__c = 'Married',
      RecordTypeId = r.id,
      Modified__c = false,
      Major_Condition_Past_Year__c = 'Yes'
    );

    insert testLead;
  }

  @isTest
  private static void getConfirmedQuotesTest() {
    OdieRequestCalloutMock calloutMock = new OdieRequestCalloutMock();
    Test.setMock(HttpCalloutMock.class, calloutMock);

    Lead testLead = getTestLead();

    OdaQuoteRequestData data = new OdaQuoteRequestData();
    data.lead = testLead;
    data.carrier = 'aig';
    data.product = 'giwl';
    data.faceAmount = 10000;

    Test.startTest();
    ODAAigController.getConfirmedQuotes(data);

    Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(
      calloutMock.urlsRequestBody.get('quotes')
    );

    System.assertEquals((String) requestBody.get('eq_lead_uuid'), testLead.EqLeadUuid__c);
    System.assertEquals((String) requestBody.get('client'), 'salesforce');

    Map<String, Object> consumerData = (Map<String, Object>) requestBody.get('consumer_data');

    System.assertEquals((String) consumerData.get('carrier'), 'aig');
    System.assertEquals((String) consumerData.get('product_name'), 'giwl');
    System.assertEquals((String) consumerData.get('state'), testLead.State);
    System.assertEquals((String) consumerData.get('eq_lead_uuid'), testLead.EqLeadUuid__c);
    System.assertEquals((String) consumerData.get('birth_date'), '02/17/1960');

    Test.stopTest();
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
        Major_Condition_Past_Year__c
      FROM Lead
      WHERE LastName = 'ODAAigControllerTests'
      LIMIT 1
    ];
  }
}