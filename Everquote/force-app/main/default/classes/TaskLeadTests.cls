/*
 * TaskLeadTests.cls
 * - Tests TaskLead trigger functionality
 *
 * Created By:      Daniel Bailey (dbailey@opfocus.com)
 * Created Date:    Dec 9, 2019
 *
 * Updated By:      Daniel Voicu (dvoicu@everquote.com)
 * Updated Date:    Apr 10, 2020
 */
@isTest
public class TaskLeadTests {
  // 'Unique' fields for inserting test records
  private static final String LEAD_LASTNAME = 'Test Lead';
  private static final String USER_EMAIL = 'TaskLeadTriggerTestUser@everquote.ai';
  private static final Id PONG_DEVELOPER_ID = '0051a000002j8TUAAY';
  private static final Id INBOUND_LIFE_QUEUE_ID = '00G2g000000HbBiEAK';
  private static final Id DUMMY_QUEUE_ID = '00G1a000001WCo7EAG';

  // Default prefix for User object
  private static final String USER_PREFIX = '005';

  @testSetup
  static void testSetup() {
    // Create our test user with a Standard User profile
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];

    // Create a test user who will assume ownership of the lead after task insertion
    User testUser = new User(
      Alias = 'TLTTU',
      Email = USER_EMAIL,
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LastName = 'Testing',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/New_York',
      Username = USER_EMAIL,
      Odie_Agent_ID__c = Integer.valueof((Math.random() * 10000))
    );

