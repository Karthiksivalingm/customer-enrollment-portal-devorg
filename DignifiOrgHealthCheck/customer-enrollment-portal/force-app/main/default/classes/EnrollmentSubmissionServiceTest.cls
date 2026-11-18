@IsTest
private class EnrollmentSubmissionServiceTest {
  /**
   * Same situation as the site guest user: no Lead permissions at all.
   * Submission must still create the Lead, write only the mapped fields,
   * ignore extra properties sent by the browser, and return no record data.
   */
  @IsTest
  static void userWithoutLeadAccessCanSubmitOnlyMappedFields() {
    Profile minimum = [
      SELECT Id
      FROM Profile
      WHERE Name = 'Minimum Access - Salesforce'
      LIMIT 1
    ];
    User noAccess = new User(
      ProfileId = minimum.Id,
      LastName = 'No Lead Access',
      Email = 'no.lead.access@example.com',
      Username = 'no.lead.access.' +
        EnrollmentTestFactory.uniqueSuffix() +
        '@example.com',
      Alias = 'nolead',
      TimeZoneSidKey = 'America/Los_Angeles',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US'
    );
    insert noAccess;

    EnrollmentRequest request = EnrollmentTestFactory.request(2);
    // Extra properties a malicious browser might add; they must be ignored.
    Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(
      JSON.serialize(request)
    );
    body.put('Status', 'Closed - Converted');
    body.put('OwnerId', UserInfo.getUserId());
    Map<String, Object> company = (Map<String, Object>) body.get('company');
    company.put('Rating', 'Hot');
    company.put('Description', 'injected');

    EnrollmentSubmissionService.Result result;
    System.runAs(noAccess) {
      Assert.isFalse(
        Schema.SObjectType.Lead.isCreateable(),
        'Test user has no Lead create permission, like the guest user'
      );
      Test.startTest();
      result = EnrollmentSubmissionController.submitEnrollment(
        JSON.serialize(body)
      );
      Test.stopTest();
    }
    Assert.isTrue(result.success, '' + result.message + ' ' + result.errors);
    Assert.isFalse(
      JSON.serialize(result).contains('00Q'),
      'No Lead id is returned'
    );

    Lead saved = [
      SELECT Status, Rating, Description, OwnerId, Company, Email
      FROM Lead
    ];
    Assert.areEqual(request.company.companyName, saved.Company);
    Assert.areEqual(request.company.companyEmail, saved.Email);
    Assert.isNull(saved.Rating, 'Unmapped field from the request is ignored');
    Assert.areNotEqual(
      'injected',
      saved.Description,
      'Unmapped field from the request is ignored'
    );
    Assert.areNotEqual(
      'Closed - Converted',
      saved.Status,
      'Status cannot be set by the request'
    );
  }

  @IsTest
  static void validSubmissionCreatesExactlyOneLeadWithPeople() {
    User user = EnrollmentTestFactory.createUser(false);
    System.runAs(user) {
      EnrollmentRequest request = EnrollmentTestFactory.request(3);
      Test.startTest();
      Lead lead = EnrollmentTestFactory.submit(request);
      Test.stopTest();

      Lead saved = [
        SELECT
          Company,
          LastName,
          Email,
          CountryCode,
          StateCode,
          LeadSource,
          Enrollment_Person_Count__c,
          Enrollment_People__c
        FROM Lead
        WHERE Id = :lead.Id
      ];
      Assert.areEqual(request.company.companyName, saved.Company);
      Assert.areEqual(
        request.company.companyName,
        saved.LastName,
        'LastName holds the company name'
      );
      Assert.areEqual('US', saved.CountryCode);
      Assert.areEqual('CA', saved.StateCode);
      Assert.areEqual('Web', saved.LeadSource);
      Assert.areEqual(3, saved.Enrollment_Person_Count__c);

      EnrollmentPeopleSerializer.ParseResult parsed = EnrollmentPeopleSerializer.parse(
        saved.Enrollment_People__c
      );
      Assert.isTrue(parsed.valid, '' + parsed.message);
      Assert.areEqual(3, parsed.people.size());
      Assert.areEqual('P01', parsed.people[0].id);
      Assert.areEqual(request.people[1].email, parsed.people[1].email);
      Assert.isNull(parsed.people[1].phone, 'Blank phone stays blank');
      Assert.areEqual('Buyer', parsed.people[0].role, 'Role is stored');
      Assert.isFalse(
        saved.Enrollment_People__c.contains('jobTitle'),
        'New submissions store Role only'
      );
    }
    Assert.areEqual(1, [SELECT COUNT() FROM Lead], 'Exactly one Lead');
    Assert.areEqual(
      0,
      [SELECT COUNT() FROM Account],
      'No Account at submission'
    );
    Assert.areEqual(
      0,
      [SELECT COUNT() FROM Contact],
      'No Contact at submission'
    );
  }

  @IsTest
  static void repeatedSubmissionKeyCreatesOnlyOneLead() {
    User user = EnrollmentTestFactory.createUser(false);
    System.runAs(user) {
      String body = JSON.serialize(EnrollmentTestFactory.request(2));
      Test.startTest();
      EnrollmentSubmissionService.Result first = EnrollmentSubmissionController.submitEnrollment(
        body
      );
      EnrollmentSubmissionService.Result second = EnrollmentSubmissionController.submitEnrollment(
        body
      );
      Test.stopTest();
      Assert.isTrue(first.success, '' + first.message);
      Assert.isTrue(
        second.success,
        'A retry of the same submission is reported as success: ' +
        second.message
      );
    }
    Assert.areEqual(
      1,
      [SELECT COUNT() FROM Lead],
      'The unique submission key prevents a second Lead'
    );
  }

