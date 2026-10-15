public class OdaReliashieldRateRequestBuilder extends OdaRatesRequestBuilder {
  public override List<Integer> faceAmounts() {
    return new List<Integer>{};
  }

  public override Map<String, Object> buildRatesRequest(OdaRateLookupData lookupData) {
    Map<String, Object> requestParams = new Map<String, Object>{
      'product' => lookupData.product
    };

    return requestParams;
  }
}