    // Insert our new test user
    insert testUser;
  }

  // Ensures the trigger does not update Lead owner to match Task owner if already owned by an user(agent)
  @isTest
  static void taskLeadTrigger_ownerAgentNotPongDev_shouldNotUpdateOwnerTest() {
    // Pull in the new data
    insertLead(null);
    User testUser = getTestUser();
    Lead testLead = getTestLead();

    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock(200));

    // Initially verify that the lead is not owned by our test user
    System.assertNotEquals(
      testUser.Id,
      testLead.OwnerId,
      'Lead should not be owned by our test User yet'
    );
    Id testLeadInitialOwnerId = testLead.OwnerId;

    // Verify that the lead is owned by a user
    System.assertEquals(USER_PREFIX, ((String) testLeadInitialOwnerId).substring(0, 3));

    // Create the test task with our data
    Task testTask = new Task(CallType = 'Inbound', WhoId = testLead.Id, OwnerId = testUser.Id);

    // Insert the record (Fires our trigger)
    Test.startTest();
    insert testTask;
    Test.stopTest();

    // Re-query our lead and verify that it is still owned by initial agent
    testLead = getTestLead();
    System.assertEquals(
      testLeadInitialOwnerId,
      testLead.OwnerId,
      'Lead owner should not be changed if it is already owned by a user!'
    );
  }

  // Ensures the trigger update Lead owner to match Task owner if owned by Pong Developer agent
  @isTest
  static void taskLeadTrigger_ownerPongDev_shouldUpdateLeadOwnerTest() {
    insertLead(PONG_DEVELOPER_ID);

    // Pull in the new data
    User testUser = getTestUser();
    Lead testLead = getTestLead();

    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock(200));

    // Verify that the lead is owned by Pong Develoer
    System.assertEquals(
      PONG_DEVELOPER_ID,
      testLead.OwnerId,
      'Invalid setup: Lead should owned by Pong Developer'
    );

    // Create the test task with our data
    Task testTask = new Task(CallType = 'Inbound', WhoId = testLead.Id, OwnerId = testUser.Id);

    // Insert the record (Fires our trigger)
    Test.startTest();
    insert testTask;
    Test.stopTest();

    // Re-query our lead and verify that it is owned by an agent
    testLead = getTestLead();
    System.assertNotEquals(
      testUser.Id,
      testLead.OwnerId,
      'Lead owner should be changed if a Lead is owned by Pong Developer and an agent takes a new task on that lead!'
    );
  }

  // Ensures the trigger does not update Lead owner if owned by a different queue
  @isTest
  static void taskLeadTrigger_leadNotOwnedByILQ_shouldNotUpdateLeadOwnerTest() {
    insertLead(DUMMY_QUEUE_ID);

    // Pull in the new data
    User testUser = getTestUser();
    Lead testLead = getTestLead();

    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock(200));

    // Verify that the lead is owned by Pong Develoer
    System.assertEquals(
      DUMMY_QUEUE_ID,
      testLead.OwnerId,
      'Invalid setup: Lead should owned by Dummy Queue'
    );

    // Create the test task with our data
    Task testTask = new Task(CallType = 'Inbound', WhoId = testLead.Id, OwnerId = testUser.Id);

    // Insert the record (Fires our trigger)
    Test.startTest();
    insert testTask;
    Test.stopTest();

    // Re-query our lead and verify that it is owned by dummy queue
    testLead = getTestLead();
    System.assertEquals(
      DUMMY_QUEUE_ID,
      testLead.OwnerId,
      'Lead owner should not be changed if a Lead is owned by a different queue (not Inbound Life Queue) and an agent takes a new task on that lead!'
    );
  }

  // Ensures the trigger does update Lead owner if owned by Inbound Life Queue
  // @isTest
  // static void taskLeadTrigger_leadOwnedByILQ_shouldUpdateLeadOwnerTest() {
  //   insertLead(INBOUND_LIFE_QUEUE_ID);

  //   // Pull in the new data
  //   User testUser = getTestUser();
  //   Lead testLead = getTestLead();

  //   Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock(200));

  //   // Verify that the lead is owned by Pong Develoer
  //   System.assertEquals(
  //     INBOUND_LIFE_QUEUE_ID,
  //     testLead.OwnerId,
  //     'Invalid setup: Lead should owned by Inbound Life Queue'
  //   );

  //   // Create the test task with our data
  //   Task testTask = new Task(CallType = 'Inbound', WhoId = testLead.Id, OwnerId = testUser.Id);

  //   // Insert the record (Fires our trigger)
  //   Test.startTest();
  //   insert testTask;
  //   Test.stopTest();

  //   // Re-query our lead and verify that it is owned by dummy queue
  //   testLead = getTestLead();
  //   System.assertEquals(
  //     testUser.Id,
  //     testLead.OwnerId,
  //     'Lead owner should be changed if a Lead is owned by Inbound Life Queue and an agent takes a new task on that lead!'
  //   );
  // }

  // Attempt update with different call type
  @isTest
  static void taskLeadTrigger_nonInboundCallType_shouldNotUpdateOwnerTest() {
    insertLead(null);

    // Pull in the new data
    User testUser = getTestUser();
    Lead testLead = getTestLead();

    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock(200));

    // Create the test task with our data and 'Internal' call type
    Task testTask = new Task(CallType = 'Internal', WhoId = testLead.Id, OwnerId = testUser.Id);

    // Insert the record (Fires our trigger)
    Test.startTest();
    insert testTask;
    Test.stopTest();

    // Re-query our lead and verify that it is still not owned by our task owner
    testLead = getTestLead();
    System.assertNotEquals(
      testUser.Id,
      testLead.OwnerId,
      'Lead should not be owned by our new test user!'
    );
  }

  // Attempt update without a Lead lookup
  @isTest
  static void taskLeadTrigger_invalidWhoId_shouldNotUpdateOwnerTest() {
    insertLead(null);

    // Pull in the new user data
    User testUser = getTestUser();

    Test.setMock(HttpCalloutMock.class, new OdieRequestCalloutMock());

    // Create the test task with our data
    Task testTask = new Task(CallType = 'Inbound', OwnerId = testUser.Id);

    // Insert the record (Fires our trigger)
    Test.startTest();
    insert testTask;
    Test.stopTest();

    // Re-query our lead and verify that it is still not owned by our task owner
    Lead testLead = getTestLead();
    System.assertNotEquals(
      testUser.Id,
      testLead.OwnerId,
      'Lead should not be owned by our new test user!'
    );
  }

  // Helper method to query our test lead
  private static Lead getTestLead() {
    return [SELECT Id, OwnerId FROM Lead WHERE LastName = :LEAD_LASTNAME LIMIT 1];
  }

  // Helper method to query our test user
  private static User getTestUser() {
    return [SELECT Id FROM User WHERE Username = :USER_EMAIL LIMIT 1];
  }

  // Helper method to insert a lead
  private static void insertLead(Id ownerId) {
    // Create a lead to associated tasks to
    Lead testLead = new Lead(LastName = LEAD_LASTNAME);
    if (ownerId != null) {
      testLead.OwnerId = ownerId;
    }
    insert testLead;
  }
}