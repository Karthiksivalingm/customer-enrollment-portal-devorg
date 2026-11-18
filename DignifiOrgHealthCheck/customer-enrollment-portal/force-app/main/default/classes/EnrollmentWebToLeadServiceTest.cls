/**
 * Tests for the Web-to-Lead enrollment channel. Apex tests cannot call the real
 * Web-to-Lead servlet, so a Web-to-Lead post is simulated by inserting a Lead with
 * the same fields the form posts (standard company fields, the UUID key and the
 * contacts payload).
 */
@IsTest
private class EnrollmentWebToLeadServiceTest {
  // ---------- helpers ----------

  private static String payload(Object people) {
    return JSON.serialize(
      new Map<String, Object>{ 'schemaVersion' => 1, 'people' => people }
    );
  }

  /** A Lead exactly as the Web-to-Lead form posts it. */
  private static Lead webToLeadLead(EnrollmentRequest request) {
    return new Lead(
      Company = request.company.companyName,
      LastName = '[not provided]',
      Email = request.company.companyEmail,
      Website = request.company.website,
      Phone = request.company.companyPhone,
      Street = request.company.street,
      City = request.company.city,
      StateCode = request.company.stateCode,
      CountryCode = request.company.countryCode,
      PostalCode = request.company.postalCode,
      Enrollment_Submission_Key__c = request.submissionKey,
      Enrollment_W2L_Payload__c = payload(request.people)
    );
  }

  /** The people JSON the Experience channel would store for the same input. */
  private static String expectedPeopleJson(List<EnrollmentPerson> people) {
    List<EnrollmentPerson> expected = new List<EnrollmentPerson>();
    for (Integer i = 0; i < people.size(); i++) {
      EnrollmentPerson p = new EnrollmentPerson();
      p.id = 'P' + String.valueOf(i + 1).leftPad(2, '0');
      p.firstName = EnrollmentValidator.clean(people[i].firstName);
      p.lastName = EnrollmentValidator.clean(people[i].lastName);
      p.email = EnrollmentValidator.clean(people[i].email);
      p.phone = EnrollmentValidator.clean(people[i].phone);
      p.role = EnrollmentValidator.clean(people[i].role);
      expected.add(p);
    }
    return EnrollmentPeopleSerializer.serialize(expected);
  }

  private static void assertRejected(Lead lead, String expectedFragment) {
    // SYSTEM_MODE: like Web-to-Lead itself, the simulated post does not depend on
    // the running user's field access (nobody has access to the payload field).
    Database.SaveResult result = Database.insert(
      lead,
      false,
      AccessLevel.SYSTEM_MODE
    );
    Assert.isFalse(result.isSuccess(), 'The submission must be rejected');
    String message = result.getErrors()[0].getMessage();
    Assert.isTrue(
      message.containsIgnoreCase(expectedFragment),
      'Expected "' + expectedFragment + '" in: ' + message
    );
    Assert.areEqual(0, [SELECT COUNT() FROM Lead], 'No Lead is created');
  }

  private static Lead saved(Id leadId) {
    return [
      SELECT
        Company,
        LastName,
        FirstName,
        Email,
        LeadSource,
        CountryCode,
        StateCode,
        Enrollment_People__c,
        Enrollment_Person_Count__c,
        Enrollment_Submission_Key__c,
        Enrollment_Submitted_At__c,
        Enrollment_Channel__c,
        Enrollment_W2L_Payload__c
      FROM Lead
      WHERE Id = :leadId
      WITH SYSTEM_MODE
    ];
  }

  // ---------- successful submissions ----------

