@IsTest
private class EnrollmentConversionServiceTest {
  @IsTest
  static void conversionCreatesOneAccountAndAllContacts() {
    User user = EnrollmentTestFactory.createUser(true);
    System.runAs(user) {
      EnrollmentRequest request = EnrollmentTestFactory.request(3);
      Lead lead = EnrollmentTestFactory.submit(request);

      EnrollmentConversionService.Preview preview = EnrollmentConversionController.getConversionPreview(
        lead.Id
      );
      Assert.isTrue(preview.canConvert, '' + preview.message);
      Assert.areEqual(3, preview.people.size());
      preview.people[2].role = 'AP';

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

      Assert.areEqual(1, [SELECT COUNT() FROM Account], 'Exactly one Account');
      Account account = [
        SELECT Name, Industry, BillingCountryCode
        FROM Account
        WHERE Id = :result.accountId
      ];
      Assert.areEqual(request.company.companyName, account.Name);
      Assert.isNull(
        account.Industry,
        'Industry forced by org automation is reverted for enrollment Accounts'
      );
      Assert.areEqual('US', account.BillingCountryCode);

      List<Contact> contacts = [
        SELECT
          FirstName,
          Email,
          Phone,
          Title,
          Description,
          AccountId,
          Enrollment_Person_Key__c,
          Enrollment_Source_Lead__c
        FROM Contact
        ORDER BY Enrollment_Person_Key__c
      ];
      Assert.areEqual(
        3,
        contacts.size(),
        'Exactly one Contact per submitted person, no extra Contact from the Lead'
      );
      for (Integer i = 0; i < contacts.size(); i++) {
        Contact c = contacts[i];
        Assert.areEqual(result.accountId, c.AccountId);
        Assert.areEqual(lead.Id, c.Enrollment_Source_Lead__c);
        Assert.areEqual(
          EnrollmentConversionService.personKey(lead.Id, 'P0' + (i + 1)),
          c.Enrollment_Person_Key__c
        );
        Assert.areEqual(request.people[i].email, c.Email);
        Assert.areEqual(
          request.people[i].phone,
          c.Phone,
          'Phone is exactly what was submitted (blank stays blank)'
        );
        Assert.isNull(
          c.Description,
          'Description forced by org automation is reverted'
        );
      }
      Assert.areEqual(
        'Buyer',
        contacts[0].Title,
        'The submitted Role label is the Contact title'
      );
      Assert.areEqual(
        'Account Payable',
        contacts[2].Title,
        'Role edits from the conversion screen are applied (AP is shown as Account Payable)'
      );

      // People panel now links each person to their Contact.
      EnrollmentPeopleController.PanelData panel = EnrollmentPeopleController.getPeople(
        lead.Id
      );
      Assert.isTrue(panel.isConverted);
      Assert.isFalse(panel.canConvert);
      for (EnrollmentPerson person : panel.people) {
        Assert.isNotNull(
          person.contactId,
          'Each person is linked to their Contact'
        );
      }
    }
  }

  @IsTest
  static void legacyJobTitleIsPreserved() {
    // Leads submitted before Role existed store a free-text "jobTitle" and no "role".
    Lead legacy = new Lead(
      LastName = 'Legacy',
      Company = 'Legacy Co',
      Email = 'l.' + EnrollmentTestFactory.uniqueSuffix() + '@example.com',
      Enrollment_Submission_Key__c = EnrollmentTestFactory.newUuid(),
      Enrollment_People__c = '{"schemaVersion":1,"people":[' +
        '{"id":"P01","firstName":"Ann","lastName":"One","email":"ann.' +
        EnrollmentTestFactory.uniqueSuffix() +
        '@example.com","jobTitle":"Legacy Developer"},' +
        '{"id":"P02","firstName":"Bob","lastName":"Two","email":"bob.' +
        EnrollmentTestFactory.uniqueSuffix() +
        '@example.com","jobTitle":"Legacy Artist"}]}'
    );
    System.runAs(EnrollmentTestFactory.createUser(true)) {
      insert legacy;
      EnrollmentPeopleController.PanelData panel = EnrollmentPeopleController.getPeople(
        legacy.Id
      );
      Assert.isTrue(panel.valid, '' + panel.message);
      Assert.areEqual('Legacy Developer', panel.people[0].roleLabel);

      EnrollmentConversionService.Preview preview = EnrollmentConversionController.getConversionPreview(
        legacy.Id
      );
      Assert.isTrue(preview.canConvert, '' + preview.message);
      preview.people[1].role = 'EDI Contact';
      preview.people[0].jobTitle = 'Ignored: not editable';
      Test.startTest();
      EnrollmentConversionService.Result result = EnrollmentConversionController.convertEnrollment(
        legacy.Id,
        EnrollmentTestFactory.conversionRequestJson(preview)
      );
      Test.stopTest();
      Assert.isTrue(result.success, '' + result.message);
    }
    List<Contact> contacts = [
      SELECT Title
      FROM Contact
      ORDER BY Enrollment_Person_Key__c
    ];
    Assert.areEqual(2, contacts.size());
    Assert.areEqual(
      'Legacy Developer',
      contacts[0].Title,
      'Without a Role, the submitted job title is kept'
    );
    Assert.areEqual(
      'EDI Contact',
      contacts[1].Title,
      'A selected Role takes priority over the legacy job title'
    );
  }

