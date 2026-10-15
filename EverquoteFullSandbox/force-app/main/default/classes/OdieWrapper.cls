global class OdieWrapper {
  public static Map<String, Object> createForm(Lead lead) {
    Map<String, Object> formRequestBody = getCreateFormRequestBody(lead);

    System.debug(JSON.serialize(formRequestBody));
    String formCreateResponseBody = processOdieRequest(JSON.serialize(formRequestBody), 'forms');
    System.debug(formCreateResponseBody);

    Map<String, Object> formCreateResponse = (Map<String, Object>) JSON.deserializeUntyped(
      formCreateResponseBody
    );
    return formCreateResponse;
  }

  public static Map<String, Object> createLead(String formIdentifier, Lead lead) {
    Map<String, Object> leadRequestBody = getCreateLeadRequestBody(lead);

    System.debug(JSON.serialize(leadRequestBody));
    String leadCreateResponseBody = processOdieRequest(
      JSON.serialize(leadRequestBody),
      'forms/' +
      formIdentifier +
      '/leads'
    );
    System.debug(leadCreateResponseBody);

    Map<String, Object> leadCreateResponse = (Map<String, Object>) JSON.deserializeUntyped(
      leadCreateResponseBody
    );
    return leadCreateResponse;
  }

  @future(callout=true)
  public static void updateFormDisposition(Id leadId) {
    Lead lead = [
      SELECT Id, Lead_Outcome__c, Phone, EqLeadUuid__c, OwnerId, LastModifiedDate
      FROM Lead
      WHERE Id = :leadId
    ];

    Map<String, Object> updateFormRequestBody = getUpdateFormRequestBody(lead);

    System.debug('Update form disposition request body: ' + JSON.serialize(updateFormRequestBody));
    String updateFormResponseBody = processOdieRequest(
      JSON.serialize(updateFormRequestBody),
      'forms/update_sales_disposition'
    );
    System.debug(
      'Update form disposition response body: ' + JSON.serialize(updateFormResponseBody)
    );
  }

  @future(callout=true)
  public static void updateFormDispositionFuture(Id[] leadIds) {
    Lead[] leads = [
      SELECT Id, Lead_Outcome__c, Phone, EqLeadUuid__c, OwnerId, LastModifiedDate
      FROM Lead
      WHERE Id IN :leadIds
    ];

    for (Lead lead : leads) {
      Map<String, Object> updateFormRequestBody = getUpdateFormRequestBody(lead);

      System.debug('Update form disposition request body: ' + JSON.serialize(updateFormRequestBody));
      String updateFormResponseBody = processOdieRequest(
        JSON.serialize(updateFormRequestBody),
        'forms/update_sales_disposition'
      );
      System.debug(
        'Update form disposition response body: ' + JSON.serialize(updateFormResponseBody)
      );
    }
  }

  @future(callout=true)
  public static void syncLeadOwnerToOdieFuture(Id[] leadIds) {
    System.debug('Sync lead owner');
    Lead[] leads = [
      SELECT Id, Assigned_Date__c, Owner.Email, Owner.Name, EqLeadUuid__c
      FROM Lead
      WHERE Id IN :leadIds
    ];

    for (Lead lead : leads) {
      syncLeadOwnerToOdie(lead);
    }
  }

  @future(callout=true)
  public static void createRecordsForNewSalesforceLeadsFuture(Id[] leadIds) {
    Lead[] leads = [
      SELECT
        City,
        Coverage_Amount__c,
        Coverage_Type__c,
        Currently_Insured__c,
        Date_of_Birth__c,
        DUI_Conviction__c,
        Email,
        EqLeadUuid__c,
        OriginalEqLeadUuid__c,
        FirstName,
        Gender__c,
        Height__c,
        LastName,
        Marital_Status__c,
        Military_Affiliation__c,
        Occupation__c,
        Phone,
        PostalCode,
        Residency__c,
        State,
        Street,
        Use_Tobacco__c,
        Weight__c,
        What_is_your_major_condition__c,
        Owner.Email,
        Owner.Name,
        Assigned_Date__c,
        Oda_New_Lead_Source__c
      FROM Lead
      WHERE Id IN :leadIds
    ];

    for (Lead lead : leads) {
      String eqLeadUuid = createRecordsForNewSalesforceLead(lead);
      lead.EqLeadUuid__c = eqLeadUuid;
    }

    update leads;
  }

  public static String createRecordsForNewSalesforceLead(Lead lead) {
    if (lead.EqLeadUuid__c != null && lead.EqLeadUuid__c.length() != 0) {
      return lead.EqLeadUuid__c;
    }

    Map<String, Object> formCreateResponse = createForm(lead);
    String formPublicUuid = (String) formCreateResponse.get('public_uuid');

    Map<String, Object> leadCreateResponse = createLead(formPublicUuid, lead);
    String eqLeadUuid = (String) leadCreateResponse.get('eq_lead_uuid');

    return eqLeadUuid;
  }

  public static void syncLeadOwnerToOdie(Lead lead) {
    Map<String, Object> requestBody = getUpdateFormOwnerRequestBody(lead);

    System.debug('Update form owner request body: ' + JSON.serialize(requestBody));

    String responseBody = processOdieRequest(JSON.serialize(requestBody), 'forms/update_owner');
    System.debug('Update form owner response body: ' + JSON.serialize(responseBody));
  }

  public static String processOdieRequest(String requestBody, String endPointPath) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:Odie_API_Credential/' + endPointPath);
    req.setMethod('POST');
    req.setHeader('Content-Type', 'application/json');
    req.setBody(requestBody);
    system.debug('REQUEST BODY');
    system.debug(requestBody);

    Http http = new Http();

    HTTPResponse res = http.send(req);

    System.debug('HTTP response');

    if (res.getStatusCode() == 200) {
      return res.getBody();
    }

    return '{}';
  }

  private static Map<String, Object> getCreateFormRequestBody(Lead lead) {
    String uuidHex = EncodingUtil.ConvertTohex(Crypto.GenerateAESKey(128));
    String arrivalUuid =
      uuidHex.SubString(0, 8) +
      '-' +
      uuidHex.SubString(8, 12) +
      '-' +
      uuidHex.SubString(12, 16) +
      '-' +
      uuidHex.SubString(16, 20) +
      '-' +
      uuidHex.substring(20);
    Map<String, Object> requestBody = new Map<String, Object>{
      'arrival_uuid' => arrivalUuid,
      'client' => 'salesforce',
      'us_state' => lead.State,
      'currently_insured' => lead.Currently_Insured__c ? true : false,
      'uses_tobacco' => lead.Use_Tobacco__c ? true : false,
      'lead_source' => lead.Oda_New_Lead_Source__c,
      'lead_created_by' => UserInfo.getUserEmail()
    };

    requestBody.putAll(getUpdateFormOwnerRequestBody(lead));

    if (lead.Phone != null) {
      requestBody.put('phone_number', lead.Phone);
    }
    if (lead.State != null) {
      requestBody.put('state', lead.State);
    }

    if (lead.Date_of_Birth__c != null) {
      Date d = lead.Date_of_Birth__c;
      Datetime dt = DateTime.newInstance(d.year(), d.month(), d.day());
      requestBody.put('birth_date', dt.format('MM/dd/yyyy'));
    }

    if (lead.Marital_Status__c != null) {
      requestBody.put('marital_status', lead.Marital_Status__c.toLowercase());
    }

    if (lead.Residency__c != null) {
      requestBody.put('residence_type', lead.Residency__c.toLowercase());
    }

    if (lead.Gender__c == 'Male') {
      requestBody.put('gender', 'M');
    } else if (lead.Gender__c == 'Female') {
      requestBody.put('gender', 'F');
    }

    if (lead.OriginalEqLeadUuid__c != null) {
      requestBody.put('original_eq_lead_uuid', lead.OriginalEqLeadUuid__c);
    }

    return requestBody;
  }

  private static Map<String, Object> getCreateLeadRequestBody(Lead lead) {
    Map<String, Object> requestBody = new Map<String, Object>{
      'birth_date' => lead.Date_of_Birth__c,
      'city' => lead.City,
      'coverage_amount' => lead.Coverage_Amount__c,
      'email' => lead.Email,
      'first_name' => lead.FirstName,
      'gender' => lead.Gender__c,
      'dui_conviction' => lead.DUI_Conviction__c != 'No',
      'height' => lead.Height__c,
      'military' => lead.Military_Affiliation__c != 'No',
      'last_name' => lead.LastName,
      'major_conditions' => lead.What_is_your_major_condition__c,
      'marital_status' => lead.Marital_Status__c,
      'occupation' => lead.Occupation__c,
      'phone' => lead.Phone,
      'coverage_type' => lead.Coverage_Type__c,
      'residence' => lead.Residency__c,
      'state' => lead.State,
      'street_line_1' => lead.Street,
      'tobacco' => lead.Use_Tobacco__c,
      'vertical' => 'Life',
      'weight' => lead.Weight__c,
      'zip' => lead.PostalCode
    };

    return requestBody;
  }

  private static Map<String, Object> getUpdateFormOwnerRequestBody(Lead lead) {
    return new Map<String, Object>{
      'eq_lead_uuid' => lead.EqLeadUuid__c,
      'lead_owner' => getLeadOwner(lead),
      'lead_owner_updated_by' => UserInfo.getUserEmail(),
      'lead_owner_updated_at' => lead.Assigned_Date__c
    };
  }

  private static Map<String, Object> getUpdateFormRequestBody(Lead lead) {
    return new Map<String, Object>{
      'lead_outcome' => lead.Lead_Outcome__c,
      'phone' => lead.Phone,
      'eq_lead_uuid' => lead.EqLeadUuid__c,
      'updated_by' => UserInfo.getUserEmail(),
      'updated_at' => lead.LastModifiedDate
    };
  }

  private static String getLeadOwner(Lead lead) {
    if (lead.Owner.Email != null) {
      return lead.Owner.Email;
    } else {
      return lead.Owner.Name;
    }
  }
}