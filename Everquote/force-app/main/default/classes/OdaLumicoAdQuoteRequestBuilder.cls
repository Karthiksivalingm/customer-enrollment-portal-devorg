public class OdaLumicoAdQuoteRequestBuilder extends OdaQuoteRequestBuilder {
  public override Map<String, Object> buildQuoteRequest(OdaQuoteRequestData data) {
    Map<String, Object> requestParams = baseRequest(data);

    return requestParams;
  }
}