  @IsTest
  static void twoContactsCreateOneEnrollmentLead() {
    User user = EnrollmentTestFactory.createUser(true);
    System.runAs(user) {
      EnrollmentRequest request = EnrollmentTestFactory.request(2);
      request.submissionKey = request.submissionKey.toUpperCase();
      request.people[1].role = 'AP';
      Lead lead = webToLeadLead(request);

      Test.startTest();
      insert as system lead;
      Test.stopTest();

      Lead result = saved(lead.Id);
      Assert.areEqual(request.company.companyName, result.Company);
      Assert.areEqual(
        request.company.companyName,
        result.LastName,
        'LastName holds the company name, as in the Experience channel'
      );
      Assert.areEqual('Web', result.LeadSource);
      Assert.areEqual('US', result.CountryCode);
      Assert.areEqual('CA', result.StateCode);
      Assert.areEqual(2, result.Enrollment_Person_Count__c);
      Assert.areEqual(
        request.submissionKey.toLowerCase(),
        result.Enrollment_Submission_Key__c
      );
      Assert.isNotNull(result.Enrollment_Submitted_At__c);
      Assert.areEqual('Web-to-Lead', result.Enrollment_Channel__c);
      Assert.isNull(
        result.Enrollment_W2L_Payload__c,
        'The temporary payload is cleared'
      );
      Assert.areEqual(
        expectedPeopleJson(request.people),
        result.Enrollment_People__c,
        'Same schema v1 JSON as the Experience channel'
      );

      // Same Lead experience: the existing panel and conversion preview accept it.
      EnrollmentPeopleController.PanelData panel = EnrollmentPeopleController.getPeople(
        lead.Id
      );
      Assert.isTrue(panel.isEnrollment);
      Assert.isTrue(panel.valid, '' + panel.message);
      Assert.isNull(panel.message);
      Assert.areEqual(2, panel.people.size());
      Assert.areEqual('Account Payable', panel.people[1].roleLabel);
      Assert.isTrue(panel.canConvert);
    }
    Assert.areEqual(1, [SELECT COUNT() FROM Lead], 'Exactly one Lead');
    Assert.areEqual(0, [SELECT COUNT() FROM Account], 'No Account');
    Assert.areEqual(0, [SELECT COUNT() FROM Contact], 'No Contact');
  }

  @IsTest
  static void twentyFiveContactsWithMaximumLengthValues() {
    EnrollmentRequest request = EnrollmentTestFactory.request(25);
    for (Integer i = 0; i < 25; i++) {
      EnrollmentPerson p = request.people[i];
      String n = String.valueOf(i + 1).leftPad(2, '0');
      p.firstName = ('F' + n).rightPad(40, 'f');
      p.lastName = ('L' + n).rightPad(80, 'l');
      p.email =
        ('e' + n).rightPad(80 - '@example.com'.length(), 'e') + '@example.com';
      p.phone = '+1 555 010 ' + n + '0 000 000';
      p.role = 'Broker / Agency Rep';
    }
    Lead lead = webToLeadLead(request);
    Test.startTest();
    insert as system lead;
    Test.stopTest();

    Lead result = saved(lead.Id);
    Assert.areEqual(25, result.Enrollment_Person_Count__c);
    EnrollmentPeopleSerializer.ParseResult parsed = EnrollmentPeopleSerializer.parse(
      result.Enrollment_People__c
    );
    Assert.isTrue(parsed.valid, '' + parsed.message);
    Assert.areEqual(25, parsed.people.size());
    Assert.areEqual('P25', parsed.people[24].id);
    Assert.areEqual(80, parsed.people[24].email.length());
  }

  // ---------- rejected submissions ----------

  @IsTest
  static void oneContactIsRejected() {
    assertRejected(
      webToLeadLead(EnrollmentTestFactory.request(1)),
      'At least 2 contacts are required.'
    );
  }

  @IsTest
  static void twentySixContactsAreRejected() {
    assertRejected(
      webToLeadLead(EnrollmentTestFactory.request(26)),
      'A maximum of 25 contacts can be submitted.'
    );
  }

  @IsTest
  static void invalidContactEmailIsRejected() {
    EnrollmentRequest request = EnrollmentTestFactory.request(2);
    request.people[0].email = 'not-an-email';
    assertRejected(
      webToLeadLead(request),
      'Contact 1: Email is not in a valid format.'
    );
  }

  @IsTest
  static void duplicateContactEmailsAreRejected() {
    EnrollmentRequest request = EnrollmentTestFactory.request(2);
    request.people[1].email = request.people[0].email.toUpperCase();
    assertRejected(
      webToLeadLead(request),
      'Contact 2: Email is already used for another contact.'
    );
  }

  @IsTest
  static void missingRoleIsRejected() {
    EnrollmentRequest request = EnrollmentTestFactory.request(2);
    request.people[1].role = null;
    assertRejected(webToLeadLead(request), 'Contact 2: Role is required.');
  }

