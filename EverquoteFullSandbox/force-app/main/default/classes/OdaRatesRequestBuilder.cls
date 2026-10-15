public abstract class OdaRatesRequestBuilder {
  public abstract List<Integer> faceAmounts();
  public abstract Map<String, Object> buildRatesRequest(OdaRateLookupData lookupData);

  public Map<String, Object> baseRequest(Lead lead, String product, List<Integer> faceAmounts) {
    Map<String, Object> requestBody = new Map<String, Object>{
      'age' => lead.Age__c,
      'gender' => lead.Gender__c,
      'product' => product,
      'face_amounts' => faceAmounts
    };
    return requestBody;
  }
}