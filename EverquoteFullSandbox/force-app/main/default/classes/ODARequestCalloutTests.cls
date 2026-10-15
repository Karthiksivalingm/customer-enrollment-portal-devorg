@isTest
public with sharing class ODARequestCalloutTests {
  @isTest
  static void postTest() {
    OdieRequestCalloutMock calloutMock = new OdieRequestCalloutMock();
    Test.setMock(HttpCalloutMock.class, calloutMock);

    Map<String, String> params = new Map<String, String>{ 'key' => 'value' };

    Test.startTest();
    ODARequestCallout.post('test', params);
    Test.stopTest();

    System.assertEquals(true, calloutMock.urlsRequestBody.containsKey('test'));

    Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(
      calloutMock.urlsRequestBody.get('test')
    );

    System.assertEquals((String) requestBody.get('key'), 'value');
  }

  @isTest
  static void getTest() {
    OdieRequestCalloutMock calloutMock = new OdieRequestCalloutMock();
    Test.setMock(HttpCalloutMock.class, calloutMock);

    Map<String, String> params = new Map<String, String>{ 'key' => 'value' };

    Test.startTest();
    ODARequestCallout.get('test', params);
    Test.stopTest();

    System.assertEquals(true, calloutMock.urlsRequestBody.containsKey('test'));

    Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(
      calloutMock.urlsRequestBody.get('test')
    );

    System.assertEquals((String) requestBody.get('key'), 'value');
  }

  @isTest
  private static void postRaiseODABusinessRuleExceptionTest() {
    OdieRequestCalloutMock calloutMock = new OdieRequestCalloutMock();
    Map<String, Object> response = new Map<String, Object>{
      'business_rule' => 'Business rule 001'
    };
    calloutMock.setMockStatusAndBody(400, JSON.serialize(response));
    Test.setMock(HttpCalloutMock.class, calloutMock);

    Map<String, Object> params = new Map<String, Object>{ 'data' => 'test' };

    Test.startTest();
    try {
      ODARequestCallout.post('test', params);
    } catch (ODABusinessRuleException ex) {
      System.assertEquals(response.get('business_rule'), ex.getMessage());
    }

    Test.stopTest();
  }

  @isTest
  private static void postNullResponseRaiseODAExceptionTest() {
    OdieRequestCalloutMock calloutMock = new OdieRequestCalloutMock();
    String response = 'error';
    calloutMock.setMockStatusAndBody(400, JSON.serialize(response));
    Test.setMock(HttpCalloutMock.class, calloutMock);

    Map<String, Object> params = new Map<String, Object>{ 'data' => 'test' };

    Test.startTest();
    try {
      ODARequestCallout.post('test', params);
    } catch (ODAException ex) {
      System.assertEquals('Error processing request. Please try again.', ex.getMessage());
    }

    Test.stopTest();
  }

  @isTest
  private static void postNoPreviousApplicationRaiseODAExceptionTest() {
    OdieRequestCalloutMock calloutMock = new OdieRequestCalloutMock();
    Map<String, Object> response = new Map<String, Object>{
      'error' => 'No Quote found for quote_id \'71b45289de0747e2b558496cf58d3a3a\' or eq_lead_uuid: \'7906b4f1-74ff-5ed8-a004-fbe6a3fff306\''
    };
    calloutMock.setMockStatusAndBody(400, JSON.serialize(response));
    Test.setMock(HttpCalloutMock.class, calloutMock);

    Map<String, Object> params = new Map<String, Object>{ 'data' => 'test' };

    Test.startTest();
    try {
      ODARequestCallout.post('test', params);
    } catch (ODAException ex) {
      System.assertEquals('No previous application was found.', ex.getMessage());
    }

    Test.stopTest();
  }
}