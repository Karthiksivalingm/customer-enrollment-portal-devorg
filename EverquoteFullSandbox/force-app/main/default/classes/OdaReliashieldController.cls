public inherited sharing class OdaReliashieldController {
  public static final String QUOTES_PATH = '/quotes';

  @AuraEnabled
  public static String getReliashieldComparisonPdfUrl() {
    String link = OdaUtils.getLink('reliashield_comparison_pdf');

    return link;
  }

  @AuraEnabled
  public static Map<String, Object> getConfirmedQuote(OdaQuoteRequestData quoteRequestData) {

    Map<String, Object> requestParams = OdaQuoteRequestProvider.getQuoteRequest(
          quoteRequestData
        );

    Map<String, Object> quote = (Map<String, Object>) JSON.deserializeUntyped(
      ODARequestCallout.post(QUOTES_PATH, requestParams)
    );

    return quote;
  }
}