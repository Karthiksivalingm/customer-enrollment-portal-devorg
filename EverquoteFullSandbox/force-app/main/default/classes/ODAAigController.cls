public with sharing class ODAAigController {
  public static final String QUOTES_PATH = '/quotes';

  @AuraEnabled
  public static Map<Integer, Map<String, Object>> getConfirmedQuotes(
    OdaQuoteRequestData quoteRequestData
  ) {
    List<Integer> faceAmounts = new List<Integer>{
      quoteRequestData.faceAmount - 1000,
      quoteRequestData.faceAmount,
      quoteRequestData.faceAmount + 1000
    };

    Map<Integer, Map<String, Object>> quotes = new Map<Integer, Map<String, Object>>();
    for (Integer amount : faceAmounts) {
      if (amount >= 5000 && amount <= 25000) {
        quoteRequestData.faceAmount = amount;
        Map<String, Object> requestParams = OdaQuoteRequestProvider.getQuoteRequest(
          quoteRequestData
        );

        Map<String, Object> quote = (Map<String, Object>) JSON.deserializeUntyped(
          ODARequestCallout.post(QUOTES_PATH, requestParams)
        );

        quotes.put(amount, quote);
      }
    }
    return quotes;
  }
}