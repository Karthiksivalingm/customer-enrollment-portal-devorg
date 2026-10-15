public class OdaLumicoWlRatesRequestBuilder extends OdaRatesRequestBuilder {
  public override List<Integer> faceAmounts() {
    return new List<Integer>();
  }

  public override Map<String, Object> buildRatesRequest(OdaRateLookupData lookupData) {
    Lead lead = lookupData.lead;
    Map<String, Object> requestParams = new Map<String, Object>{
      'state' => lead.State,
      'gender' => lead.Gender__c.substring(0, 1),
      'birth_date' => OdaUtils.formatBirthDate(lead.Date_Of_Birth__c),
      'amount_band' => lookupData.amounts,
      'eq_lead_uuid' => lead.EqLeadUuid__c,
      'tobacco' => lead.Use_Tobacco__c,
      'has_major_condition' => lead.Major_Condition_Past_Year__c.substring(0, 1) == 'Y',
      'height' => lead.Height_new__c,
      'weight' => lead.Weight_new__c
    };

    if (string.isNotBlank(lookupData.riskClass)) {
      ((Map<String, Object>) requestParams).put('risk_class', lookupData.riskClass);
    }

    return requestParams;
  }
}