/*
 * LifeLeadCreatedTest.cls
 *
 * Tests LifeLeadCreatedTest trigger functionality
 *
 * Created By:      Daniel Voicu (dvoicu@everquote.com)
 * Created Date:    Jul 10, 2020
 */
@isTest
public class LifeLeadCreatedTest {
  // 'Unique' fields for inserting test records
  private static final String LEAD_LASTNAME = 'Test Lead';

  @isTest
  static void insertLifeLead_existingEqLeadUuid_Test() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());

    String eqLeadUuid = '7906b4f1-74ff-5ed8-a004-fbe6a3fff306';

    Lead lead = createLead();
    lead.EqLeadUuid__c = eqLeadUuid;

    insert lead;

    lead = getTestLead();
    System.assertEquals(eqLeadUuid, lead.EqLeadUuid__c, 'Lead EqLeadUuid__c not equal');
  }

  @isTest
  static void insertLifeLead_nullEqLeadUuid_Test() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());

    Lead lead = createLead();
    insert lead;

    lead = getTestLead();
    System.assertEquals(null, lead.EqLeadUuid__c, 'Lead EqLeadUuid__c not equal');
  }

  // Helper method to query our test lead
  private static Lead getTestLead() {
    return [SELECT Id, OwnerId, EqLeadUuid__c FROM Lead WHERE LastName = :LEAD_LASTNAME LIMIT 1];
  }

  private static Lead createLead() {
    Lead lead = new Lead(
      LastName = LEAD_LASTNAME,
      Phone = '+12112688222',
      RecordTypeId = '0121a000000VlZ7AAK'
    );

    return lead;
  }
}