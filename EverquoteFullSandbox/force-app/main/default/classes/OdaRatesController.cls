public inherited sharing class OdaRatesController {
  @AuraEnabled
  public static String getRates(OdaRateLookupData rateLookup) {
    String rate_lookup_path = requestPath(rateLookup.carrier, rateLookup.product);

    Map<String, Object> requestParams = OdaRatesRequestProvider.getRatesRequest(rateLookup);

    String result = ODARequestCallout.get(rate_lookup_path, requestParams);
    return result;
  }

  private static String requestPath(String carrier, String product) {
    List<String> requestArgs = new List<String>{ carrier, product };

    if (string.isBlank(carrier) || String.isBlank(product)) {
      String errorTemplate = 'Unable to create rates request path. Missing carrier or product. carrier: "{0}", product: "{1}"';
      throw new ODAException(String.format(errorTemplate, requestArgs));
    }
    String requestPathTemplate = '/carriers/{0}/products/{1}/rate_lookup';
    return String.format(requestPathTemplate, requestArgs);
  }
}