  @IsTest
  static void invalidRoleIsRejected() {
    EnrollmentRequest request = EnrollmentTestFactory.request(2);
    request.people[0].role = 'Chief Executive';
    assertRejected(webToLeadLead(request), 'Contact 1: Role is not valid.');
  }

  @IsTest
  static void invalidCountryIsRejected() {
    EnrollmentRequest request = EnrollmentTestFactory.request(2);
    Lead lead = webToLeadLead(request);
    lead.StateCode = null;
    lead.CountryCode = 'ZZ';
    // Rejected by the validator ("Country is not valid.") or by the platform picklist.
    assertRejected(lead, 'country');
  }

  @IsTest
  static void missingCountryIsRejected() {
    Lead lead = webToLeadLead(EnrollmentTestFactory.request(2));
    lead.StateCode = null;
    lead.CountryCode = null;
    assertRejected(lead, 'Country is required.');
  }

  @IsTest
  static void invalidStateIsRejected() {
    EnrollmentRequest request = EnrollmentTestFactory.request(2);
    Lead lead = webToLeadLead(request);
    // TX is a US state, not valid for India. Rejected by the validator or the platform.
    lead.CountryCode = 'IN';
    lead.StateCode = 'TX';
    assertRejected(lead, 'state');
  }

  @IsTest
  static void malformedJsonIsRejected() {
    Lead lead = webToLeadLead(EnrollmentTestFactory.request(2));
    lead.Enrollment_W2L_Payload__c = '{"schemaVersion":1,"people":[{';
    assertRejected(lead, 'Contacts could not be read.');
  }

  @IsTest
  static void wrongSchemaVersionIsRejected() {
    Lead lead = webToLeadLead(EnrollmentTestFactory.request(2));
    lead.Enrollment_W2L_Payload__c = lead.Enrollment_W2L_Payload__c.replace(
      '"schemaVersion":1',
      '"schemaVersion":2'
    );
    assertRejected(lead, 'Contacts use an unsupported format.');
  }

  @IsTest
  static void missingSubmissionKeyIsRejected() {
    Lead lead = webToLeadLead(EnrollmentTestFactory.request(2));
    lead.Enrollment_Submission_Key__c = null;
    assertRejected(lead, 'Submission key is required.');
  }

  @IsTest
  static void invalidSubmissionKeyIsRejected() {
    Lead lead = webToLeadLead(EnrollmentTestFactory.request(2));
    lead.Enrollment_Submission_Key__c = 'not-a-uuid';
    assertRejected(lead, 'Submission key is not valid.');
  }

  @IsTest
  static void missingCompanyPlaceholderIsRejected() {
    Lead lead = webToLeadLead(EnrollmentTestFactory.request(2));
    lead.Company = '[not provided]';
    assertRejected(lead, 'Company name is required.');
  }

  @IsTest
  static void channelLabelWithoutPayloadIsRejected() {
    Lead lead = webToLeadLead(EnrollmentTestFactory.request(2));
    lead.Enrollment_W2L_Payload__c = null;
    lead.Enrollment_Channel__c = 'Web-to-Lead';
    assertRejected(lead, 'Contacts are missing.');
  }

  @IsTest
  static void duplicateSubmissionKeyCreatesOnlyOneLead() {
    EnrollmentRequest first = EnrollmentTestFactory.request(2);
    insert as system webToLeadLead(first);

    EnrollmentRequest second = EnrollmentTestFactory.request(2);
    second.submissionKey = first.submissionKey;
    Database.SaveResult result = Database.insert(
      webToLeadLead(second),
      false,
      AccessLevel.SYSTEM_MODE
    );
    Assert.isFalse(result.isSuccess(), 'Repeated key is rejected');
    Assert.areEqual(1, [SELECT COUNT() FROM Lead], 'Exactly one Lead');
  }

  // ---------- untrusted input ----------

