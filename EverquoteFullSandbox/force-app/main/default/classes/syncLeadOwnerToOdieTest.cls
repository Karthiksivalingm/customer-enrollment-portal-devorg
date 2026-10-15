@isTest
public class syncLeadOwnerToOdieTest {
  // 'Unique' fields for inserting test records
  private static final String GROUP_NAME = 'ODA_OB_LeadAutomation_Test';
  private static final String USER1_FIRSTNAME = 'Test001';
  private static final String USER1_LASTNAME = 'User001';
  private static final String USER1_STATESLICENSEDIN = 'CA, MA';

  private static final String USER2_FIRSTNAME = 'Test001';
  private static final String USER2_LASTNAME = 'User002';
  private static final String USER2_STATESLICENSEDIN = 'CA';

  @testSetup
  static void testSetup() {
    // // Create Group
    // Group oda_ob_leadAutomation_group = new Group(Name = GROUP_NAME, Type = 'Regular');
    // insert oda_ob_leadAutomation_group;

    // // Create 2 users
    // User user1 = createUser(USER1_FIRSTNAME, USER1_LASTNAME, USER1_STATESLICENSEDIN);
    // User user2 = createUser(USER2_FIRSTNAME, USER2_LASTNAME, USER2_STATESLICENSEDIN);

    // // Add users to group
    // addUserToGroup(user1, oda_ob_leadAutomation_group);
    // addUserToGroup(user2, oda_ob_leadAutomation_group);
  }

  @isTest
  static void assign_usersLastAssignDateNull_shouldAssignLeadToAnUser() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());

    String leadState = 'CA';
    Integer trafficSource = 950;

    Test.startTest();
    Lead lead = createLead(leadState, trafficSource);

    syncLeadOwnerToOdie.LeadToSync leadToSync = new syncLeadOwnerToOdie.LeadToSync();
    leadToSync.leadRecordId = lead.Id;

    syncLeadOwnerToOdie.sync(new List<syncLeadOwnerToOdie.LeadToSync>{ leadToSync });

    Test.stopTest();
  }

  private static Lead createLead(String state, Integer trafficSource) {
    String lastName = 'Test' + System.currentTimeMillis();
    Lead lead = new Lead(
      FirstName = 'Lead',
      LastName = lastName,
      State = state,
      Phone = '+13017000000',
      Traffic_Source__c = trafficSource
    );
    insert lead;
    return lead;
  }
}