public with sharing class ODAEAppController {
  public static final String E_APPS_PATH = 'e_apps';
  public static final String PREV_E_APPS_PATH = 'e_apps/previous_e_apps';

  @AuraEnabled
  public static List<Map<String, Object>> loadPreviousApplications(
    Lead lead,
    String carrier,
    String product
  ) {
    List<ODA_Policy__c> lastEAppPolicies = [
      SELECT Id, Quote_Id__c
      FROM ODA_Policy__c
      WHERE Carrier__c = :carrier AND Product__c = :product AND Lead__c = :lead.Id
      ORDER BY Created_at__c DESC
    ];

    if (lastEAppPolicies.size() == 0) {
      throw new ODAException('No previous application was found.');
    }

    Lead fullLeadDetails = ODALeadController.findById(lead.Id);

    Map<String, Object> params = new Map<String, Object>{
      'carrier' => carrier,
      'product' => product,
      'eq_lead_uuid' => fullLeadDetails.EqLeadUuid__c
    };

    List<String> quotesId = new List<String>();
    for (ODA_Policy__c policy : lastEAppPolicies) {
      quotesId.add(policy.Quote_Id__c);
    }

    params.put('quotes', quotesId);

    List<Map<String, String>> result = (List<Map<String, String>>) JSON.deserialize(
      ODARequestCallout.post(PREV_E_APPS_PATH, params),
      List<Map<String, String>>.class
    );

    System.debug(result);

    return result;
  }

  @AuraEnabled
  public static Map<String, Object> openPreviousApplication(
    Lead lead,
    String carrier,
    String product,
    String quoteId
  ) {
    Lead fullLeadDetails = ODALeadController.findById(lead.Id);
    Map<String, Object> result = eAppRequestCallout(fullLeadDetails, quoteId, carrier, product);

    return result;
  }

  @AuraEnabled
  public static Map<String, Object> getEApp(
    Lead lead,
    String quoteId,
    Integer faceAmount,
    String carrier,
    String product
  ) {
    Lead fullLeadDetails = ODALeadController.findById(lead.Id);

    Map<String, Object> results = eAppRequestCallout(fullLeadDetails, quoteId, carrier, product);
    updateLeadAfterEApp(fullLeadDetails, faceAmount, quoteId, carrier, product);

    return results;
  }

  private static Map<String, Object> eAppRequestCallout(
    Lead lead,
    String quoteId,
    String carrier,
    String product
  ) {
    Map<String, Object> params = buildEappRequestBody(lead, quoteId, carrier, product);
    Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(
      ODARequestCallout.post(E_APPS_PATH, params)
    );
    return results;
  }

  public static Map<String, Object> buildEappRequestBody(
    Lead lead,
    String quoteId,
    String carrier,
    String product
  ) {
    Map<String, Object> requestBody = new Map<String, Object>{
      'eq_lead_uuid' => lead.EqLeadUuid__c,
      'quote_id' => quoteId,
      'carrier' => carrier,
      'product_name' => product != null ? product : '',
      'agent_id' => OdaUtils.getCurrentAgentId(),
      'odie_agent_id' => OdaUtils.getCurrentOdieAgentId(),
      'client' => 'salesforce',
      'consumer_data' => new Map<String, Object>{
        'first_name' => lead.firstName,
        'last_name' => lead.lastName,
        'home_street' => lead.street,
        'home_city' => lead.city,
        'home_state' => lead.state,
        'home_zip' => lead.PostalCode,
        'weight' => lead.Weight__c,
        'height' => lead.Height__c,
        'gender' => lead.Gender__c,
        'family_status' => lead.Marital_Status__c,
        'email' => lead.Email,
        'phone_number' => lead.Phone,
        'birth_date' => OdaUtils.formatBirthDate(lead.Date_Of_Birth__c)
      }
    };

    if (product == 'term' || product == 'term19') {
      ((Map<String, Object>) requestBody.get('consumer_data'))
        .put('height', Integer.valueOf(lead.Height_new__c));
      ((Map<String, Object>) requestBody.get('consumer_data')).put('weight', lead.Weight_new__c);
    }

    system.debug(requestBody);
    return requestBody;
  }

  @TestVisible
  private static void updateLeadAfterEApp(
    Lead lead,
    Integer faceAmount,
    String quoteId,
    String carrier,
    String product
  ) {
    if (carrier.toLowerCase() == 'lumico' && faceAmount != null) {
      if (product.toLowerCase() == 'sife') {
        lead.Coverage_Amount__c = ODALeadController.sifeFieldValueMap.get(faceAmount);
      }
      lead.Lumico_Quote_ID__c = quoteId;
    }

    createODAPolicy(lead.Id, carrier, product, quoteId, faceAmount);

    update lead;
  }

  private static void createODAPolicy(
    Id leadId,
    String carrier,
    String product,
    String quoteId,
    Integer coverageAmount
  ) {
    List<ODA_Policy__c> existingPolicies = [
      SELECT Id
      FROM ODA_Policy__c
      WHERE Quote_Id__c = :quoteId
      LIMIT 1
    ];

    if (existingPolicies.size() == 0) {
      ODA_Policy__c policy = new ODA_Policy__c(
        Name = 'N/A',
        Lead__c = leadId,
        Carrier__c = carrier,
        Product__c = product,
        Quote_Id__c = quoteId,
        Coverage_Amount__c = coverageAmount
      );

      insert policy;
    }
  }
}