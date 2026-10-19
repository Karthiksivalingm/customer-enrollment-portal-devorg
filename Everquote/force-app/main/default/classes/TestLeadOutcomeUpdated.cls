/*
 * TestLeadOutcomeUpdated.cls
 *
 * Tests LeadOutcomeUpdated trigger functionality
 *
 * Created By:      Daniel Voicu (dvoicu@everquote.com)
 * Created Date:    Jun 10, 2020
 */
@isTest
public class TestLeadOutcomeUpdated {
  // 'Unique' fields for inserting test records
  private static final String LEAD_LASTNAME = 'Test Lead';
  private static final String LEAD_PHONE = '+12112688222';

  @testSetup
  static void testSetup() {
    Lead lead = new Lead(LastName = LEAD_LASTNAME, Phone = LEAD_PHONE, Lead_Outcome__c='Initial Lead Outcome');
    insert lead;
  }

  @isTest
  static void updateLeadOutcomeTest() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());
    
    Lead lead = getTestLead();

    lead.Lead_Outcome__c = 'Do Not Call';
    updateLead(lead);

    lead = getTestLead();
    System.assertEquals('Do Not Call', lead.Lead_Outcome__c, 'Lead Outcome not updated');
  }

  // Helper method to query our test lead
  private static Lead getTestLead() {
    return [SELECT Id, Lead_Outcome__c FROM Lead WHERE LastName = :LEAD_LASTNAME LIMIT 1];
  }

  // Helper method update  lead
  private static void updateLead(Lead lead) {
    // Insert the record (Fires our trigger)
    Test.startTest();
    update lead;
    Test.stopTest();
  }
}