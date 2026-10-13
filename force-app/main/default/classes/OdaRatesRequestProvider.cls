public inherited sharing class OdaRatesRequestProvider {
  @AuraEnabled
  public static Map<String, Object> getRatesRequest(OdaRateLookupData lookupData) {
    OdaRatesRequestBuilder builder = getRequestBuilderObject(lookupData);
    return builder.buildRatesRequest(lookupData);
  }

  private static OdaRatesRequestBuilder getRequestBuilderObject(OdaRateLookupData lookupData) {
    String carrier = lookupData.carrier;
    OdaRatesRequestBuilder builder;
    if (string.isNotBlank(carrier)) {
      switch on carrier.toLowerCase() {
        when 'gerber' {
          builder = new OdaGerberRatesRequestBuilder();
        }
        when 'aig' {
          builder = new OdaAigRateRequestBuilder();
        }
        when 'reliashield' {
          builder = new OdaReliashieldRateRequestBuilder();
        }
        when 'lumico' {
          builder = getLumicoProductRequestBuilderObject(lookupData.product);
        }
        when else {
          throw new ODAException('Invalid carrier: ' + '"' + carrier + '"');
        }
      }
      return builder;
    }
    throw new ODAException('Carrier not specified');
  }

  private static OdaRatesRequestBuilder getLumicoProductRequestBuilderObject(String product) {
    OdaRatesRequestBuilder builder;
    if (string.isNotBlank(product)) {
      switch on product.toLowerCase() {
        when 'ad' {
          builder = new OdaLumicoAdRatesRequestBuilder();
        }
        when 'wl' {
          builder = new OdaLumicoWlRatesRequestBuilder();
        }
        when else {
          throw new ODAException('Invalid product: ' + '"' + product + '"');
        }
      }
      return builder;
    }
    throw new ODAException('Product not specified');
  }
}