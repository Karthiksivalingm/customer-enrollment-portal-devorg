public with sharing class ODALeadController {
  public static final Integer SIFE_MIN_QUOTE_VALUE = 5000;
  public static final Integer SIFE_MAX_MOD_QUOTE_VALUE = 15000;
  public static final Integer SIFE_MAX_STANDARD_QUOTE_VALUE = 30000;
  public static final Integer SIFE_MAX_PREFERRED_QUOTE_VALUE = 50000;

  public static Map<Integer, String> sifeFieldValueMap = getSifeFieldValueMap(
    SIFE_MAX_PREFERRED_QUOTE_VALUE
  );

  private static Map<Integer, String> getSifeFieldValueMap(Integer maxAmount) {
    List<Integer> amounts = getAmmountsList(maxAmount);
    Map<Integer, String> fieldValueMap = new Map<Integer, String>{};
    for (Integer amount : amounts) {
      fieldValueMap.put(amount, '$' + amount.format());
    }

    return fieldValueMap;
  }

  @AuraEnabled
  public static Boolean userHasTheRightSkillsAndLicenses(Id leadId, String product) {
    User user = [
      SELECT Id, Product_Skills__c, StatesLicensedIn__c, HealthStatesLicensedIn__c
      FROM User
      WHERE Id = :UserInfo.getUserId()
      LIMIT 1
    ];

    Lead lead = [SELECT Id, State FROM Lead WHERE Id = :leadId LIMIT 1];

    String productSkills = ((String) user.Product_Skills__c).toLowerCase();
    String healthStatesLicensedIn = ((String) user.HealthStatesLicensedIn__c).toLowerCase();
    String formattedProduct = ('-' + product + '-').toLowerCase();

    // currently this is used only for Lumico AD product, but can be extended also to life vertical
    if (
      string.isNotBlank(productSkills) &&
      productSkills.contains(formattedProduct) &&
      healthStatesLicensedIn.contains(lead.State.toLowerCase())
    ) {
      return true;
    }

    return false;
  }

  @AuraEnabled
  public static String pauseRecording(Id leadId) {
    return callRecordingAction(leadId, 'pause_recording');
  }

  @AuraEnabled
  public static String resumeRecording(Id leadId) {
    return callRecordingAction(leadId, 'resume_recording');
  }

  private static String callRecordingAction(Id leadId, String action) {
    Lead lead = [SELECT Id, EqLeadUuid__c, Phone, Twilio_Task_Sid__c FROM Lead WHERE Id = :leadId];

    Map<String, Object> params = new Map<String, Object>{
      'phone_number' => lead.Phone,
      'eq_lead_uuid' => lead.EqLeadUuid__c,
      'task_sid' => lead.Twilio_Task_Sid__c
    };

    return ODARequestCallout.post('/twilio/' + action, params);
  }

  @AuraEnabled
  public static String getFEComparisonToolUrl(
    Integer age,
    String gender,
    Boolean tobacco,
    String eqLeadUuid
  ) {
    String namedCredential = OdaUtils.getLink('omni_commerce');

    Map<String, Object> params = new Map<String, Object>{
      'age' => age,
      'gender' => gender.toLowerCase(),
      'tobacco' => tobacco,
      'eq_lead_uuid' => eqLeadUuid,
      'advisor_id' => UserInfo.getUserEmail()
    };

    String link = namedCredential + '?' + addUrlParams(params);

    return link;
  }

  @AuraEnabled
  public static Lead findById(String leadId) {
    Lead[] leads = [
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
        Carrier__c,
        Carrier__r.No__c,
        Height_new__c,
        Weight_new__c,
        Twilio_Task_Sid__c
      FROM Lead
      WHERE Id = :leadId
    ];
    return leads.isEmpty() ? null : leads[0];
  }

  @AuraEnabled
  public static Lead saveBirthDate(Id leadId, Date dateOfBirth) {
    Lead newLead = new Lead(Id = leadId, Date_of_Birth__c = dateOfBirth);
    update newLead;
    return findById(newLead.Id);
  }

  @AuraEnabled
  public static Lead saveAdditionalLevelTermInformation(Id leadId, String height, Integer weight) {
    Lead newLead = new Lead(Id = leadId, Height_new__c = height, Weight_new__c = weight);
    update newLead;
    return findById(newLead.Id);
  }

  @AuraEnabled
  public static Lead saveLeadRequiredInformation(
    Id leadId,
    String gender,
    String state,
    Date dateOfBirth
  ) {
    Lead newLead = new Lead(
      Id = leadId,
      Gender__c = gender,
      State = state,
      Date_of_Birth__c = dateOfBirth
    );
    update newLead;
    return findById(newLead.Id);
  }

  @TestVisible
  private static String processOdieRequest(String requestBody, String endPointPath) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:Odie_API_Credential/' + endPointPath);
    //req.setEndpoint('https://enhihxmqlj8l.x.pipedream.net/' + endPointPath);
    req.setMethod('POST');
    req.setHeader('Content-Type', 'application/json');
    req.setBody(requestBody);
    system.debug('REQUEST BODY');
    system.debug(requestBody);

    Http http = new Http();

    HTTPResponse res = http.send(req);

    if (res.getStatusCode() == 200) {
      return res.getBody();
    }

    return '{}';
  }

  @AuraEnabled
  public static String getQuotes(
    Lead lead,
    String product,
    List<Integer> termLengths,
    Integer faceAmount,
    String riskClass
  ) {
    switch on product {
      when 'sife' {
        return processSifeQuotes(lead, product, faceAmount, riskClass);
      }
      when 'siterm' {
        return processSitermQuotes(lead, product, termLengths, faceAmount);
      }
      when else {
        //default block term or term19
        return processLevelTermQuotes(lead, product, termLengths, faceAmount, riskClass);
      }
    }
  }

  @AuraEnabled
  public static string getRiderRates(
    Integer age,
    String product,
    Integer termLength,
    Boolean tobacco,
    Integer faceAmount,
    Rider rider
  ) {
    Map<String, Object> requestBody = new Map<String, Object>{
      'rider' => rider,
      'age' => age,
      'product' => product
    };

    if (termLength != null) {
      ((Map<String, Object>) requestBody).put('term_length', termLength);
    }

    if (tobacco != null) {
      ((Map<String, Object>) requestBody).put('tobacco', tobacco ? 'Yes' : 'No');
    }

    if (faceAmount != null) {
      ((Map<String, Object>) requestBody).put('face_amount', faceAmount);
    }

    String path = 'riders/' + rider.product + '/rates';
    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(
      processQuoteRequest(path, requestBody)
    );

    return JSON.serialize(result);
  }

  public static String processLevelTermQuotes(
    Lead lead,
    String product,
    List<Integer> termLengths,
    Integer faceAmount,
    String riskClass
  ) {
    if (termLengths == null || termLengths.isEmpty()) {
      termLengths = new List<Integer>{ 10, 15, 20, 30 };
    }

    Map<Integer, Map<Integer, Object>> results = new Map<Integer, Map<Integer, Object>>{
      faceAmount => new Map<Integer, Object>()
    };

    for (Integer termLength : termLengths) {
      Map<String, Object> quoteResult = (Map<String, Object>) JSON.deserializeUntyped(
        processLevelTermQuote(lead, product, termLength, faceAmount, riskClass, null)
      );

      if (quoteResult.containsKey('quote_id')) {
        results.get(faceAmount).put(termLength, quoteResult);
      }
    }

    return JSON.serialize(results);
  }

  public static String processSifeQuotes(
    Lead lead,
    String product,
    Integer faceAmount,
    String riskClass
  ) {
    Map<Integer, String> quotes = new Map<Integer, String>();

    Set<Integer> faceAmounts = faceAmount == null
      ? sifeFieldValueMap.keySet()
      : new Set<Integer>{ faceAmount - 1000, faceAmount, faceAmount + 1000 };
    for (Integer amount : faceAmounts) {
      if (riskClass.toLowerCase() == 'modified' && amount > SIFE_MAX_MOD_QUOTE_VALUE) {
        break;
      }

      if (riskClass.toLowerCase() == 'preferred') {
        if (lead.Age__c > 75 && amount > 20000) {
          break;
        }
        if (lead.Age__c > 70 && amount > 30000) {
          break;
        }
        if (lead.Age__c > 60 && amount > 40000) {
          break;
        }
        if (lead.Age__c >= 40 && amount > 50000) {
          break;
        }
      }

      if (riskClass.toLowerCase() == 'standard' && amount > SIFE_MAX_STANDARD_QUOTE_VALUE) {
        break;
      }

      if (amount >= SIFE_MIN_QUOTE_VALUE && amount <= SIFE_MAX_PREFERRED_QUOTE_VALUE) {
        String quote = processSifeQuote(lead, product, amount, riskClass, null);
        quotes.put(amount, quote);
      }
    }

    return JSON.serialize(quotes);
  }

  public static String processSitermQuotes(
    Lead lead,
    String product,
    List<Integer> termLengths,
    Integer faceAmount
  ) {
    if (termLengths == null || termLengths.isEmpty()) {
      termLengths = new List<Integer>{ 10, 15, 20, 30 };
    }

    Map<Integer, Map<Integer, Object>> results = new Map<Integer, Map<Integer, Object>>{
      faceAmount => new Map<Integer, Object>()
    };

    for (Integer termLength : termLengths) {
      Map<String, Object> quoteResult = (Map<String, Object>) JSON.deserializeUntyped(
        processSitermQuote(lead, product, termLength, faceAmount, null)
      );

      if (quoteResult.containsKey('quote_id')) {
        results.get(faceAmount).put(termLength, quoteResult);
      }
    }
    return JSON.serialize(results);
  }

  @AuraEnabled
  public static String getRates(
    Lead lead,
    String product,
    List<Integer> amounts,
    List<Integer> termLengths,
    String riskClass
  ) {
    switch on product {
      when 'sife' {
        return getSifeRates(lead, product, amounts, riskClass);
      }
      when 'siterm' {
        return getTermRates(lead, product, amounts, termLengths);
      }
      when else {
        //default block term or term19
        return getLevelTermRates(lead, product, amounts, riskClass);
      }
    }
  }

  @TestVisible
  private static Map<String, Object> buildLevelTermRatesRequestBody(
    Lead lead,
    List<Integer> amounts,
    String riskClass
  ) {
    Map<String, Object> requestBody = new Map<String, Object>{
      'state' => lead.State,
      'gender' => lead.Gender__c.substring(0, 1),
      'birth_date' => OdaUtils.formatBirthDate(lead.Date_Of_Birth__c),
      'amount_band' => amounts,
      'eq_lead_uuid' => lead.EqLeadUuid__c,
      'tobacco' => lead.Use_Tobacco__c,
      'has_major_condition' => lead.Major_Condition_Past_Year__c.substring(0, 1) == 'Y',
      'height' => lead.Height_new__c,
      'weight' => lead.Weight_new__c
    };

    if (riskClass != null) {
      ((Map<String, Object>) requestBody).put('risk_class', riskClass);
    }
    System.debug(requestBody);
    return requestBody;
  }

  private static String getLevelTermRates(
    Lead lead,
    String product,
    List<Integer> amounts,
    String riskClass
  ) {
    String url = 'carriers/lumico/products/' + product + '/rate_lookup';

    Map<String, Object> request = buildLevelTermRatesRequestBody(lead, amounts, riskClass);

    String result = processLevelTermRatesRequest(url, request);
    Map<String, Object> parsedResults = (Map<String, Object>) JSON.deserializeUntyped(result);

    System.debug(parsedResults);
    return JSON.serialize(parsedResults);
  }

  private static String getTermRates(
    Lead lead,
    String product,
    List<Integer> amounts,
    List<Integer> termLengths
  ) {
    if (amounts == null || amounts.isEmpty()) {
      amounts = new List<Integer>{ 25, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500 };
    }
    if (termLengths == null || termLengths.isEmpty()) {
      termLengths = new List<Integer>{ 10, 15, 20, 30 };
    }
    Map<Integer, Map<Integer, Decimal>> rateTable = new Map<Integer, Map<Integer, Decimal>>();
    for (Integer amount : amounts) {
      rateTable.put(amount, new Map<Integer, Decimal>());
    }

    String url = 'carriers/lumico/products/' + product + '/rate_lookup';

    List<String> exceptions = new List<String>();

    for (Integer term : termLengths) {
      try {
        String result = processRatesRequest(url, buildRatesRequestBody(lead, term, null));
        Map<String, Object> parsedResults = (Map<String, Object>) JSON.deserializeUntyped(result);

        if (parsedResults.containsKey('rate_per_thousand')) {
          Decimal ratePerThousand = (Decimal) parsedResults.get('rate_per_thousand');
          for (Integer amount : amounts) {
            rateTable.get(amount).put(term, calculateRate(ratePerThousand, amount));
          }
        } else {
          for (Integer amount : amounts) {
            rateTable.get(amount).put(term, null);
          }
        }
      } catch (ODAException ex) {
        exceptions.add(ex.getMessage());
        for (Integer amount : amounts) {
          rateTable.get(amount).put(term, null);
        }
      }
    }

    // if all requests are failing throw exception
    if (exceptions.size() == termLengths.size()) {
      throw new ODAException(exceptions.get(0));
    }

    return JSON.serialize(rateTable);
  }

  private static List<Integer> getAmmountsList(Integer maxAmount) {
    List<Integer> amounts = new List<Integer>();
    for (Integer i = 5000; i <= maxAmount; i += 5000) {
      amounts.add(i);
    }
    return amounts;
  }

  private static String getSifeRates(
    Lead lead,
    String product,
    List<Integer> amounts,
    String riskClass
  ) {
    Map<Integer, Map<String, Object>> sifeRates = new Map<Integer, Map<String, Object>>();
    if (amounts == null || amounts.isEmpty()) {
      if (riskClass == 'modified') {
        amounts = getAmmountsList(15000);
      } else if (riskClass == 'preferred') {
        if (lead.Age__c > 75) {
          amounts = getAmmountsList(20000);
        } else if (lead.Age__c >= 71 && lead.Age__c <= 75) {
          amounts = getAmmountsList(30000);
        } else if (lead.Age__c >= 61 && lead.Age__c <= 70) {
          amounts = getAmmountsList(40000);
        } else if (lead.Age__c >= 40 && lead.Age__c <= 60) {
          amounts = getAmmountsList(50000);
        } else {
          amounts = new List<Integer>();
        }
      } else {
        amounts = new List<Integer>(getAmmountsList(30000));
      }
      String url = 'carriers/lumico/products/' + product + '/rate_lookup';

      String result = processRatesRequest(url, buildRatesRequestBody(lead, null, riskClass));
      Map<String, Object> parsedResults = (Map<String, Object>) JSON.deserializeUntyped(result);
      if (parsedResults.containsKey('rate_per_thousand')) {
        Decimal ratePerThousand = (Decimal) parsedResults.get('rate_per_thousand');
        for (Integer amount : amounts) {
          sifeRates.put(
            amount,
            new Map<String, Object>{ 'premium' => calculateSifeRate(ratePerThousand, amount) }
          );
        }
      }
    }

    return JSON.serialize(sifeRates);
  }

  private static Decimal calculateRate(Decimal ratePerThousand, Integer amount) {
    return amount * ratePerThousand;
  }

  private static Decimal calculateSifeRate(Decimal ratePerThousand, Integer amount) {
    system.debug(amount * ratePerThousand);
    return (amount * ratePerThousand) / 1000;
  }

  private static Map<String, Object> buildQuotesRequestBody(
    Lead lead,
    String product,
    Integer term,
    Integer faceAmount,
    String riskClass,
    List<Rider> riders
  ) {
    Map<String, Object> requestBody = new Map<String, Object>{
      'eq_lead_uuid' => lead.EqLeadUuid__c,
      'client' => 'salesforce',
      'consumer_data' => new Map<String, Object>{
        'eq_lead_uuid' => lead.EqLeadUuid__c,
        'carrier' => 'lumico',
        'product_name' => product,
        'state' => lead.State,
        'birth_date' => OdaUtils.formatBirthDate(lead.Date_Of_Birth__c),
        'gender' => lead.Gender__c.substring(0, 1),
        'uses_tobacco' => lead.Use_Tobacco__c,
        'modified' => lead.Modified__c,
        'has_major_condition' => lead.Major_Condition_Past_Year__c.substring(0, 1) == 'Y',
        'face_amount' => faceAmount
      }
    };

    if (riders != null && riders.size() > 0) {
      ((Map<String, Object>) requestBody.get('consumer_data')).put('riders', riders);
    }

    if (product == 'siterm') {
      ((Map<String, Object>) requestBody.get('consumer_data')).put('term_length', term);
    }

    if (product == 'term' || product == 'term19') {
      ((Map<String, Object>) requestBody.get('consumer_data')).put('height', lead.Height_new__c);
      ((Map<String, Object>) requestBody.get('consumer_data')).put('weight', lead.Weight_new__c);
      ((Map<String, Object>) requestBody.get('consumer_data')).put('term_length', term);
    }

    if (riskClass != null) {
      ((Map<String, Object>) requestBody.get('consumer_data')).put('risk_class', riskClass);
    }

    system.debug(requestBody);
    return requestBody;
  }

  private static Map<String, Object> buildRatesRequestBody(
    Lead lead,
    Integer term,
    String riskClass
  ) {
    Map<String, Object> requestBody = new Map<String, Object>{
      'age' => String.valueOf(lead.Age__c),
      'gender' => lead.Gender__c,
      'tobacco' => lead.Use_Tobacco__c ? 'Yes' : 'No'
    };

    if (riskClass != null) {
      requestBody.put('risk_class', riskClass);
    }

    if (term != null) {
      requestBody.put('term_length', String.valueOf(term));
    }

    System.debug(requestBody);
    return requestBody;
  }

  private static String addUrlParams(Map<String, Object> params) {
    String paramString = '';
    String encoding = 'UTF-8';

    for (String paramKey : params.keySet()) {
      if (paramKey != null && params.get(paramKey) != null) {
        String value = String.valueOf(params.get(paramKey));

        paramString +=
          EncodingUtil.urlEncode(paramKey, encoding) +
          '=' +
          EncodingUtil.urlEncode(value, encoding) +
          '&';
      }
    }

    paramString = paramString.removeEnd('&');

    return paramString;
  }

  @TestVisible
  private static String processQuoteRequest(String path, Map<String, Object> params) {
    HttpRequest req = new HttpRequest();
    req.setMethod('POST');
    String endpoint = path;
    req.setBody(JSON.serialize(params));
    String result = processODARequest(req, endpoint);
    return result;
  }

  @TestVisible
  private static String processRatesRequest(String path, Map<String, Object> params) {
    HttpRequest req = new HttpRequest();
    req.setMethod('GET');
    String endpoint = path + '?' + addUrlParams(params);
    system.debug(endpoint);
    return processODARequest(req, endpoint);
  }

  @TestVisible
  private static String processLevelTermRatesRequest(String path, Map<String, Object> params) {
    HttpRequest req = new HttpRequest();
    req.setMethod('POST');
    req.setBody(JSON.serialize(params));
    String endpoint = path;
    system.debug(endpoint);
    return processODARequest(req, endpoint);
  }

  @Testvisible
  private static String processTwilioRequest(String path, Map<String, Object> params) {
    system.debug(params);
    HttpRequest req = new HttpRequest();
    req.setMethod('POST');
    req.setBody(JSON.serialize(params));
    return processODARequest(req, path);
  }

  @Testvisible
  private static String processODARequest(HttpRequest req, string endpoint) {
    req.setEndpoint('callout:Odie_API_Credential/' + endpoint);
    // req.setEndpoint('callout:dvoicu_odie_local/' + endpoint);
    req.setHeader('Content-Type', 'application/json');
    Http http = new Http();
    HTTPResponse res = http.send(req);

    system.debug(res.getBody());
    system.debug(res.getStatusCode());

    if (res.getStatusCode() == 200) {
      return res.getBody();
    }

    String errorMessage = 'Error processing request. Please try again.';
    Map<String, Object> response = null;
    try {
      response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    } catch (Exception ex) {
      System.debug(ex);
    }

    if (response == null) {
      throw new ODAException(errorMessage);
    }

    if (response.containsKey('error')) {
      errorMessage = (String) response.get('error');
      throw new ODAException(errorMessage);
    }

    if (response.containsKey('business_rule')) {
      throw new ODABusinessRuleException((String) response.get('business_rule'));
    }
    throw new ODAException(errorMessage);
  }

  public static String processSifeQuote(
    Lead lead,
    String product,
    Integer faceAmount,
    String riskClass,
    List<Rider> riders
  ) {
    String path = 'quotes';

    Map<String, Object> reqBody = buildQuotesRequestBody(
      lead,
      product,
      null,
      faceAmount,
      riskClass,
      riders
    );
    return processQuoteRequest(path, reqBody);
  }

  public static String processSitermQuote(
    Lead lead,
    String product,
    Integer termLength,
    Integer faceAmount,
    List<Rider> riders
  ) {
    Map<String, Object> params = buildQuotesRequestBody(
      lead,
      product,
      termLength,
      faceAmount,
      null,
      riders
    );

    String path = 'quotes';
    return processQuoteRequest(path, params);
  }

  public static String processLevelTermQuote(
    Lead lead,
    String product,
    Integer termLength,
    Integer faceAmount,
    String riskClass,
    List<Rider> riders
  ) {
    String path = 'quotes';

    Map<String, Object> params = buildQuotesRequestBody(
      lead,
      product,
      termLength,
      faceAmount,
      riskClass,
      riders
    );

    return processQuoteRequest(path, params);
  }

  @AuraEnabled
  public static String getQuoteIncludingRiders(
    Lead lead,
    String product,
    Integer termLength,
    Integer faceAmount,
    String riskClass,
    List<Rider> riders
  ) {
    switch on product {
      when 'sife' {
        return sifeQuoteIncludingRiders(lead, product, faceAmount, riskClass, riders);
      }
      when 'siterm' {
        return sitermQuoteIncludingRiders(lead, product, termLength, faceAmount, riskClass, riders);
      }
      when else {
        //default block term or term19
        return levelTermQuoteIncludingRiders(
          lead,
          product,
          termLength,
          faceAmount,
          riskClass,
          riders
        );
      }
    }
  }

  public static String sifeQuoteIncludingRiders(
    Lead lead,
    String product,
    Integer faceAmount,
    String riskClass,
    List<Rider> riders
  ) {
    Map<Integer, Object> result = new Map<Integer, Object>();
    String quote = processSifeQuote(lead, product, faceAmount, riskClass, riders);
    result.put(faceAmount, quote);

    return JSON.serialize(result);
  }

  public static String sitermQuoteIncludingRiders(
    Lead lead,
    String product,
    Integer termLength,
    Integer faceAmount,
    String riskClass,
    List<Rider> riders
  ) {
    String quote = processSitermQuote(lead, product, termLength, faceAmount, riders);

    Map<Integer, Map<Integer, Object>> result = new Map<Integer, Map<Integer, Object>>{
      faceAmount => new Map<Integer, Object>{ termLength => JSON.deserializeUntyped(quote) }
    };

    return JSON.serialize(result);
  }

  public static String levelTermQuoteIncludingRiders(
    Lead lead,
    String product,
    Integer termLength,
    Integer faceAmount,
    String riskClass,
    List<Rider> riders
  ) {
    String quote = processLevelTermQuote(lead, product, termLength, faceAmount, riskClass, riders);

    Map<Integer, Map<Integer, Object>> result = new Map<Integer, Map<Integer, Object>>{
      faceAmount => new Map<Integer, Object>{ termLength => JSON.deserializeUntyped(quote) }
    };

    return JSON.serialize(result);
  }
}