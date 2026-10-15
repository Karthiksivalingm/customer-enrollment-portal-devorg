public with sharing class OdaGerberController {
  public static final String QUOTES_PATH = '/quotes';

  @AuraEnabled
  public static List<Map<String, Object>> getConfirmedQuotes(OdaQuoteRequestData quoteRequestData) {
    List<Integer> faceAmounts = new List<Integer>{
      quoteRequestData.faceAmount - 1000,
      quoteRequestData.faceAmount,
      quoteRequestData.faceAmount + 1000
    };

    List<Map<String, Object>> quotes = new List<Map<String, Object>>();
    for (Integer amount : faceAmounts) {
      if (amount >= 5000 && amount <= 25000) {
        quoteRequestData.faceAmount = amount;
        Map<String, Object> requestParams = OdaQuoteRequestProvider.getQuoteRequest(
          quoteRequestData
        );

        Map<String, Object> quote = (Map<String, Object>) JSON.deserializeUntyped(
          ODARequestCallout.post(QUOTES_PATH, requestParams)
        );

        quotes.add(quote);
      }
    }
    return quotes;
  }
}