/*
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
*/

/**********************************
Class Name    : ODAPolicyControllerTests
Description     : Test coverage for ODAPolicyController.
VERSION          DATE                   AUTHOR                DETAIL
---------------------------------------------------------------------------------------------------------
1.1              (refactor)             Kept every original test scenario unchanged. Added:
                                          - updatePolicies_multipleExistingPolicies_allGetUpdatedCorrectly:
                                            regression test for the DML-in-loop fix. Sends 3 existing
                                            ODA_Policy__c records through savePolicies() in one call and
                                            asserts all 3 end up with the correct Name/Coverage_Amount__c -
                                            the original bug (update running once per loop iteration on a
                                            growing list) would still have produced this same final state
                                            for a passing case, so this test alone doesn't prove the old bug
                                            existed, but it locks in correct behavior post-fix and would
                                            catch a regression that broke bulk updates.
                                          - savePolicies_dmlFailureDuringUpdate_throwsAuraHandledException:
                                            forces an update failure (a policiesDto entry referencing a
                                            well-formed but non-existent ODA_Policy__c Id) and asserts
                                            savePolicies() throws AuraHandledException rather than letting a
                                            raw DmlException propagate to the caller - the regression test
                                            for the try/catch + AuraHandledException fix.
***********************************/
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

  @isTest
  static void updatePolicies_multipleExistingPolicies_allGetUpdatedCorrectly() {
    Lead testLead = getTestLead();

    List<ODA_Policy__c> existingPolicies = new List<ODA_Policy__c>();
    for (Integer i = 0; i < 3; i++) {
      existingPolicies.add(new ODA_Policy__c(
        Name = 'Old Name ' + i,
        Lead__c = testLead.Id,
        Carrier__c = 'lumico',
        Product__c = 'sife',
        Quote_Id__c = 'quote_' + i + '_' + System.currentTimeMillis(),
        Coverage_Amount__c = 1000
      ));
    }
    insert existingPolicies;

    List<ODAPolicyDto> policiesDto = new List<ODAPolicyDto>();
    for (Integer i = 0; i < 3; i++) {
      ODAPolicyDto dto = new ODAPolicyDto();
      dto.id = existingPolicies[i].Id;
      dto.policyNumber = 'UPDATED-' + i;
      dto.carrier = 'lumico';
      dto.product = 'sife';
      dto.coverageAmount = 9999 + i;
      dto.quoteId = existingPolicies[i].Quote_Id__c;
      dto.cannotGetPolicyNumber = false;
      policiesDto.add(dto);
    }

    OdieRequestCalloutMock calloutMock = new OdieRequestCalloutMock();
    calloutMock.setResponseBody(
      JSON.serialize(
        new Map<String, Object>{
          'new_policies' => new List<ODAPolicyDto>(),
          'failing_policies' => new List<Map<String, Object>>()
        }
      )
    );
    Test.setMock(HttpCalloutMock.class, calloutMock);

    Test.startTest();
    ODAPolicyController.savePolicies(testLead.Id, policiesDto);
    Test.stopTest();

    List<ODA_Policy__c> updatedPolicies = [
      SELECT Id, Name, Coverage_Amount__c
      FROM ODA_Policy__c
      WHERE Id IN :existingPolicies
    ];
    System.assertEquals(3, updatedPolicies.size(), 'All 3 policies should still exist.');

    Map<Id, ODA_Policy__c> updatedById = new Map<Id, ODA_Policy__c>(updatedPolicies);
    for (Integer i = 0; i < 3; i++) {
      ODA_Policy__c updated = updatedById.get(existingPolicies[i].Id);
      System.assertEquals('UPDATED-' + i, updated.Name, 'Policy ' + i + ' should have its updated Name.');
      System.assertEquals(9999 + i, updated.Coverage_Amount__c, 'Policy ' + i + ' should have its updated Coverage_Amount__c.');
    }
  }

  @isTest
  static void savePolicies_dmlFailureDuringUpdate_throwsAuraHandledException() {
    Lead testLead = getTestLead();

    // Well-formed Id that does not correspond to any real ODA_Policy__c record, forcing the
    // update to fail with INVALID_CROSS_REFERENCE_KEY / entity not found.
    Id nonExistentPolicyId = ODA_Policy__c.SObjectType.getDescribe().getKeyPrefix() + '000000000000AAA';

    ODAPolicyDto dto = new ODAPolicyDto();
    dto.id = nonExistentPolicyId;
    dto.policyNumber = 'WONT-SAVE';
    dto.carrier = 'lumico';
    dto.product = 'sife';
    dto.coverageAmount = 5000;
    dto.quoteId = 'quote_' + System.currentTimeMillis();
    dto.cannotGetPolicyNumber = false;

    OdieRequestCalloutMock calloutMock = new OdieRequestCalloutMock();
    calloutMock.setResponseBody(
      JSON.serialize(
        new Map<String, Object>{
          'new_policies' => new List<ODAPolicyDto>(),
          'failing_policies' => new List<Map<String, Object>>()
        }
      )
    );
    Test.setMock(HttpCalloutMock.class, calloutMock);

    Test.startTest();
    Boolean threwAuraHandledException = false;
    try {
      ODAPolicyController.savePolicies(testLead.Id, new List<ODAPolicyDto>{ dto });
    } catch (AuraHandledException ex) {
      threwAuraHandledException = true;
    }
    Test.stopTest();

    System.assert(threwAuraHandledException, 'A DML failure during update should surface as an AuraHandledException, not a raw DmlException.');
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