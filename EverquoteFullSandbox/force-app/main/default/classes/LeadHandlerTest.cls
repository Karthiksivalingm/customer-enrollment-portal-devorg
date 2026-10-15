/*
 * LeadHandlerTest.cls
 *
 * Covers LeadHandler.cls / LeadTrigger.trigger: every before/after insert and
 * update branch, plus the Lead validation rules and required fields that
 * gate those branches (Lead_must_have_either_Phone_or_Email,
 * First_Name_Required, Phone_required_on_conversion,
 * If_status_is_contacted_carrier_required, and the standard LastName
 * required field).
 *
 * Note: several legacy Lead triggers (UpdateLeadMobilePhone, LeadOwnerUpdated,
 * LeadOutcomeUpdated, LifeLeadCreated, UpdateReferral, etcd8_LeadTrigger) are
 * still active alongside LeadTrigger and duplicate parts of this logic.
 * Assertions below check observable outcomes (field values / callouts made)
 * rather than which specific trigger produced them, since Salesforce does
 * not guarantee execution order between multiple triggers on the same object.
 */
@isTest
private class LeadHandlerTest {
  private static final Id LIFE_RECORD_TYPE_ID = '0121a000000VlZ7AAK';
  private static final String LEAD_PHONE = '+12112688222';
  private static final String LEAD_PHONE_2 = '+12112688223';
  private static final String STD_USER_LASTNAME = 'LeadHandlerTestStdUser';

  @testSetup
  static void setup() {
    Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    User standardUser = new User(
      Alias = 'lhtstd',
      Email = 'lead.handler.std.user@everquote.ai',
      EmailEncodingKey = 'UTF-8',
      LastName = STD_USER_LASTNAME,
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = standardProfile.Id,
      TimeZoneSidKey = 'America/New_York',
      Username = 'lead.handler.std.user' + System.currentTimeMillis() + '@everquote.ai',
      Odie_Agent_ID__c = Integer.valueOf(Math.random() * 1000000)
    );
    insert standardUser;
  }

  private static User getStandardUser() {
    return [SELECT Id FROM User WHERE LastName = :STD_USER_LASTNAME LIMIT 1];
  }

  private static Carrier__c createCarrier() {
    Carrier__c carrier = new Carrier__c(Name = 'LeadHandlerTest Carrier');
    insert carrier;
    return carrier;
  }

  private static String getConvertedStatusApiName() {
    LeadStatus convertedStatus = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
    return convertedStatus.MasterLabel;
  }

  // ==================== beforeInsert ====================

  @isTest
  static void beforeInsert_webScrapeSource_setsScoreWhenBlank() {
    Lead lead = new Lead(
      FirstName = 'Test',
      LastName = 'WebScrapeLead',
      Company = 'Test Co',
      Phone = LEAD_PHONE,
      LeadSource = 'Web Scrape'
    );

    insert lead;

    Lead inserted = [SELECT Phone, MobilePhone, mkto71_Lead_Score__c FROM Lead WHERE Id = :lead.Id];
    System.assertEquals(inserted.Phone, inserted.MobilePhone, 'MobilePhone should mirror Phone after insert');

    Trigger_Setting__mdt setting = Trigger_Setting__mdt.getInstance('LeadBeforeInsert');
    Boolean isActive = setting != null && setting.Is_Active__c;
    if (isActive) {
      System.assertEquals(90, inserted.mkto71_Lead_Score__c, 'Web Scrape leads should default to a score of 90 when the setting is active');
    } else {
      System.assertEquals(null, inserted.mkto71_Lead_Score__c, 'Lead score should stay untouched while the LeadBeforeInsert setting is inactive');
    }
  }

  @isTest
  static void beforeInsert_webScrapeSource_doesNotOverwriteExistingScore() {
    Lead lead = new Lead(
      FirstName = 'Test',
      LastName = 'WebScrapeLeadScored',
      Company = 'Test Co',
      Phone = LEAD_PHONE,
      LeadSource = 'Web Scrape',
      mkto71_Lead_Score__c = 55
    );

    insert lead;

    Lead inserted = [SELECT mkto71_Lead_Score__c FROM Lead WHERE Id = :lead.Id];
    System.assertEquals(55, inserted.mkto71_Lead_Score__c, 'An existing lead score should never be overwritten');
  }

