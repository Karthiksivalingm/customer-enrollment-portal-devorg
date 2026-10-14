global class CaseAssignmentHybridBatch implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, OwnerId, Case_Assign_To__c, Case_Assignment_Queue__c, Case_Request__c, Status_Filtered__c, AccountId ' +
                       'FROM Case ' +
                       'WHERE Case_Assign_To__c = null ' +
                       'AND Case_Assignment_Queue__c != null ' +
                       'AND CreatedDate = TODAY ' +
                       'AND (Foundation_Record__c = TRUE OR Case_Category__c = \'New Digital Support\') ' +
                       'AND Account.FNDN_Billed_Through_TVM__c = TRUE';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Case> listCases) {
        System.debug('>>>> Hybrid execute ' + listCases.size());

        if (listCases.isEmpty()) return;

        Map<String, Case_Routing_Config__mdt> hybridConfigMap = new Map<String, Case_Routing_Config__mdt>();

        for (Case_Routing_Config__mdt cfg : [
            SELECT Id, Request_Type__c, Queue__c, Case_Entry__c, Initial_Assignment__c, Field_Name__c
            FROM Case_Routing_Config__mdt
            WHERE Case_Entry__c = 'Auto'
            AND Active__c = true
            AND Case_Type__c = 'Hybrid'
        ]) {
            if (cfg.Request_Type__c != null) {
                hybridConfigMap.put(cfg.Request_Type__c, cfg);
            }
        }

        Set<String> setQueues = new Set<String>();

        for (Case c : listCases) {
            if (c.Case_Assignment_Queue__c != null) setQueues.add(c.Case_Assignment_Queue__c);
        }

        Map<String, Id> groupIdMap = new Map<String, Id>();

        for (Group g : [SELECT Id, Name FROM Group WHERE Name IN :setQueues AND Type = 'Queue']) {
            groupIdMap.put(g.Name, g.Id);
        }

        Map<String, List<String>> groupUserMap = new Map<String, List<String>>();
        Map<Id, List<String>> groupMembersMap = new Map<Id, List<String>>();

        for (GroupMember gm : [SELECT GroupId, UserOrGroupId FROM GroupMember WHERE GroupId IN :groupIdMap.values()]) {
            if (!groupMembersMap.containsKey(gm.GroupId)) groupMembersMap.put(gm.GroupId, new List<String>());
            groupMembersMap.get(gm.GroupId).add(gm.UserOrGroupId);
        }

        for (String grpName : groupIdMap.keySet()) {
            Id gid = groupIdMap.get(grpName);
            if (groupMembersMap.containsKey(gid)) groupUserMap.put(grpName, groupMembersMap.get(gid));
        }

        Set<String> setUserIds = new Set<String>();
        setQueues.clear();

        for (Case c : listCases) {
            Case_Routing_Config__mdt cfg = hybridConfigMap.get(c.Case_Request__c);

            if (cfg != null && cfg.Queue__c != null && groupUserMap.containsKey(cfg.Queue__c)
                && cfg.Initial_Assignment__c == 'Queue' && cfg.Case_Entry__c == 'Auto') {
                setQueues.add(cfg.Queue__c);
                for (String uid : groupUserMap.get(cfg.Queue__c)) setUserIds.add(uid);
            }
        }

        List<Case> listOldRecords = [
            SELECT OwnerId, Case_Assign_To__c, Case_Assignment_Queue__c
            FROM Case
            WHERE Case_Assign_To__c IN :setUserIds
            AND Case_Assignment_Queue__c IN :setQueues
            ORDER BY LastModifiedDate DESC
        ];

        Map<String, Case> mapQueueAndCases = new Map<String, Case>();

        for (Case c : listOldRecords) {
            if (!mapQueueAndCases.containsKey(c.Case_Assignment_Queue__c)) {
                mapQueueAndCases.put(c.Case_Assignment_Queue__c, c);
            }
        }

        Map<String, Integer> mapQueueNextIndex = new Map<String, Integer>();
        Integer userNotAvailableIndex = 0;

        for (Case c : listCases) {

            if (c.Case_Assign_To__c != null) {
                continue;
            }

            Case_Routing_Config__mdt cfg = hybridConfigMap.get(c.Case_Request__c);

            if (cfg != null && cfg.Queue__c != null && groupUserMap.containsKey(cfg.Queue__c)
                && cfg.Initial_Assignment__c == 'Queue') {

                List<String> userIds = groupUserMap.get(cfg.Queue__c);

                String lastAssignedUserId = mapQueueAndCases.containsKey(c.Case_Assignment_Queue__c)
                    ? mapQueueAndCases.get(c.Case_Assignment_Queue__c).Case_Assign_To__c
                    : null;

                Integer nextUserIndex = String.isNotBlank(lastAssignedUserId)
                    ? userIds.indexOf(lastAssignedUserId) + 1
                    : 0;

                if (!mapQueueNextIndex.containsKey(c.Case_Assignment_Queue__c)) {
                    mapQueueNextIndex.put(c.Case_Assignment_Queue__c, nextUserIndex);
                }

                nextUserIndex = mapQueueNextIndex.get(c.Case_Assignment_Queue__c);

                if (nextUserIndex >= userIds.size()) nextUserIndex = 0;

                // Assign case
                c.OwnerId = userIds[nextUserIndex];
                c.Case_Assign_To__c = userIds[nextUserIndex];

                // NEW: Change status from New to Assigned
                if (c.Status_Filtered__c == 'New') {
                    c.Status_Filtered__c = 'Assigned';
                }

                mapQueueNextIndex.put(c.Case_Assignment_Queue__c, nextUserIndex + 1);
            }
        }

        update listCases;
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Hybrid Case Assignment Batch finished.');
    }
}