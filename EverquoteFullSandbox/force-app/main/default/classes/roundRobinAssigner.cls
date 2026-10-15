/*
   Original Code

   NOTE: Apex does not support nested block comments. The class-level doc-comment
   at the top of the original file below originally ended with a star followed
   immediately by a slash; that exact two-character sequence would close this
   wrapper comment early and break compilation, so a backslash has been inserted
   between the star and the slash there (turning it into star-backslash-slash)
   purely to keep this wrapper valid. This is a comment-syntax fix only; the
   archived code below is not compiled/executed and no logic has been altered.


 * Invocable class to perform Round Robin assignment of SObjects
 * (e.g., Opportunities, Cases) to members of a specified Salesforce Group.
 * It uses a custom setting (RoundRobin__c) to persist the index
 * of the last assigned user for a given rule (Object-Field-Group).
 * author Installed package - https://github.com/mshanemc/roundRobinProcessBuilder/blob/master/force-app/main/default/classes/roundRobinAssigner.cls
 * date 2025-12-16
 */

public without sharing class roundRobinAssigner {
  public static final integer customSettingNameLimitLength = 38;

  @InvocableMethod(label='Assign objects')
  public static void assign(list<RoundRobinAssignment> rras) {
    // what was the last user index?
    list<RoundRobin__c> RRSettings = [
      SELECT id, GroupName__c, FieldName__c, Object__c, IndexOfLastUsed__c
      FROM RoundRobin__c
    ];

    map<string, list<GroupMember>> usersByGroup = new Map<string, list<GroupMember>>();
    List<SObject> objectList = new List<SObject>();

    // get the records
    for (RoundRobinAssignment rra : rras) {
      // default field
      if (rra.fieldName == null) {
        rra.fieldName = 'OwnerId';
      }

      list<groupMember> groupUsers = new List<groupMember>();
      // see if we have it already in our map
      if (usersByGroup.get(rra.groupName) == null) {
        groupUsers = [
          SELECT Group.Name, GroupId, UserOrGroupId
          FROM GroupMember
          WHERE Group.Name = :rra.groupName
        ];
        //store in the map so we don't have to query about this group again
        usersByGroup.put(rra.groupName, groupUsers);
      } else {
        groupUsers = usersByGroup.get(rra.groupName);
      }
      // what kind of object is this, anyway?
      Id rId = id.valueOf(rra.recordId);
      string Obj = rid.getSObjectType().getDescribe().getName();

      RoundRobin__c matchingRR = recordMatcher(
        RRSettings,
        rra.fieldName,
        Obj,
        rra.groupName
      );

      sObject so = rid.getSObjectType().newSObject(rid);
      integer nextIndex = getNextIndex(matchingRR, groupUsers);
      so.put(rra.fieldName, groupUsers[nextIndex].UserOrGroupId);

      matchingRR.IndexOfLastUsed__c = nextIndex;

      // if the original list didn't contain the matching one, we need to add it here
      boolean isNew = true;
      for (RoundRobin__c rr : RRSettings) {
        // we already had that on our list
        if (rr.Id == matchingRR.Id) {
          rr.IndexOfLastUsed__c = matchingRR.IndexOfLastUsed__c;
          isNew = false;
        }
      }
      if (isNew) {
        //we hadn't seen it before
        system.debug('inserting a RR custom setting');
        RRSettings.add(matchingRR);
      }

      objectList.add(so);
    }

    update objectList;

    // because we may have incremented them
    update RRSettings;
  }

  public static integer getNextIndex(
    RoundRobin__c match,
    list<GroupMember> groupUsers
  ) {
    if (groupUsers.size() == 0) throw new IllegalArgumentException(
                'Round Robin Assigner: No members of ' + match.GroupName__c + ' found');
    else if (match.IndexOfLastUsed__c == null) {
      // it's null, so grab the first one!
      return 0;
    } else if (match.IndexOfLastUsed__c >= groupUsers.size() - 1) {
      // you've used them all
      system.debug(
        match.IndexOfLastUsed__c +
        ' is the last match, which is >= the group size of ' +
        groupUsers.size() +
        'so we are going back to 0'
      );
      return 0;
    } else {
      // return the next one
      return integer.valueOf(match.IndexOfLastUsed__c + 1);
    }
  }

  public static RoundRobin__c recordMatcher(
    list<RoundRobin__c> records,
    string FieldName,
    string Obj,
    string GroupName
  ) {
    for (RoundRobin__c rr : records) {
      if (
        rr.FieldName__c == FieldName &&
        rr.Object__c == Obj &&
        rr.GroupName__c == GroupName
      ) {
        return rr;
      }
    }

    // we never found it, so create one
    RoundRobin__c rrNew = new RoundRobin__c();
    rrNew.FieldName__c = FieldName;
    rrNew.Object__c = Obj;
    rrNew.GroupName__c = GroupName;
    // because name is required
    rrNew.Name = nameShortener(Obj, FieldName, GroupName);

    // how "too long" is it?
    insert rrNew;
    return rrNew;
  }

  public static string nameShortener(
    string Obj,
    string FieldName,
    string GroupName
  ) {
    integer tooLongness =
      Obj.length() +
      FieldName.length() +
      GroupName.length() +
      2 -
      customSettingNameLimitLength; // for separators
    while (tooLongness > 0) {
      if (Obj.length() > 10) Obj = Obj.left(Obj.length() - 1);
      if (FieldName.length() > 10) FieldName = FieldName.left(FieldName.length() - 1);
      if (GroupName.length() > 10) GroupName = GroupName.left(GroupName.length() - 1);

      tooLongness =
        Obj.length() +
        FieldName.length() +
        GroupName.length() +
        2 -
        customSettingNameLimitLength;
    }

    return Obj + '-' + FieldName + '-' + GroupName;
  }

  //what Process Builder/Flow Builder can reference for the input variables
  public class RoundRobinAssignment {
    @InvocableVariable(required=true label='group name')
    public string groupName;

    @InvocableVariable(required=true label='recordId')
    public string recordId;

    @InvocableVariable(required=false label='field name (default = ownerId)')
    public string fieldName;
  }
}


