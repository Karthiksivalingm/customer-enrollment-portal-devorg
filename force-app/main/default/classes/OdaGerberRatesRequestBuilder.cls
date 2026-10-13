public class OdaGerberRatesRequestBuilder extends OdaRatesRequestBuilder {
  public override List<Integer> faceAmounts() {
    return new List<Integer>{ 5000, 10000, 15000, 20000, 25000 };
  }

  public override Map<String, Object> buildRatesRequest(OdaRateLookupData lookupData) {
    Map<String, Object> requestParams = baseRequest(
      lookupData.lead,
      lookupData.product,
      faceAmounts()
    );

    return requestParams;
  }
}