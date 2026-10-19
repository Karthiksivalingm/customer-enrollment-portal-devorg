public class OdaQuoteRequestProvider {
  public static Map<String, Object> getQuoteRequest(OdaQuoteRequestData data) {
    OdaQuoteRequestBuilder builder = getQuoteBuilderObject(data);
    return builder.buildQuoteRequest(data);
  }

  private static OdaQuoteRequestBuilder getQuoteBuilderObject(OdaQuoteRequestData data) {
    OdaQuoteRequestBuilder builder;
    if (string.isNotBlank(data.carrier)) {
      switch on data.carrier.toLowerCase() {
        when 'reliashield' {
          builder = new OdaReliashieldQuoteRequestBuilder();
        }
        when 'gerber' {
          builder = new OdaGerberQuoteRequestBuilder();
        }
        when 'aig' {
          builder = new OdaAigQuoteRequestBuilder();
        }
        when 'lumico' {
          builder = getLumicoQuoteBuilderObject(data.product);
        }
        when else {
          throw new ODAException('Invalid carrier: ' + '"' + data.carrier + '"');
        }
      }
      return builder;
    }
    throw new ODAException('Carrier not specified');
  }

  private static OdaQuoteRequestBuilder getLumicoQuoteBuilderObject(String product) {
    OdaQuoteRequestBuilder builder;
    if (string.isNotBlank(product)) {
      switch on product.toLowerCase() {
        when 'ad' {
          builder = new OdaLumicoAdQuoteRequestBuilder();
        }
        when 'wl' {
          builder = new OdaLumicoWlQuoteRequestBuilder();
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