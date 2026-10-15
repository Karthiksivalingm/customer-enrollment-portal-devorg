public with sharing class ODARequestCallout {
  public static String post(String endPointPath, Map<String, Object> params) {
    if (String.isBlank((String) params.get('client'))) {
      params.put('client', 'salesforce');
    }

    if (String.isBlank((String) params.get('odie_agent_id'))) {
      params.put('odie_agent_id', OdaUtils.getCurrentOdieAgentId());
    }

    if (String.isBlank((String) params.get('agent_email'))) {
      params.put('agent_email', UserInfo.getUserEmail());
    }

    return processRequest(JSON.serialize(params), endPointPath, 'POST');
  }

  public static String get(String endPointPath, Map<String, Object> params) {
    String endpoint = endPointPath + '?' + addUrlParams(params);
    return processRequest(JSON.serialize(params), endPointPath, 'GET');
  }

  private static String processRequest(
    String requestBody,
    String endPointPath,
    String requestMethod
  ) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:Odie_API_Credential/' + endPointPath);

    req.setMethod('POST');
    req.setHeader('Content-Type', 'application/json');
    req.setBody(requestBody);
    system.debug('REQUEST BODY: ' + requestBody);

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
      // No Quote found for quote_id '71b45289de0747e2b558496cf58d3a3a' or eq_lead_uuid: '7906b4f1-74ff-5ed8-a004-fbe6a3fff306'
      // Change error message with a friendly one
      if (errorMessage.trim().startsWith('No Quote found for quote_id')) {
        errorMessage = 'No previous application was found.';
      }

      throw new ODAException(errorMessage);
    }

    if (response.containsKey('business_rule')) {
      throw new ODABusinessRuleException((String) response.get('business_rule'));
    }
    throw new ODAException(errorMessage);
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
}