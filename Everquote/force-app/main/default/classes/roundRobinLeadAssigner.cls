public with sharing class roundRobinLeadAssigner {
  private static final Integer HOT_LEAD_SOURCE = 950;

  //Define what Process Builder/Flow Builder can reference for the input variables
  public class RoundRobinLeadAssignment {
    @InvocableVariable(required=true label='Group name')
    public String groupName;

    @InvocableVariable(required=true label='Lead RecordId')
    public String leadRecordId;

    @InvocableVariable(required=true label='Lead State')
    public String leadState;

    @InvocableVariable(required=true label='Lead FirstName')
    public String firstName;

    @InvocableVariable(required=true label='Lead LastName')
    public String lastName;

    @InvocableVariable(required=true label='Lead Traffic_Source')
    public Integer trafficSource;

    @InvocableVariable(required=false label='Lead Phone')
    public String phone;
  }

  @InvocableMethod(label='Assign Lead')
  public static void assign(List<RoundRobinLeadAssignment> rrlas) {
    List<Task> taskList = new List<Task>();
    List<Id> usersIdsToUpdate = new List<Id>();
    Map<Id, Id> leadIdOwnerIdMap = new Map<Id, Id>();

    for (RoundRobinLeadAssignment rra : rrlas) {
      List<User> usersByGroupAndState = loadUsersByGroupAndState(rra.groupName, rra.leadState);

      if (usersByGroupAndState.size() == 0) {
        System.debug('No matching user by state: ' + rra.leadState + ' in group: ' + rra.groupName);
        return;
      }

      User userToUpdate = randomExtractUser(usersByGroupAndState);
      if (userToUpdate == null) {
        System.debug('No matching user by ODA_HnF_Weight__c');
        // Assign lead to the advisor that didn't had recently a fresh/hot lead
        userToUpdate = usersByGroupAndState[0];
      }

      leadIdOwnerIdMap.put(rra.leadRecordId, userToUpdate.Id);

      Task newTask = createTask(rra, userToUpdate.Id);
      taskList.add(newTask);
      usersIdsToUpdate.add(userToUpdate.Id);
    }

    if (taskList.size() > 0) {
      insert taskList;
      updateUserOdaTimestampLastObLeadAssigned(usersIdsToUpdate);
      updateLeadsOwner(leadIdOwnerIdMap);
    }
  }

  public static void updateLeadsOwner(Map<Id, Id> leadOwnerMAp) {
    List<Lead> updatedLeads = new List<Lead>();
    List<Lead> leads = [
      SELECT Id, OwnerId, OwnerIsUser__c
      FROM Lead
      WHERE Id IN :leadOwnerMAp.keySet()
    ];

    for (Lead lead : leads) {
      // only update lead owner current owner is not an advisor
      if (lead.OwnerIsUser__c) {
        System.debug(
          'Skip owner update for lead ' +
          lead.Id +
          '. Lead own by user ' +
          lead.OwnerId
        );
        continue;
      }

      lead.OwnerId = leadOwnerMAp.get(lead.Id);
      updatedLeads.add(lead);
    }

    update updatedLeads;
  }

  @Future
  public static void updateUserOdaTimestampLastObLeadAssigned(List<Id> usersId) {
    List<User> users = [
      SELECT Id, StatesLicensedIn__c, Oda_timestamp_last_ob_lead_assigned__c
      FROM User
      WHERE Id IN :usersId
    ];

    for (User user : users) {
      user.Oda_timestamp_last_ob_lead_assigned__c = datetime.now();
    }

    update users;
  }

  public static List<User> loadUsersByGroupAndState(String groupName, String leadState) {
    List<GroupMember> usersByGroup = [
      SELECT Group.Name, GroupId, UserOrGroupId
      FROM GroupMember
      WHERE Group.Name = :groupName
    ];

    List<Id> usersId = new List<Id>();
    for (GroupMember member : usersByGroup) {
      usersId.add(member.UserOrGroupId);
    }

    // load user by StatesLicensedIn__c ordered by Oda_timestamp_last_ob_lead_assigned__c
    String stateLike = '%' + leadState + '%';
    String stateNotLike = '%' + leadState + '*%';
    List<User> usersByGroupAndState = [
      SELECT Id, StatesLicensedIn__c, Oda_timestamp_last_ob_lead_assigned__c, ODA_HnF_Weight__c
      FROM User
      WHERE
        IsActive = true
        AND StatesLicensedIn__c LIKE :stateLike
        AND (NOT StatesLicensedIn__c LIKE :stateNotLike)
        AND Id IN :usersId
      ORDER BY Oda_timestamp_last_ob_lead_assigned__c ASC
    ];

    return usersByGroupAndState;
  }

  public static User randomExtractUser(List<User> users) {
    // advisors weight sum, will be used to calculate probability for each advisor
    Decimal weightSum = getUsersWeightSum(users);

    if (weightSum == 0) {
      // No eligible advisors to receive a HnF lead
      return null;
    }

    List<Integer> userProbabilityList = generateRandomList();

    Integer randomUserValue = (Integer) (Math.random() * 100);

    Integer currentIndex = 0;
    Integer endRange = 0;

    User selectedUser = null;
    for (User user : users) {
      Integer probability = (Integer) Math.ceil(((getUserWeight(user) / weightSum) * 100));
      endRange += probability;

      while (currentIndex < endRange) {
        if (randomUserValue == userProbabilityList[currentIndex]) {
          selectedUser = user;
          break;
        }
        currentIndex += 1;
      }

      if (selectedUser != null) {
        break;
      }
    }

    return selectedUser;
  }

  /**
   * Generate a list of integers from 0 to 100 in a random order
   * 67, 84, 51, 7, 99, 14, 28, 71, 5, 75, ...
   */
  public static List<Integer> generateRandomList() {
    List<Integer> randomList = new List<Integer>();

    while (randomList.size() < 100) {
      Integer newItem = (Integer) (Math.random() * 100);

      if (!randomList.contains(newItem)) {
        randomList.add(newItem);
      }
    }

    return randomList;
  }

  public static Decimal getUserWeight(User user) {
    return user.ODA_HnF_Weight__c != null ? user.ODA_HnF_Weight__c : 0;
  }

  public static Decimal getUsersWeightSum(List<User> users) {
    Decimal weightSum = 0;
    for (User user : users) {
      weightSum += getUserWeight(user);
    }
    return weightSum;
  }

  public static Task createTask(RoundRobinLeadAssignment leadAssignment, String ownerId) {
    String subject = HOT_LEAD_SOURCE == leadAssignment.trafficSource
      ? 'Sage - Hot Lead Assigned, '
      : 'Sage - Fresh Lead Assigned, ';
    subject = subject + leadAssignment.firstName + ' ' + leadAssignment.lastName;

    return new Task(
      WhoId = leadAssignment.leadRecordId,
      Subject = subject,
      ActivityDate = Date.today(),
      OwnerId = ownerId,
      Priority = 'High',
      Task_Phone__c = leadAssignment.phone
    );
  }
}