  @isTest
  static void beforeInsert_nonWebScrapeSource_leavesScoreBlank() {
    Lead lead = new Lead(
      FirstName = 'Test',
      LastName = 'OtherSourceLead',
      Company = 'Test Co',
      Phone = LEAD_PHONE,
      LeadSource = 'Other'
    );

    insert lead;

    Lead inserted = [SELECT mkto71_Lead_Score__c, MobilePhone FROM Lead WHERE Id = :lead.Id];
    System.assertEquals(null, inserted.mkto71_Lead_Score__c, 'Non Web Scrape leads should not receive a default score');
    System.assertEquals(LEAD_PHONE, inserted.MobilePhone, 'MobilePhone should mirror Phone regardless of lead source');
  }

  @isTest
  static void beforeInsert_missingLastName_throwsRequiredFieldError() {
    Lead lead = new Lead(FirstName = 'Test', Company = 'Test Co', Phone = LEAD_PHONE);

    try {
      insert lead;
      System.assert(false, 'Insert should have failed because LastName is a required field');
    } catch (DmlException e) {
      System.assert(
        e.getMessage().contains('LastName') || e.getMessage().toLowerCase().contains('required'),
        'Expected a required field error for LastName, got: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void beforeInsert_missingPhoneAndEmail_throwsValidationError() {
    System.runAs(getStandardUser()) {
      Lead lead = new Lead(FirstName = 'Test', LastName = 'NoContactInfo', Company = 'Test Co');

      try {
        insert lead;
        System.assert(false, 'Insert should have failed the Lead_must_have_either_Phone_or_Email validation rule');
      } catch (DmlException e) {
        System.assert(
          e.getMessage().contains('Phone Number or Email is required'),
          'Expected the phone/email validation error, got: ' + e.getMessage()
        );
      }
    }
  }

  @isTest
  static void beforeInsert_missingFirstName_throwsValidationError() {
    System.runAs(getStandardUser()) {
      Lead lead = new Lead(LastName = 'NoFirstName', Company = 'Test Co', Phone = LEAD_PHONE);

      try {
        insert lead;
        System.assert(false, 'Insert should have failed the First_Name_Required validation rule');
      } catch (DmlException e) {
        System.assert(
          e.getMessage().contains('First Name Required'),
          'Expected the first name validation error, got: ' + e.getMessage()
        );
      }
    }
  }

  // ==================== beforeUpdate ====================

  @isTest
  static void beforeUpdate_phoneChange_updatesMobilePhone() {
    Lead lead = new Lead(FirstName = 'Test', LastName = 'PhoneSync', Company = 'Test Co', Phone = LEAD_PHONE);
    insert lead;

    checkTriggerRecursion.reset();

    lead.Phone = LEAD_PHONE_2;
    update lead;

    Lead updated = [SELECT MobilePhone FROM Lead WHERE Id = :lead.Id];
    System.assertEquals(LEAD_PHONE_2, updated.MobilePhone, 'MobilePhone should be re-synced when Phone changes');
  }

  @isTest
  static void beforeUpdate_statusLost_clearsCallFields() {
    Lead lead = new Lead(
      FirstName = 'Test',
      LastName = 'LostLead',
      Company = 'Test Co',
      Phone = LEAD_PHONE,
      GateKeeperCallCount__c = 5,
      DMCallCount__c = 3,
      LastCallDispo__c = 'No Answer'
    );
    insert lead;

    checkTriggerRecursion.reset();

    lead.Status = 'Lost';
    update lead;

    Lead updated = [
      SELECT GateKeeperCallCount__c, DMCallCount__c, LastCallDispo__c
      FROM Lead
      WHERE Id = :lead.Id
    ];
    System.assertEquals(null, updated.GateKeeperCallCount__c, 'GateKeeperCallCount__c should be cleared when Status is Lost');
    System.assertEquals(null, updated.DMCallCount__c, 'DMCallCount__c should be cleared when Status is Lost');
    System.assertEquals(null, updated.LastCallDispo__c, 'LastCallDispo__c should be cleared when Status is Lost');
  }

  @isTest
  static void beforeUpdate_removingPhoneAndEmail_throwsValidationError() {
    System.runAs(getStandardUser()) {
      Lead lead = new Lead(FirstName = 'Test', LastName = 'RemoveContactInfo', Company = 'Test Co', Phone = LEAD_PHONE);
      insert lead;

      checkTriggerRecursion.reset();

      lead.Phone = null;

      try {
        update lead;
        System.assert(false, 'Update should have failed the Lead_must_have_either_Phone_or_Email validation rule');
      } catch (DmlException e) {
        System.assert(
          e.getMessage().contains('Phone Number or Email is required'),
          'Expected the phone/email validation error, got: ' + e.getMessage()
        );
      }
    }
  }

  // ==================== afterInsert ====================

  @isTest
  static void afterInsert_lifeLeadWithExistingUuid_syncsOwnerToOdie() {
    OdieRequestCalloutMock mock = new OdieRequestCalloutMock();
    Test.setMock(HttpCalloutMock.class, mock);

    Lead lead = new Lead(
      FirstName = 'Test',
      LastName = 'LifeLeadExistingUuid',
      Company = 'Test Co',
      Phone = LEAD_PHONE,
      RecordTypeId = LIFE_RECORD_TYPE_ID,
      EqLeadUuid__c = '7906b4f1-74ff-5ed8-a004-fbe6a3fff306'
    );

    Test.startTest();
    insert lead;
    Test.stopTest();

    System.assert(
      mock.urlsRequestBody.containsKey('forms/update_owner'),
      'Owner sync callout should have been made for a Life Lead that already has an EqLeadUuid'
    );

    Lead inserted = [SELECT EqLeadUuid__c FROM Lead WHERE Id = :lead.Id];
    System.assertEquals('7906b4f1-74ff-5ed8-a004-fbe6a3fff306', inserted.EqLeadUuid__c, 'EqLeadUuid__c should be unchanged');
  }

  @isTest
  static void afterInsert_lifeLeadWithoutUuid_createsOdieRecord() {
    OdieRequestCalloutMock mock = new OdieRequestCalloutMock();
    Test.setMock(HttpCalloutMock.class, mock);

    Lead lead = new Lead(
      FirstName = 'Test',
      LastName = 'LifeLeadNoUuid',
      Company = 'Test Co',
      Phone = LEAD_PHONE,
      RecordTypeId = LIFE_RECORD_TYPE_ID
    );

    Test.startTest();
    insert lead;
    Test.stopTest();

    System.assert(
      mock.urlsRequestBody.containsKey('forms'),
      'A new Odie form should have been created for a Life Lead without an EqLeadUuid'
    );

    Lead inserted = [SELECT EqLeadUuid__c FROM Lead WHERE Id = :lead.Id];
    System.assertEquals(null, inserted.EqLeadUuid__c, 'EqLeadUuid__c should remain null since the mock response has no eq_lead_uuid');
  }

  @isTest
  static void afterInsert_nonLifeLead_doesNotAttemptOdieSync() {
    // No HttpCalloutMock is registered on purpose: if the Life Lead-only guard
    // were broken, any enqueued callout would throw and fail this test.
    Lead lead = new Lead(FirstName = 'Test', LastName = 'DefaultLead', Company = 'Test Co', Phone = LEAD_PHONE);

    Test.startTest();
    insert lead;
    Test.stopTest();

    System.assertNotEquals(null, lead.Id, 'A non Life Lead should insert cleanly without attempting an Odie callout');
  }

  // ==================== afterUpdate ====================

  @isTest
  static void afterUpdate_ownerChangeWithUuid_syncsOwnerToOdie() {
    Lead lead = new Lead(
      FirstName = 'Test',
      LastName = 'OwnerChangeLead',
      Company = 'Test Co',
      Phone = LEAD_PHONE,
      EqLeadUuid__c = '7906b4f1-74ff-5ed8-a004-fbe6a3fff307'
    );
    insert lead;

    User newOwner = getStandardUser();

    OdieRequestCalloutMock mock = new OdieRequestCalloutMock();
    Test.setMock(HttpCalloutMock.class, mock);
    checkTriggerRecursion.reset();

    Test.startTest();
    lead.OwnerId = newOwner.Id;
    update lead;
    Test.stopTest();

    System.assert(
      mock.urlsRequestBody.containsKey('forms/update_owner'),
      'Changing the owner of a lead with an EqLeadUuid should sync the new owner to Odie'
    );
  }

  @isTest
  static void afterUpdate_outcomeChange_syncsDispositionToOdie() {
    Lead lead = new Lead(
      FirstName = 'Test',
      LastName = 'OutcomeChangeLead',
      Company = 'Test Co',
      Phone = LEAD_PHONE,
      Lead_Outcome__c = 'None'
    );
    insert lead;

    OdieRequestCalloutMock mock = new OdieRequestCalloutMock();
    Test.setMock(HttpCalloutMock.class, mock);
    checkTriggerRecursion.reset();

    Test.startTest();
    lead.Lead_Outcome__c = 'Do Not Call';
    update lead;
    Test.stopTest();

    System.assert(
      mock.urlsRequestBody.containsKey('forms/update_sales_disposition'),
      'Changing Lead_Outcome__c should sync the disposition to Odie'
    );
  }

  @isTest
  static void afterUpdate_convertedLead_updatesLinkedReferral() {
    Lead referredLead = new Lead(
      FirstName = 'Test',
      LastName = 'ReferredLead',
      Company = 'Test Co',
      Phone = LEAD_PHONE,
      Carrier__c = createCarrier().Id
    );
    insert referredLead;

    Referral__c referral = new Referral__c(Referral__c = referredLead.Id);
    insert referral;

    Database.LeadConvert lc = new Database.LeadConvert();
    lc.setLeadId(referredLead.Id);
    lc.setConvertedStatus(getConvertedStatusApiName());
    lc.setDoNotCreateOpportunity(true);

    checkTriggerRecursion.reset();

    Test.startTest();
    Database.LeadConvertResult result = Database.convertLead(lc);
    Test.stopTest();

    System.assert(result.isSuccess(), 'Lead conversion should succeed when Phone and Carrier are populated');

    Referral__c updatedReferral = [
      SELECT Referral_Account__c, Referral_Contact__c
      FROM Referral__c
      WHERE Id = :referral.Id
    ];
    System.assertEquals(result.getAccountId(), updatedReferral.Referral_Account__c, 'Referral_Account__c should be synced from the converted lead');
    System.assertEquals(result.getContactId(), updatedReferral.Referral_Contact__c, 'Referral_Contact__c should be synced from the converted lead');
  }

  @isTest
  static void afterUpdate_convertingWithoutPhone_throwsValidationError() {
    Lead lead = new Lead(
      FirstName = 'Test',
      LastName = 'NoPhoneConvert',
      Company = 'Test Co',
      Email = 'nophoneconvert@everquote.ai'
    );
    insert lead;

    Database.LeadConvert lc = new Database.LeadConvert();
    lc.setLeadId(lead.Id);
    lc.setConvertedStatus(getConvertedStatusApiName());
    lc.setDoNotCreateOpportunity(true);

    try {
      Database.convertLead(lc);
      System.assert(false, 'Conversion should have failed the Phone_required_on_conversion validation rule');
    } catch (DmlException e) {
    
    }
  }

  @isTest
  static void afterUpdate_convertingWithoutCarrier_throwsValidationError() {
    Lead lead = new Lead(FirstName = 'Test', LastName = 'NoCarrierConvert', Company = 'Test Co', Phone = LEAD_PHONE);
    insert lead;

    Database.LeadConvert lc = new Database.LeadConvert();
    lc.setLeadId(lead.Id);
    lc.setConvertedStatus(getConvertedStatusApiName());
    lc.setDoNotCreateOpportunity(true);

    try {
      Database.convertLead(lc);
      System.assert(false, 'Conversion should have failed the If_status_is_contacted_carrier_required validation rule');
    } catch (DmlException e) {
      System.assert(
        e.getMessage().contains('Carrier and affiliation information is required'),
        'Expected the carrier-required-on-conversion error, got: ' + e.getMessage()
      );
    }
  }
}