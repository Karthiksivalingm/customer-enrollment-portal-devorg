@isTest
public class roundRobinLeadAssignerTest {
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
    // Create Group
    Group oda_ob_leadAutomation_group = new Group(Name = GROUP_NAME, Type = 'Regular');
    insert oda_ob_leadAutomation_group;

    // Create 2 users
    User user1 = createUser(USER1_FIRSTNAME, USER1_LASTNAME, USER1_STATESLICENSEDIN);
    User user2 = createUser(USER2_FIRSTNAME, USER2_LASTNAME, USER2_STATESLICENSEDIN);

    // Add users to group
    addUserToGroup(user1, oda_ob_leadAutomation_group);
    addUserToGroup(user2, oda_ob_leadAutomation_group);
  }

  @isTest
  static void assign_usersLastAssignDateNull_shouldAssignLeadToAnUser() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());

    List<User> users = getUsers();

    for (User user : users) {
      System.assertEquals(
        null,
        user.Oda_timestamp_last_ob_lead_assigned__c,
        'User Oda_timestamp_last_ob_lead_assigned__c is not null'
      );
    }
    String leadState = 'CA';
    Integer trafficSource = 950;

    Test.startTest();
    Lead lead = createLead(leadState, trafficSource);

    roundRobinLeadAssigner.RoundRobinLeadAssignment rra = createLeadAssignment(lead);
    roundRobinLeadAssigner.assign(new List<roundRobinLeadAssigner.RoundRobinLeadAssignment>{ rra });
    Test.stopTest();

    List<User> updatedUsers = getUpdatedUsers();
    System.assertEquals(1, updatedUsers.size());

    String taskSubject = 'Sage - Hot Lead Assigned, ' + lead.FirstName + ' ' + lead.LastName;
    Task task = [
      SELECT Subject, WhoId, OwnerId, Task_Phone__c
      FROM Task
      WHERE WhoId = :lead.Id AND OwnerId = :updatedUsers[0].Id
    ];
    System.assertNotEquals(null, task, 'No task for user: ' + updatedUsers[0].Id);
    System.assertEquals(taskSubject, task.Subject, 'Invalid task Subject');
    System.assertEquals(lead.Phone, task.Task_Phone__c, 'Invalid task Phone');

    System.assertNotEquals(
      null,
      updatedUsers[0].Oda_timestamp_last_ob_lead_assigned__c,
      'User Oda_timestamp_last_ob_lead_assigned__c not updated'
    );
  }

  @isTest
  static void assign_onlyOneAgentMatchByState_shouldAssignLeadToCorrectUser() {
    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());

    String leadState = 'MA';
    Integer trafficSource = 940;

    User user = [
      SELECT Id, Oda_timestamp_last_ob_lead_assigned__c, StatesLicensedIn__c
      FROM User
      WHERE StatesLicensedIn__c LIKE :'%' + leadState + '%' AND FirstName = :USER1_FIRSTNAME
      LIMIT 1
    ];

    Test.startTest();
    Lead lead = createLead(leadState, trafficSource);
    roundRobinLeadAssigner.RoundRobinLeadAssignment rra = createLeadAssignment(lead);
    roundRobinLeadAssigner.assign(new List<roundRobinLeadAssigner.RoundRobinLeadAssignment>{ rra });
    Test.stopTest();

    String subject = 'Sage - Fresh Lead Assigned, ' + lead.FirstName + ' ' + lead.LastName;

    Task task = [
      SELECT Subject, WhoId, OwnerId, Task_Phone__c
      FROM Task
      WHERE WhoId = :lead.Id AND OwnerId = :user.Id
    ];
    System.assertNotEquals(null, task, 'No task with subject: ' + subject);
    System.assertEquals(subject, task.Subject, 'Invalid task Subject');
    System.assertEquals(lead.Phone, task.Task_Phone__c, 'Invalid task Phone');
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

  private static roundRobinLeadAssigner.RoundRobinLeadAssignment createLeadAssignment(Lead lead) {
    roundRobinLeadAssigner.RoundRobinLeadAssignment leadAssignment = new roundRobinLeadAssigner.RoundRobinLeadAssignment();

    leadAssignment.groupName = GROUP_NAME;
    leadAssignment.leadRecordId = lead.Id;
    leadAssignment.leadState = lead.State;
    leadAssignment.firstName = lead.FirstName;
    leadAssignment.lastName = lead.LastName;
    leadAssignment.trafficSource = integer.valueOf(lead.Traffic_Source__c);
    leadAssignment.phone = lead.Phone;
    return leadAssignment;
  }

  private static void addUserToGroup(User user, Group grp) {
    GroupMember groupMember = new GroupMember(GroupId = grp.Id, UserOrGroupId = user.Id);
    insert groupMember;
  }

  private static List<User> getUsers() {
    return [
      SELECT Id, FirstName, LastName, Oda_timestamp_last_ob_lead_assigned__c, StatesLicensedIn__c
      FROM User
      WHERE LastName = :USER1_LASTNAME OR LastName = :USER2_LASTNAME
    ];
  }

  private static List<User> getUpdatedUsers() {
    return [
      SELECT Id, FirstName, LastName, Oda_timestamp_last_ob_lead_assigned__c, StatesLicensedIn__c
      FROM User
      WHERE
        (LastName = :USER1_LASTNAME
        OR LastName = :USER2_LASTNAME)
        AND Oda_timestamp_last_ob_lead_assigned__c != null
    ];
  }

  private static User createUser(String firstName, String lastName, String statesLicensedIn) {
    String email = firstName + lastName + '@everquote.ai';
    String userName = email + System.currentTimeMillis();

    User user = new User(
      FirstName = firstName,
      LastName = lastName,
      StatesLicensedIn__c = statesLicensedIn,
      Email = email,
      Username = userName,
      CompanyName = 'TEST',
      Title = 'title',
      Alias = 'alias',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      TimeZoneSidKey = 'America/Los_Angeles',
      ProfileId = UserInfo.getProfileId(),
      Oda_timestamp_last_ob_lead_assigned__c = null,
      Odie_Agent_ID__c = Integer.valueof((Math.random() * 10000)),
      ODA_HnF_Weight__c = 50
    );

    insert user;
    return user;
  }
}