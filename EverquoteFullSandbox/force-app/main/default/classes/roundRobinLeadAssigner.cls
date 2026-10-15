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

 
  // * Generate a list of integers from 0 to 100 in a random order
  // * 67, 84, 51, 7, 99, 14, 28, 71, 5, 75, ...
    //
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


/** United Techno code
 * Invocable class that performs Round Robin (weighted-random) assignment of Leads
 * to eligible advisors within a Public Group, based on the Lead's State and each
 * advisor's licensing/weighting fields.
 *
 * Refactored to follow Salesforce Apex best practices while preserving the exact
 * business logic of the original implementation (see commented-out block above):
 *  - Bulkified SOQL: the eligible-advisor lookup is cached per Group/State
 *    combination so it only runs once per unique combination instead of once
 *    per Lead in the invocable batch (avoids SOQL-in-a-loop).
 *  - Guard clauses skip SOQL/DML entirely when there is no work to do.
 *  - Centralized exception handling via a dedicated exception type, with the
 *    original error paths preserved (including the early-return behavior when
 *    no eligible advisor is found for a Lead's state/group).
 *  - ApexDoc comments added for maintainability.
 *
 * All public method signatures, the inner RoundRobinLeadAssignment class and its
 * fields remain unchanged from the original implementation so existing Flow /
 * Process Builder definitions and any Apex callers continue to work unmodified.
 */
/*
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

 
  public class RoundRobinLeadAssignerException extends Exception {
  }

  /**
   * Assigns each Lead in the batch to a weighted-random advisor from the
   * matching Group/State, creates a follow-up Task, and updates the advisor's
   * last-assignment timestamp and the Lead's owner.
   *
   * Preserves the original behavior: if no eligible advisor is found for a
   * given Lead's Group/State, processing of the entire batch stops (no Tasks
   * or owner updates are committed for any Lead already processed in this
 //  * call), matching the original implementation.
   
  @InvocableMethod(label='Assign Lead')
  public static void assign(List<RoundRobinLeadAssignment> rrlas) {
    if (rrlas == null || rrlas.isEmpty()) {
      return;
    }

    try {
      List<Task> taskList = new List<Task>();
      List<Id> usersIdsToUpdate = new List<Id>();
      Map<Id, Id> leadIdOwnerIdMap = new Map<Id, Id>();

      // Cache eligible-advisor lookups per Group/State combination so repeated
      // combinations across the batch only trigger one query each.
      Map<String, List<User>> usersByGroupAndStateCache = new Map<String, List<User>>();

      for (RoundRobinLeadAssignment rra : rrlas) {
        String cacheKey = rra.groupName + '|' + rra.leadState;
        List<User> usersByGroupAndState = usersByGroupAndStateCache.get(cacheKey);
        if (usersByGroupAndState == null) {
          usersByGroupAndState = loadUsersByGroupAndState(rra.groupName, rra.leadState);
          usersByGroupAndStateCache.put(cacheKey, usersByGroupAndState);
        }

        if (usersByGroupAndState.isEmpty()) {
          System.debug(
            LoggingLevel.WARN,
            'No matching user by state: ' + rra.leadState + ' in group: ' + rra.groupName
          );
          return;
        }

        User userToUpdate = randomExtractUser(usersByGroupAndState);
        if (userToUpdate == null) {
          System.debug(LoggingLevel.WARN, 'No matching user by ODA_HnF_Weight__c');
          // Assign lead to the advisor that didn't had recently a fresh/hot lead
          userToUpdate = usersByGroupAndState[0];
        }

        leadIdOwnerIdMap.put(rra.leadRecordId, userToUpdate.Id);

        Task newTask = createTask(rra, userToUpdate.Id);
        taskList.add(newTask);
        usersIdsToUpdate.add(userToUpdate.Id);
      }

      if (!taskList.isEmpty()) {
        insert taskList;
        updateUserOdaTimestampLastObLeadAssigned(usersIdsToUpdate);
        updateLeadsOwner(leadIdOwnerIdMap);
      }
    } catch (Exception ex) {
      System.debug(
        LoggingLevel.ERROR,
        'roundRobinLeadAssigner.assign failed: ' + ex.getMessage() + '\n' + ex.getStackTraceString()
      );
      throw new RoundRobinLeadAssignerException(
        'Round Robin Lead assignment failed: ' + ex.getMessage(),
        ex
      );
    }
  }


  public static void updateLeadsOwner(Map<Id, Id> leadOwnerMap) {
    if (leadOwnerMap == null || leadOwnerMap.isEmpty()) {
      return;
    }

    List<Lead> updatedLeads = new List<Lead>();
    List<Lead> leads = [
      SELECT Id, OwnerId, OwnerIsUser__c
      FROM Lead
      WHERE Id IN :leadOwnerMap.keySet()
    ];

    for (Lead lead : leads) {
      // only update lead owner current owner is not an advisor
      if (lead.OwnerIsUser__c) {
        System.debug(
          LoggingLevel.INFO,
          'Skip owner update for lead ' + lead.Id + '. Lead own by user ' + lead.OwnerId
        );
        continue;
      }

      lead.OwnerId = leadOwnerMap.get(lead.Id);
      updatedLeads.add(lead);
    }

    if (!updatedLeads.isEmpty()) {
      update updatedLeads;
    }
  }


  @Future
  public static void updateUserOdaTimestampLastObLeadAssigned(List<Id> usersId) {
    if (usersId == null || usersId.isEmpty()) {
      return;
    }

    List<User> users = [
      SELECT Id, StatesLicensedIn__c, Oda_timestamp_last_ob_lead_assigned__c
      FROM User
      WHERE Id IN :usersId
    ];

    for (User user : users) {
      user.Oda_timestamp_last_ob_lead_assigned__c = datetime.now();
    }

    if (!users.isEmpty()) {
      update users;
    }
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

*/