/**
 * Invocable class to perform Round Robin assignment of SObjects
 * (e.g., Opportunities, Cases) to members of a specified Salesforce Group.
 * It uses a custom setting (RoundRobin__c) to persist the index
 * of the last assigned user for a given rule (Object-Field-Group).
 * Original source: https://github.com/mshanemc/roundRobinProcessBuilder/blob/master/force-app/main/default/classes/roundRobinAssigner.cls
 
public without sharing class roundRobinAssigner {
  public static final Integer customSettingNameLimitLength = 38;

  // =========================================================================
  // Invocable entry point (called from Process Builder / Flow Builder)
  // =========================================================================
  @InvocableMethod(label='Assign objects')
  public static void assign(List<RoundRobinAssignment> rras) {
    // what was the last user index?
    List<RoundRobin__c> rrSettings = [
      SELECT Id, GroupName__c, FieldName__c, Object__c, IndexOfLastUsed__c
      FROM RoundRobin__c
    ];

    Map<String, List<GroupMember>> usersByGroup = new Map<String, List<GroupMember>>();
    List<SObject> objectList = new List<SObject>();

    // get the records
    for (RoundRobinAssignment rra : rras) {
      // default field
      if (rra.fieldName == null) {
        rra.fieldName = 'OwnerId';
      }

      List<GroupMember> groupUsers = new List<GroupMember>();
      // see if we have it already in our map
      if (usersByGroup.get(rra.groupName) == null) {
        groupUsers = [
          SELECT Group.Name, GroupId, UserOrGroupId
          FROM GroupMember
          WHERE Group.Name = :rra.groupName
        ];
        // store in the map so we don't have to query about this group again
        usersByGroup.put(rra.groupName, groupUsers);
      } else {
        groupUsers = usersByGroup.get(rra.groupName);
      }

      // what kind of object is this, anyway?
      Id rId = Id.valueOf(rra.recordId);
      String objectName = rId.getSObjectType().getDescribe().getName();

      RoundRobin__c matchingRR = recordMatcher(
        rrSettings,
        rra.fieldName,
        objectName,
        rra.groupName
      );

      SObject so = rId.getSObjectType().newSObject(rId);
      Integer nextIndex = getNextIndex(matchingRR, groupUsers);
      so.put(rra.fieldName, groupUsers[nextIndex].UserOrGroupId);

      matchingRR.IndexOfLastUsed__c = nextIndex;

      // if the original list didn't contain the matching one, we need to add it here
      Boolean isNew = true;
      for (RoundRobin__c rr : rrSettings) {
        // we already had that on our list
        if (rr.Id == matchingRR.Id) {
          rr.IndexOfLastUsed__c = matchingRR.IndexOfLastUsed__c;
          isNew = false;
        }
      }
      if (isNew) {
        // we hadn't seen it before
        System.debug('inserting a RR custom setting');
        rrSettings.add(matchingRR);
      }

      objectList.add(so);
    }

    if (!objectList.isEmpty()) {
      update objectList;
    }

    // because we may have incremented them
    if (!rrSettings.isEmpty()) {
      update rrSettings;
    }
  }

  // =========================================================================
  // Round-robin index helper
  // =========================================================================
  public static Integer getNextIndex(RoundRobin__c match, List<GroupMember> groupUsers) {
    if (groupUsers.isEmpty()) {
      throw new IllegalArgumentException(
        'Round Robin Assigner: No members of ' + match.GroupName__c + ' found'
      );
    } else if (match.IndexOfLastUsed__c == null) {
      // it's null, so grab the first one!
      return 0;
    } else if (match.IndexOfLastUsed__c >= groupUsers.size() - 1) {
      // you've used them all
      System.debug(
        match.IndexOfLastUsed__c +
        ' is the last match, which is >= the group size of ' +
        groupUsers.size() +
        'so we are going back to 0'
      );
      return 0;
    } else {
      // return the next one
      return Integer.valueOf(match.IndexOfLastUsed__c + 1);
    }
  }

  // =========================================================================
  // RoundRobin__c matching / creation helper
  // =========================================================================
  public static RoundRobin__c recordMatcher(
    List<RoundRobin__c> records,
    String fieldName,
    String objectName,
    String groupName
  ) {
    for (RoundRobin__c rr : records) {
      if (
        rr.FieldName__c == fieldName &&
        rr.Object__c == objectName &&
        rr.GroupName__c == groupName
      ) {
        return rr;
      }
    }

    // we never found it, so create one
    RoundRobin__c rrNew = new RoundRobin__c();
    rrNew.FieldName__c = fieldName;
    rrNew.Object__c = objectName;
    rrNew.GroupName__c = groupName;
    // because name is required
    rrNew.Name = nameShortener(objectName, fieldName, groupName);

    // how "too long" is it?
    insert rrNew;
    return rrNew;
  }

  // =========================================================================
  // Custom setting Name length helper
  // =========================================================================
  public static String nameShortener(String objectName, String fieldName, String groupName) {
    Integer tooLongness =
      objectName.length() +
      fieldName.length() +
      groupName.length() +
      2 -
      customSettingNameLimitLength; // for separators
    while (tooLongness > 0) {
      if (objectName.length() > 10) {
        objectName = objectName.left(objectName.length() - 1);
      }
      if (fieldName.length() > 10) {
        fieldName = fieldName.left(fieldName.length() - 1);
      }
      if (groupName.length() > 10) {
        groupName = groupName.left(groupName.length() - 1);
      }

      tooLongness =
        objectName.length() +
        fieldName.length() +
        groupName.length() +
        2 -
        customSettingNameLimitLength;
    }

    return objectName + '-' + fieldName + '-' + groupName;
  }

  // =========================================================================
  // What Process Builder/Flow Builder can reference for the input variables
  // =========================================================================
  public class RoundRobinAssignment {
    @InvocableVariable(required=true label='group name')
    public String groupName;

    @InvocableVariable(required=true label='recordId')
    public String recordId;

    @InvocableVariable(required=false label='field name (default = ownerId)')
    public String fieldName;
  }
}

*/