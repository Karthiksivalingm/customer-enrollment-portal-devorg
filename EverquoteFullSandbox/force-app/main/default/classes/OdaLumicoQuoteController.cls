public with sharing class OdaLumicoQuoteController {
  public static final String QUOTES_PATH = '/quotes';

  @AuraEnabled
  public static Map<Integer, Map<String, Object>> getQuotes(OdaQuoteRequestData quoteRequestData) {
    switch on quoteRequestData.product {
      when 'ad' {
        return getQuote(quoteRequestData);
      }
      when 'wl' {
        return getQuote(quoteRequestData);
      }
      when else {
        throw new ODAException('Lumico product not yet supported');
      }
    }
  }

  private static Map<Integer, Map<String, Object>> getQuote(OdaQuoteRequestData quoteRequestData) {
    Map<Integer, Map<String, Object>> quotes = new Map<Integer, Map<String, Object>>();

    Map<String, Object> requestParams = OdaQuoteRequestProvider.getQuoteRequest(quoteRequestData);

    Map<String, Object> quote = (Map<String, Object>) JSON.deserializeUntyped(
      ODARequestCallout.post(QUOTES_PATH, requestParams)
    );

    quotes.put(quoteRequestData.faceAmount, quote);

    return quotes;
  }
}