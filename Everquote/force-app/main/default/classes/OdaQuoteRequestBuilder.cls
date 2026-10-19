public abstract class OdaQuoteRequestBuilder {
  public abstract Map<String, Object> buildQuoteRequest(OdaQuoteRequestData data);

  public Map<String, Object> baseRequest(OdaQuoteRequestData data) {
    Lead lead = data.lead;

    Map<String, Object> requestBody = new Map<String, Object>{
      'eq_lead_uuid' => lead.EqLeadUuid__c,
      'client' => 'salesforce',
      'consumer_data' => new Map<String, Object>{
        'eq_lead_uuid' => lead.EqLeadUuid__c,
        'carrier' => data.carrier,
        'product_name' => data.product,
        'state' => lead.State,
        'birth_date' => OdaUtils.formatBirthDate(lead.Date_Of_Birth__c),
        'gender' => lead.Gender__c.substring(0, 1),
        'uses_tobacco' => lead.Use_Tobacco__c,
        'modified' => lead.Modified__c,
        'has_major_condition' => lead.Major_Condition_Past_Year__c.substring(0, 1) == 'Y',
        'face_amount' => data.faceAmount
      }
    };

    return requestBody;
  }
}