  @IsTest
  static void invalidSubmissionReturnsErrorsAndCreatesNothing() {
    User user = EnrollmentTestFactory.createUser(false);
    System.runAs(user) {
      EnrollmentRequest request = EnrollmentTestFactory.request(2);
      request.company.companyName = ' ';
      request.company.countryCode = 'ZZ';
      request.people[0].email = 'not-an-email';
      request.people[1].email = request.people[0].email;
      request.people[1].role = 'Chief Executive';
      request.people[0].role = null;

      EnrollmentSubmissionService.Result result = EnrollmentSubmissionController.submitEnrollment(
        JSON.serialize(request)
      );
      Assert.isFalse(result.success);
      String all = String.join(result.errors, ' | ');
      Assert.isTrue(all.contains('Company name is required.'), all);
      Assert.isTrue(all.contains('Country is not valid.'), all);
      Assert.isTrue(
        all.contains('Contact 1: Email is not in a valid format.'),
        all
      );
      Assert.isTrue(
        all.contains('Contact 2: Email is already used for another contact.'),
        all
      );
      Assert.isTrue(all.contains('Contact 2: Role is not valid.'), all);
      Assert.isTrue(all.contains('Contact 1: Role is required.'), all);
    }
    Assert.areEqual(0, [SELECT COUNT() FROM Lead]);
  }

  @IsTest
  static void fewerThanTwoContactsIsRejected() {
    User user = EnrollmentTestFactory.createUser(false);
    System.runAs(user) {
      EnrollmentSubmissionService.Result result = EnrollmentSubmissionController.submitEnrollment(
        JSON.serialize(EnrollmentTestFactory.request(1))
      );
      Assert.isFalse(result.success);
      Assert.isTrue(
        String.join(result.errors, ' | ')
          .contains('At least 2 contacts are required.')
      );
    }
    Assert.areEqual(0, [SELECT COUNT() FROM Lead]);
  }

  @IsTest
  static void moreThanMaximumPeopleIsRejected() {
    User user = EnrollmentTestFactory.createUser(false);
    System.runAs(user) {
      EnrollmentSubmissionService.Result result = EnrollmentSubmissionController.submitEnrollment(
        JSON.serialize(
          EnrollmentTestFactory.request(EnrollmentValidator.MAX_PEOPLE + 1)
        )
      );
      Assert.isFalse(result.success);
    }
    Assert.areEqual(0, [SELECT COUNT() FROM Lead]);
  }

  @IsTest
  static void botSignalsAreAcceptedSilentlyWithoutSaving() {
    User user = EnrollmentTestFactory.createUser(false);
    System.runAs(user) {
      EnrollmentRequest honeypot = EnrollmentTestFactory.request(1);
      honeypot.faxNumber = 'filled by a bot';
      EnrollmentRequest tooFast = EnrollmentTestFactory.request(1);
      tooFast.elapsedMs = 500;
      Assert.isTrue(
        EnrollmentSubmissionController.submitEnrollment(
            JSON.serialize(honeypot)
          )
          .success
      );
      Assert.isTrue(
        EnrollmentSubmissionController.submitEnrollment(JSON.serialize(tooFast))
          .success
      );
    }
    Assert.areEqual(0, [SELECT COUNT() FROM Lead]);
  }

  @IsTest
  static void malformedOrMissingKeyIsRejected() {
    User user = EnrollmentTestFactory.createUser(false);
    System.runAs(user) {
      Assert.isFalse(
        EnrollmentSubmissionController.submitEnrollment('{not json').success
      );
      Assert.isFalse(
        EnrollmentSubmissionController.submitEnrollment('').success
      );
      EnrollmentRequest badKey = EnrollmentTestFactory.request(1);
      badKey.submissionKey = 'abc';
      Assert.isFalse(
        EnrollmentSubmissionController.submitEnrollment(JSON.serialize(badKey))
          .success
      );
    }
    Assert.areEqual(0, [SELECT COUNT() FROM Lead]);
  }

  @IsTest
  static void countryOptionsIncludeStates() {
    List<EnrollmentAddressOptions.Option> countries = EnrollmentSubmissionController.getCountryOptions();
    EnrollmentAddressOptions.Option us;
    for (EnrollmentAddressOptions.Option country : countries) {
      if (country.value == 'US') {
        us = country;
      }
    }
    Assert.isNotNull(us, 'United States should be an active country');
    Boolean hasCalifornia = false;
    for (EnrollmentAddressOptions.Option state : us.states) {
      hasCalifornia = hasCalifornia || state.value == 'CA';
    }
    Assert.isTrue(
      hasCalifornia,
      'California should be a state of the United States'
    );
    Assert.isTrue(EnrollmentAddressOptions.isValidState('US', 'CA'));
    Assert.isFalse(EnrollmentAddressOptions.isValidState('US', 'ZZ'));
  }

  @IsTest
  static void serializerRejectsInvalidData() {
    Assert.isFalse(EnrollmentPeopleSerializer.parse(null).valid);
    Assert.isFalse(EnrollmentPeopleSerializer.parse('{bad').valid);
    Assert.isFalse(
      EnrollmentPeopleSerializer.parse('{"schemaVersion":2,"people":[]}').valid
    );
    Assert.isFalse(
      EnrollmentPeopleSerializer.parse(
          '{"schemaVersion":1,"people":[{"id":"P01"}]}'
        )
        .valid
    );
    Assert.isTrue(
      EnrollmentPeopleSerializer.parse(
          '{"schemaVersion":1,"people":[{"id":"P01","lastName":"A","email":"a@b.co"}]}'
        )
        .valid
    );
  }
}
