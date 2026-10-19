@isTest
public with sharing class ODAPolicyControllerTests {
  private static final String LEAD_LASTNAME = 'Test ODA Lead';

  @testSetup
  static void testSetup() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());
    createTestLead();
  }

  @isTest
  static void findPolicy_should_return_policy_when_exists() {
    findPolicyTest(true);
  }

  @isTest
  static void findPolicy_should_return_null_when_policy_missing() {
    findPolicyTest(false);
  }

  @isTest
  static void findPoliciesTest() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());

    Lead testLead = getTestLead();
    ODA_Policy__c policy = new ODA_Policy__c(
      Name = 'N/A',
      Lead__c = testLead.Id,
      Carrier__c = 'Lumico Test',
      Product__c = 'term19',
      Quote_Id__c = 'quote_' + System.currentTimeMillis(),
      Coverage_Amount__c = 10000
    );

    Test.startTest();

    insert policy;

    Test.stopTest();

    List<ODA_Policy__c> policies = ODAPolicyController.findPolicies(testLead.Id);
    System.assertEquals(policies.size(), 1);

    ODA_Policy__c resultPolicy = policies[0];

    System.assertEquals(resultPolicy.Quote_Id__c, policy.Quote_Id__c);
    System.assertEquals(resultPolicy.Product__c, 'levelterm');
  }

  private static void findPolicyTest(Boolean shouldAddPolicy) {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());

    Lead testLead = getTestLead();
    ODA_Policy__c policy = new ODA_Policy__c(
      Name = 'N/A',
      Lead__c = testLead.Id,
      Carrier__c = 'Lumico Test',
      Product__c = 'term19',
      Quote_Id__c = 'quote_' + System.currentTimeMillis(),
      Coverage_Amount__c = 10000
    );

    Test.startTest();

    if (shouldAddPolicy) {
      insert policy;
    }

    Test.stopTest();

    ODA_Policy__c existingPolicy = ODAPolicyController.findPolicy(
      testLead.Id,
      policy.Carrier__c,
      policy.Product__c
    );
    if (shouldAddPolicy) {
      System.assertEquals(policy.Quote_Id__c, existingPolicy.Quote_Id__c);
      System.assertEquals(existingPolicy.Product__c, 'levelterm');
    } else {
      System.assert(existingPolicy == null, 'Policy is not null');
    }
  }

  @isTest
  static void savePoliciesTest() {
    List<ODAPolicyDto> policiesDto = createRequestPolicies();
    ODAPolicyDto lumicoPolicy = policiesDto[0];
    ODAPolicyDto aigPolicy = policiesDto[1];

    OdieRequestCalloutMock calloutMock = new OdieRequestCalloutMock();
    calloutMock.setResponseBody(
      JSON.serialize(
        new Map<String, Object>{
          'new_policies' => new List<ODAPolicyDto>{ aigPolicy },
          'failing_policies' => new List<Map<String, Object>>{
            new Map<String, Object>{
              'error' => 'Test error',
              'policy' => new Map<String, Object>{ 'id' => 'fake_id' }
            }
          }
        }
      )
    );
    Test.setMock(HttpCalloutMock.class, calloutMock);

    Lead testLead = getTestLead();

    ODA_Policy__c odaPolicy = new ODA_Policy__c(
      Name = lumicoPolicy.policyNumber,
      Lead__c = testLead.Id,
      Carrier__c = lumicoPolicy.carrier,
      Product__c = lumicoPolicy.product,
      Quote_Id__c = lumicoPolicy.quoteId,
      Coverage_Amount__c = lumicoPolicy.coverageAmount
    );

    insert odaPolicy;

    Test.startTest();

    ODAPolicyController.savePolicies(testLead.Id, policiesDto);
    Test.stopTest();

    System.assertEquals(true, calloutMock.urlsRequestBody.containsKey('e_apps/save_policies'));

    Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(
      calloutMock.urlsRequestBody.get('e_apps/save_policies')
    );

    testLead = getTestLead();

    System.assertEquals(testLead.EqLeadUuid__c, requestBody.get('eq_lead_uuid'));

    String policiesData = JSON.serialize(requestBody.get('policies'));

    List<ODAPolicyDto> requestPolicies = (List<ODAPolicyDto>) JSON.deserialize(
      policiesData,
      List<ODAPolicyDto>.class
    );

    for (ODAPolicyDto policy : policiesDto) {
      Boolean match = false;

      for (ODAPolicyDto requestPolicy : requestPolicies) {
        if (
          policy.carrier == requestPolicy.carrier &&
          policy.product == requestPolicy.product &&
          policy.policyNumber == requestPolicy.policyNumber &&
          policy.coverageAmount == requestPolicy.coverageAmount &&
          policy.quoteId == requestPolicy.quoteId
        ) {
          match = true;
          break;
        }
      }
      System.assert(match == true, 'No match for policy: ' + JSON.serialize(policy));
    }

    List<ODA_Policy__c> sfPolicies = [
      SELECT Id, Name, Carrier__c, Product__c, Coverage_Amount__c
      FROM ODA_Policy__c
      WHERE Lead__c = :testLead.Id
    ];
    System.assertEquals(2, sfPolicies.size());
  }

  private static List<ODAPolicyDto> createRequestPolicies() {
    ODAPolicyDto lumicoPolicy = new ODAPolicyDto();
    lumicoPolicy.policyNumber = 'GM123123';
    lumicoPolicy.carrier = 'lumico';
    lumicoPolicy.product = 'sife';
    lumicoPolicy.coverageAmount = 10000;
    lumicoPolicy.quoteId = 'quote_' + System.currentTimeMillis();

    ODAPolicyDto aigPolicy = new ODAPolicyDto();
    aigPolicy.policyNumber = '1234567890';
    aigPolicy.carrier = 'aig';
    aigPolicy.product = 'giwl';
    aigPolicy.coverageAmount = 15000;
    aigPolicy.quoteId = 'quote_' + System.currentTimeMillis();

    return new List<ODAPolicyDto>{ lumicoPolicy, aigPolicy };
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