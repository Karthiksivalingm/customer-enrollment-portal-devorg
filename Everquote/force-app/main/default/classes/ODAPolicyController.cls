public with sharing class ODAPolicyController {
  @AuraEnabled
  public static ODA_Policy__c findPolicy(String leadId, String carrier, String product) {
    product = product == 'levelterm' ? leadLevelTermProduct(leadId) : product;

    List<ODA_Policy__c> policies = [
      SELECT Id, Coverage_Amount__c, Quote_Id__c, Product__c, Carrier__c
      FROM ODA_Policy__c
      WHERE Lead__c = :leadId AND Carrier__c = :carrier AND Product__c = :product AND Name = 'N/A'
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];

    if (policies.size() > 0) {
      ODA_Policy__c policy = policies[0];
      mapLevelTermProduct(policy);
      return policy;
    }
    return null;
  }

  @AuraEnabled
  public static List<ODA_Policy__c> findPolicies(String leadId) {
    List<ODA_Policy__c> policies = [
      SELECT Id, Coverage_Amount__c, Quote_Id__c, Product__c, Carrier__c
      FROM ODA_Policy__c
      WHERE Lead__c = :leadId AND Name = 'N/A'
      ORDER BY CreatedDate DESC
    ];

    for (ODA_Policy__c policy : policies) {
      mapLevelTermProduct(policy);
    }

    return policies;
  }

  @AuraEnabled
  public static String savePolicies(Id leadId, List<ODAPolicyDto> policiesDto) {
    Lead lead = ODALeadController.findById(leadId);

    List<Map<String, Object>> requestPolicies = new List<Map<String, Object>>();

    String levelTermProduct = leadLevelTermProduct(leadId);

    for (ODAPolicyDto dto : policiesDto) {
      String product = dto.product == 'levelterm' ? levelTermProduct : dto.product;

      Map<String, Object> requestPolicy = new Map<String, Object>{
        'id' => dto.id,
        'quoteId' => dto.quoteId,
        'policyNumber' => dto.policyNumber,
        'carrier' => dto.carrier,
        'product' => product,
        'coverageAmount' => dto.coverageAmount,
        'recordingWasPaused' => dto.recordingWasPaused,
        'cannotGetPolicyNumber' => dto.cannotGetPolicyNumber,
        'riskClass' => dto.riskClass,
        'tobacco' => lead.Use_Tobacco__c
      };

      if (dto.quoteId == null) {
        Map<String, Object> e_app_details = ODAEAppController.buildEappRequestBody(
          lead,
          null,
          dto.carrier,
          dto.product
        );

        e_app_details.put('quote_id', null);
        requestPolicy.put('e_app', e_app_details);
      }

      requestPolicies.add(requestPolicy);
    }

    Map<String, Object> requestParams = new Map<String, Object>{
      'eq_lead_uuid' => lead.EqLeadUuid__c,
      'policies' => requestPolicies
    };

    String requestResult = ODARequestCallout.post('e_apps/save_policies', requestParams);
    System.debug(JSON.serialize(requestResult));

    createODAPolicies(lead.Id, responseNewPoliciesDto(requestResult));
    updateODAPolicies(lead.Id, policiesDto, responseFailingPoliciesDto(requestResult));

    return requestResult;
  }

  private static String leadLevelTermProduct(Id leadId) {
    Lead lead = [SELECT Id, State FROM Lead WHERE Id = :leadId LIMIT 1];

    List<String> termStates = new List<String>{ 'DE', 'MT', 'ND', 'SD', 'FL', 'CA' };

    if (termStates.contains(lead.State.toUpperCase())) {
      return 'term';
    } else {
      return 'term19';
    }
  }

  private static void mapLevelTermProduct(ODA_Policy__c policy) {
    if (policy.Product__c.toLowerCase() == 'term' || policy.Product__c.toLowerCase() == 'term19') {
      policy.Product__c = 'levelterm';
    }
  }

  private static void createODAPolicies(Id leadId, List<ODAPolicyDto> policiesDto) {
    List<ODA_Policy__c> newODA_Policies = new List<ODA_Policy__c>();

    for (ODAPolicyDto dto : policiesDto) {
      String name = dto.cannotGetPolicyNumber == null || dto.cannotGetPolicyNumber
        ? 'No policy number'
        : dto.policyNumber;

      newODA_Policies.add(
        new ODA_Policy__c(
          Name = name,
          Lead__c = leadId,
          Carrier__c = dto.carrier,
          Product__c = dto.product,
          Quote_Id__c = dto.quoteId,
          Coverage_Amount__c = dto.coverageAmount
        )
      );
    }

    insert newODA_Policies;
  }

  private static void updateODAPolicies(
    Id leadId,
    List<ODAPolicyDto> policiesDto,
    List<ODAPolicyDto> failingPoliciesDto
  ) {
    set<string> failingIds = new Set<string>();
    for (ODAPolicyDto dto : failingPoliciesDto) {
      failingIds.add(dto.id);
    }

    List<ODA_Policy__c> odaPolicies = new List<ODA_Policy__c>();

    for (ODAPolicyDto dto : policiesDto) {
      if (!String.isBlank(dto.id) && !failingIds.contains(dto.id)) {
        String name = dto.cannotGetPolicyNumber ? 'No policy number' : dto.policyNumber;
        ODA_Policy__c odaPolicy = new ODA_Policy__c(
          Id = dto.id,
          Name = name,
          Coverage_Amount__c = dto.coverageAmount
        );
        odaPolicies.add(odaPolicy);
      }

      update odaPolicies;
    }
  }

  private static List<ODAPolicyDto> responseNewPoliciesDto(String response) {
    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response);

    String newPoliciesString = JSON.serialize(result.get('new_policies'));

    List<ODAPolicyDto> newPolicies = (List<ODAPolicyDto>) JSON.deserialize(
      newPoliciesString,
      List<ODAPolicyDto>.class
    );

    return newPolicies;
  }

  private static List<ODAPolicyDto> responseFailingPoliciesDto(String response) {
    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response);

    String failingPoliciesString = JSON.serialize(result.get('failing_policies'));

    List<Object> failingObjects = (List<Object>) JSON.deserializeUntyped(failingPoliciesString);

    List<ODAPolicyDto> failingPoliciesDto = new List<ODAPolicyDto>();

    for (Object item : failingObjects) {
      String itemString = JSON.serialize(item);
      Map<String, Object> failingDetails = (Map<String, Object>) JSON.deserializeUntyped(
        itemString
      );

      String failingPolicyString = JSON.serialize(failingDetails.get('policy'));
      ODAPolicyDto failingPolicyDto = (ODAPolicyDto) JSON.deserialize(
        failingPolicyString,
        ODAPolicyDto.class
      );

      failingPoliciesDto.add((failingPolicyDto));
    }

    return failingPoliciesDto;
  }
}