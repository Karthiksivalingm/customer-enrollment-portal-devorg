public class OdaLumicoAdRatesRequestBuilder extends OdaRatesRequestBuilder {
  public override List<Integer> faceAmounts() {
    return new List<Integer>{ 100000, 125000, 150000, 175000, 200000, 225000, 250000 };
  }

  public override Map<String, Object> buildRatesRequest(OdaRateLookupData lookupData) {
    Map<String, Object> requestParams = baseRequest(
      lookupData.lead,
      lookupData.product,
      faceAmounts()
    );
    requestParams.put('tobacco', lookupData.lead.Use_Tobacco__c);

    return requestParams;
  }
}