  @IsTest
  static void secondConversionDoesNotCreateRecords() {
    User user = EnrollmentTestFactory.createUser(true);
    System.runAs(user) {
      Lead lead = EnrollmentTestFactory.submit(
        EnrollmentTestFactory.request(2)
      );
      String body = EnrollmentTestFactory.conversionRequestJson(
        EnrollmentConversionController.getConversionPreview(lead.Id)
      );
      EnrollmentConversionService.Result first = EnrollmentConversionController.convertEnrollment(
        lead.Id,
        body
      );
      Test.startTest();
      EnrollmentConversionService.Result second = EnrollmentConversionController.convertEnrollment(
        lead.Id,
        body
      );
      Test.stopTest();
      Assert.isTrue(first.success, '' + first.message);
      Assert.isTrue(second.alreadyConverted, 'Repeated conversion is detected');
      Assert.areEqual(first.accountId, second.accountId);
    }
    Assert.areEqual(1, [SELECT COUNT() FROM Account]);
    Assert.areEqual(2, [SELECT COUNT() FROM Contact]);
  }

  @IsTest
  static void invalidEditsRollBackEverything() {
    User user = EnrollmentTestFactory.createUser(true);
    System.runAs(user) {
      Lead lead = EnrollmentTestFactory.submit(
        EnrollmentTestFactory.request(2)
      );
      EnrollmentConversionService.Preview preview = EnrollmentConversionController.getConversionPreview(
        lead.Id
      );
      preview.people[1].email = 'broken';
      Boolean failed = false;
      try {
        EnrollmentConversionController.convertEnrollment(
          lead.Id,
          EnrollmentTestFactory.conversionRequestJson(preview)
        );
      } catch (AuraHandledException ex) {
        failed = ex.getMessage()
          .contains('Contact 2: Email is not in a valid format.');
      }
      Assert.isTrue(failed, 'Invalid edits are rejected with a clear message');

      // Removing a person is not allowed: all submitted people must be converted.
      preview = EnrollmentConversionController.getConversionPreview(lead.Id);
      preview.people.remove(1);
      failed = false;
      try {
        EnrollmentConversionController.convertEnrollment(
          lead.Id,
          EnrollmentTestFactory.conversionRequestJson(preview)
        );
      } catch (AuraHandledException ex) {
        failed = true;
      }
      Assert.isTrue(failed, 'Missing people are rejected');
      Assert.isFalse(
        [SELECT IsConverted FROM Lead WHERE Id = :lead.Id].IsConverted
      );
    }
    Assert.areEqual(0, [SELECT COUNT() FROM Account], 'Nothing left behind');
    Assert.areEqual(0, [SELECT COUNT() FROM Contact], 'Nothing left behind');
  }

  @IsTest
  static void conversionRequiresCustomPermission() {
    Lead lead;
    System.runAs(EnrollmentTestFactory.createUser(true)) {
      lead = EnrollmentTestFactory.submit(EnrollmentTestFactory.request(2));
    }
    System.runAs(EnrollmentTestFactory.createUser(false)) {
      EnrollmentConversionService.Preview preview = EnrollmentConversionController.getConversionPreview(
        lead.Id
      );
      Assert.isFalse(preview.canConvert);
      Boolean blocked = false;
      try {
        EnrollmentConversionController.convertEnrollment(
          lead.Id,
          EnrollmentTestFactory.conversionRequestJson(preview)
        );
      } catch (AuraHandledException ex) {
        blocked = ex.getMessage().contains('permission');
      }
      Assert.isTrue(
        blocked,
        'Users without Convert_Enrollment_Leads cannot convert'
      );
    }
    Assert.areEqual(0, [SELECT COUNT() FROM Contact]);
  }

  @IsTest
  static void standardConversionIsBlockedForEnrollmentLeads() {
    System.runAs(EnrollmentTestFactory.createUser(true)) {
      Lead lead = EnrollmentTestFactory.submit(
        EnrollmentTestFactory.request(2)
      );
      Database.LeadConvert lc = new Database.LeadConvert();
      lc.setLeadId(lead.Id);
      lc.setConvertedStatus(
        [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1]
        .MasterLabel
      );
      lc.setDoNotCreateOpportunity(true);
      Database.LeadConvertResult result = Database.convertLead(lc, false);
      Assert.isFalse(
        result.isSuccess(),
        'Standard conversion must not bypass the enrollment conversion'
      );
      Assert.isFalse(
        [SELECT IsConverted FROM Lead WHERE Id = :lead.Id].IsConverted
      );
    }
  }

  @IsTest
  static void guardDoesNotAffectNormalLeads() {
    Lead normal = new Lead(
      LastName = 'Normal',
      Company = 'Normal Co',
      Email = 'normal.' + EnrollmentTestFactory.uniqueSuffix() + '@example.com'
    );
    insert normal;
    // IsConverted is read-only in Apex, so build the "after" version from JSON.
    Lead updated = (Lead) JSON.deserialize(
      '{"attributes":{"type":"Lead"},"Id":"' +
        normal.Id +
        '","IsConverted":true}',
      Lead.class
    );
    EnrollmentLeadTriggerHandler.beforeUpdate(
      new List<Lead>{ updated },
      new Map<Id, Lead>{ normal.Id => normal }
    );
    Assert.isFalse(
      updated.hasErrors(),
      'Leads without an enrollment key are never blocked'
    );
  }
}
