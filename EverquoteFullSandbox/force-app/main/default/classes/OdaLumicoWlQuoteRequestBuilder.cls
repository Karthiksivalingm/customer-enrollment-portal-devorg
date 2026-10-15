public class OdaLumicoWlQuoteRequestBuilder extends OdaQuoteRequestBuilder {
  public override Map<String, Object> buildQuoteRequest(OdaQuoteRequestData data) {
    Map<String, Object> requestParams = baseRequest(data);

    ((Map<String, Object>) requestParams.get('consumer_data'))
      .put('height', data.lead.Height_new__c);
    ((Map<String, Object>) requestParams.get('consumer_data'))
      .put('weight', data.lead.Weight_new__c);

    if (data.riders != null && data.riders.size() > 0) {
      ((Map<String, Object>) requestParams.get('consumer_data')).put('riders', data.riders);
    }

    if (string.isNotBlank(data.riskClass)) {
      ((Map<String, Object>) requestParams.get('consumer_data')).put('risk_class', data.riskClass);
    }

    return requestParams;
  }
}