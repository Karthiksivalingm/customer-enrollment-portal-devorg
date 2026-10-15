/*
 * LeadOwnerUpdatedTest.cls
 *
 * Tests LeadOwnerUpdated trigger functionality
 *
 * Created By:      Daniel Voicu (dvoicu@everquote.com)
 * Created Date:    Jun 30, 2020
 */
@isTest
public class LeadOwnerUpdatedTest {
  // 'Unique' fields for inserting test records
  private static final String LEAD_LASTNAME = 'Test Lead';
  private static final String OLD_OWNER_EMAIL = 'oldOwner@everquote.ai';
  private static final String NEW_OWNER_EMAIL = 'newOwner1@everquote.ai';

  @testSetup
  static void testSetup() {
    User oldOwner = createTestUser(OLD_OWNER_EMAIL);
    createTestUser(NEW_OWNER_EMAIL);

    Lead lead = new Lead(LastName = LEAD_LASTNAME, Phone = '+12112688222', OwnerId = oldOwner.Id);
    insert lead;
  }

  @isTest
  static void updateLeadOwnerTest_nullEqLeadUuid() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());

    Lead lead = getTestLead();
    User newOwner = getTestUser(NEW_OWNER_EMAIL);
    lead.OwnerId = newOwner.Id;

    updateLead(lead);

    lead = getTestLead();
    System.assertEquals(newOwner.Id, lead.OwnerId, 'Lead Owner not updated');
  }

  @isTest
  static void updateLeadOwnerTest_existingEqLeadUuid() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());

    Lead lead = getTestLead();
    User newOwner = getTestUser(NEW_OWNER_EMAIL);
    lead.EqLeadUuid__c = '7906b4f1-74ff-5ed8-a004-fbe6a3fff306';
    lead.OwnerId = newOwner.Id;

    updateLead(lead);

    lead = getTestLead();
    System.assertEquals(newOwner.Id, lead.OwnerId, 'Lead Owner not updated');
  }

  // Helper method to query our test lead
  private static Lead getTestLead() {
    return [SELECT Id, OwnerId, EqLeadUuid__c FROM Lead WHERE LastName = :LEAD_LASTNAME LIMIT 1];
  }

  // Helper method to query our test users
  private static User getTestUser(String email) {
    return [SELECT Id, Email FROM User WHERE Email = :email LIMIT 1];
  }

  // Helper method update  lead
  private static void updateLead(Lead lead) {
    // Insert the record (Fires our trigger)
    Test.startTest();
    update lead;
    Test.stopTest();
  }

  private static User createTestUser(String email) {
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
    String lastName = 'Testing ' + System.currentTimeMillis();
    User user = new User(
      Alias = 'TLTTU',
      Email = email,
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LastName = lastName,
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/New_York',
      Username = email,
      Odie_Agent_ID__c = Integer.valueof((Math.random() * 10000))
    );

    insert user;

    return user;
  }
}