  @IsTest
  static void extraJsonPropertiesAreIgnored() {
    EnrollmentRequest request = EnrollmentTestFactory.request(2);
    List<Object> people = new List<Object>();
    for (EnrollmentPerson p : request.people) {
      Map<String, Object> raw = (Map<String, Object>) JSON.deserializeUntyped(
        JSON.serialize(p)
      );
      raw.put('id', 'X99');
      raw.put('jobTitle', 'Injected title');
      raw.put('roleLabel', 'Injected label');
      raw.put('isAdmin', true);
      people.add(raw);
    }
    Lead lead = webToLeadLead(request);
    Map<String, Object> envelope = new Map<String, Object>{
      'schemaVersion' => 1,
      'people' => people,
      'ownerId' => UserInfo.getUserId()
    };
    lead.Enrollment_W2L_Payload__c = JSON.serialize(envelope);
    insert as system lead;

    String stored = saved(lead.Id).Enrollment_People__c;
    Assert.areEqual(expectedPeopleJson(request.people), stored);
    Assert.isFalse(stored.contains('X99'), 'Posted ids are replaced');
    Assert.isFalse(stored.contains('Injected'), 'Extra properties are dropped');
    Assert.isFalse(stored.contains('isAdmin'));
    Assert.isFalse(stored.contains('ownerId'));
  }

  @IsTest
  static void postedTrustedFieldsAreOverwritten() {
    EnrollmentRequest request = EnrollmentTestFactory.request(2);
    Lead lead = webToLeadLead(request);
    lead.Company = '  ' + request.company.companyName + '  ';
    lead.LastName = 'Spoofed';
    lead.LeadSource = 'Other';
    lead.Enrollment_People__c = '{"schemaVersion":1,"people":[{"id":"P01","lastName":"Fake","email":"fake@example.com"}]}';
    lead.Enrollment_Person_Count__c = 99;
    lead.Enrollment_Submitted_At__c = Datetime.newInstanceGmt(2000, 1, 1);
    insert as system lead;

    Lead result = saved(lead.Id);
    Assert.areEqual(request.company.companyName, result.Company);
    Assert.areEqual(request.company.companyName, result.LastName);
    Assert.areEqual('Web', result.LeadSource);
    Assert.areEqual(2, result.Enrollment_Person_Count__c);
    Assert.areEqual(
      expectedPeopleJson(request.people),
      result.Enrollment_People__c
    );
    Assert.isTrue(result.Enrollment_Submitted_At__c.year() > 2000);
    Assert.areEqual('Web-to-Lead', result.Enrollment_Channel__c);
  }

  @IsTest
  static void directEnrollmentFieldsAreRejectedInWebToLeadContext() {
    // Bypass attempt: key and people posted directly, no payload, no channel.
    EnrollmentRequest request = EnrollmentTestFactory.request(2);
    Lead lead = webToLeadLead(request);
    lead.Enrollment_W2L_Payload__c = null;
    lead.Enrollment_People__c = expectedPeopleJson(request.people);
    lead.Enrollment_Person_Count__c = 2;
    EnrollmentWebToLeadService.simulateWebToLeadContext = true;
    assertRejected(lead, EnrollmentWebToLeadService.DIRECT_FIELDS_MESSAGE);
  }

  @IsTest
  static void testContextIsNotTreatedAsWebToLead() {
    Assert.isFalse(
      EnrollmentWebToLeadService.isWebToLeadContext(),
      'Apex test (RUNTEST) context must never be treated as Web-to-Lead'
    );
  }

  // ---------- isolation: ordinary and Experience Cloud Leads ----------

  @IsTest
  static void ordinaryLeadsAreUnchanged() {
    Lead normal = new Lead(
      FirstName = 'Ordinary',
      LastName = 'Lead',
      Company = 'Ordinary Co',
      Email = 'ordinary.' +
        EnrollmentTestFactory.uniqueSuffix() +
        '@example.com',
      LeadSource = 'Phone Inquiry'
    );
    insert normal;
    // Also in the Web-to-Lead context: an ordinary Web-to-Lead Lead is untouched.
    EnrollmentWebToLeadService.simulateWebToLeadContext = true;
    Lead ordinaryWebToLead = new Lead(
      LastName = 'Visitor',
      Company = 'Visitor Co',
      Email = 'visitor.' +
        EnrollmentTestFactory.uniqueSuffix() +
        '@example.com',
      LeadSource = 'Web'
    );
    insert ordinaryWebToLead;

    for (Lead l : [
      SELECT
        FirstName,
        LastName,
        Company,
        LeadSource,
        Enrollment_Channel__c,
        Enrollment_People__c,
        Enrollment_Submission_Key__c,
        Enrollment_Person_Count__c,
        Enrollment_Submitted_At__c
      FROM Lead
      ORDER BY CreatedDate, Id
    ]) {
      Assert.isNull(l.Enrollment_Channel__c);
      Assert.isNull(l.Enrollment_People__c);
      Assert.isNull(l.Enrollment_Submission_Key__c);
      Assert.isNull(l.Enrollment_Person_Count__c);
      Assert.isNull(l.Enrollment_Submitted_At__c);
    }
    Lead first = [
      SELECT FirstName, LastName, Company, LeadSource
      FROM Lead
      WHERE Id = :normal.Id
    ];
    Assert.areEqual('Ordinary', first.FirstName);
    Assert.areEqual('Lead', first.LastName);
    Assert.areEqual('Ordinary Co', first.Company);
    Assert.areEqual('Phone Inquiry', first.LeadSource);
  }

