/*
 * TestUpdateLeadMobilePhone.cls
 *
 * Tests UpdateLeadMobilePhone trigger functionality
 *
 * Created By:      Daniel Voicu (dvoicu@everquote.com)
 * Created Date:    Apr 15, 2020
 */
@isTest
public class TestUpdateLeadMobilePhone {
  // 'Unique' fields for inserting test records
  private static final String LEAD_LASTNAME = 'Test Lead';

  private static final String LEAD_PHONE = '+12112688222';
  private static final String LEAD_PHONE_NEW = '+12112688223';

  @testSetup
  static void testSetup() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock(200));
  }

  // MobilePhone field value should be set to Phone field value after lead is created
  @isTest
  static void insertNewLeadTest() {
    Lead testLead = new Lead(LastName = LEAD_LASTNAME, Phone = LEAD_PHONE);

    // Insert the record (Fires our trigger)
    insertLead(testLead);

    // Re-query our lead and verify mobile phone value
    testLead = getTestLead();
    System.assertEquals(
      LEAD_PHONE,
      testLead.MobilePhone,
      'MobilePhone field value should be set to Phone field value after a lead is created!'
    );
  }

  // MobilePhone field value should be set to Phone field value after a lead is updated
  @isTest
  static void updateLeadTest() {
    Lead testLead = new Lead(LastName = LEAD_LASTNAME, Phone = LEAD_PHONE);

    insert testLead;

    // reset recursive check
    checkTriggerRecursion.reset();

    // Re-query our lead and update the phone number
    testLead = getTestLead();
    testLead.Phone = LEAD_PHONE_NEW;

    updateLead(testLead);

    // Re-query our lead and verify that it is still not owned by our task owner
    testLead = getTestLead();

    System.assertEquals(
      LEAD_PHONE_NEW,
      testLead.MobilePhone,
      'Lead mobile phone should be equal with phone field after the lead is updated!'
    );
  }

  // Helper method to query our test lead
  private static Lead getTestLead() {
    return [SELECT Id, MobilePhone FROM Lead WHERE LastName = :LEAD_LASTNAME LIMIT 1];
  }

  // Helper method insert a new lead
  private static void insertLead(Lead lead) {
    // Insert the record (Fires our trigger)
    Test.startTest();
    insert lead;
    Test.stopTest();
  }

  // Helper method update  lead
  private static void updateLead(Lead lead) {
    // Insert the record (Fires our trigger)
    Test.startTest();
    update lead;
    Test.stopTest();
  }
}