  @IsTest
  static void experienceCloudSubmissionIsUnchanged() {
    User user = EnrollmentTestFactory.createUser(false);
    EnrollmentRequest request = EnrollmentTestFactory.request(3);
    request.people[0].role = 'Primary Contact';
    // Fields an attacker might add to the Experience request; they must be ignored.
    Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(
      JSON.serialize(request)
    );
    body.put('Enrollment_Channel__c', 'Web-to-Lead');
    body.put('Enrollment_W2L_Payload__c', payload(request.people));
    body.put('channel', 'Web-to-Lead');
    ((Map<String, Object>) body.get('company'))
      .put('Enrollment_Channel__c', 'Web-to-Lead');

    EnrollmentSubmissionService.Result result;
    System.runAs(user) {
      Test.startTest();
      result = EnrollmentSubmissionController.submitEnrollment(
        JSON.serialize(body)
      );
      Test.stopTest();
    }
    Assert.isTrue(result.success, '' + result.message + ' ' + result.errors);

    Lead lead = [
      SELECT
        Id,
        Company,
        LastName,
        Email,
        LeadSource,
        Enrollment_People__c,
        Enrollment_Person_Count__c,
        Enrollment_Submission_Key__c,
        Enrollment_Channel__c,
        Enrollment_W2L_Payload__c
      FROM Lead
      WITH SYSTEM_MODE
    ];
    Assert.isNull(
      lead.Enrollment_Channel__c,
      'Experience Leads have no channel label'
    );
    Assert.isNull(lead.Enrollment_W2L_Payload__c);
    Assert.areEqual(request.company.companyName, lead.Company);
    Assert.areEqual(request.company.companyName, lead.LastName);
    Assert.areEqual('Web', lead.LeadSource);
    Assert.areEqual(3, lead.Enrollment_Person_Count__c);
    Assert.areEqual(
      request.submissionKey.toLowerCase(),
      lead.Enrollment_Submission_Key__c
    );
    Assert.areEqual(
      expectedPeopleJson(request.people),
      lead.Enrollment_People__c,
      'Experience JSON is exactly what the Experience service writes'
    );
  }

  // ---------- same conversion experience ----------

  @IsTest
  static void webToLeadLeadConvertsWithExistingConversionService() {
    User user = EnrollmentTestFactory.createUser(true);
    System.runAs(user) {
      Lead lead = webToLeadLead(EnrollmentTestFactory.request(3));
      insert as system lead;

      EnrollmentConversionService.Preview preview = EnrollmentConversionController.getConversionPreview(
        lead.Id
      );
      Assert.isTrue(preview.canConvert, '' + preview.message);
      Assert.areEqual(3, preview.people.size());

      Test.startTest();
      EnrollmentConversionService.Result result = EnrollmentConversionController.convertEnrollment(
        lead.Id,
        EnrollmentTestFactory.conversionRequestJson(preview)
      );
      Test.stopTest();

      Assert.isTrue(result.success, '' + result.message);
      Assert.areEqual(3, result.contactCount);
      Lead converted = [
        SELECT IsConverted, ConvertedAccountId, ConvertedOpportunityId
        FROM Lead
        WHERE Id = :lead.Id
      ];
      Assert.isTrue(converted.IsConverted);
      Assert.areEqual(result.accountId, converted.ConvertedAccountId);
      Assert.isNull(converted.ConvertedOpportunityId, 'No Opportunity');
    }
    Assert.areEqual(1, [SELECT COUNT() FROM Account]);
    Assert.areEqual(
      3,
      [SELECT COUNT() FROM Contact WHERE AccountId != NULL],
      'One Contact per submitted person, all on the Account'
    );
  }
}
