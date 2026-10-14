public without sharing class ClusterTeamEngine {

    public static void assignTeams(
        String objectName,
        List<SObject> records
    ) {

        if (records.isEmpty()) return;

        Set<String> clusterValues = new Set<String>();
        Set<Id> recordIds = new Set<Id>();

        for (SObject rec : records) {
            recordIds.add(rec.Id);
            String cluster = (String)rec.get('Cluster__c');
            if (!String.isBlank(cluster)) {
                clusterValues.add(cluster);
            }
        }

        if (clusterValues.isEmpty()) return;

        Map<String,List<Account_Cluster_Team__mdt>> rulesByCluster =
            new Map<String,List<Account_Cluster_Team__mdt>>();

        for (Account_Cluster_Team__mdt rule : [
            SELECT Cluster_Value__c,
                   User_Identifier__c,
                   Team_Role__c,
                   Access_Level__c,
                   ObjectAPIName__c
            FROM Account_Cluster_Team__mdt
            WHERE Cluster_Value__c IN :clusterValues
            AND ObjectAPIName__c = :objectName
        ]) {

            if (!rulesByCluster.containsKey(rule.Cluster_Value__c)) {
                rulesByCluster.put(rule.Cluster_Value__c,
                    new List<Account_Cluster_Team__mdt>());
            }
            rulesByCluster.get(rule.Cluster_Value__c).add(rule);
        }

        if (rulesByCluster.isEmpty()) return;

        Set<String> usernames = new Set<String>();
        for (List<Account_Cluster_Team__mdt> ruleList :
             rulesByCluster.values()) {
            for (Account_Cluster_Team__mdt rule : ruleList) {
                usernames.add(rule.User_Identifier__c);
            }
        }

        Map<String,User> usersByUsername = new Map<String,User>();

        for (User u : [
            SELECT Id, Username
            FROM User
            WHERE Username IN :usernames
            AND IsActive = true
        ]) {
            usersByUsername.put(u.Username, u);
        }

        deleteExistingTeams(objectName, recordIds);

        List<SObject> toInsert = new List<SObject>();

        for (SObject rec : records) {

            String cluster = (String)rec.get('Cluster__c');

            if (String.isBlank(cluster) ||
                !rulesByCluster.containsKey(cluster)) continue;

            for (Account_Cluster_Team__mdt rule :
                 rulesByCluster.get(cluster)) {

                User u = usersByUsername.get(rule.User_Identifier__c);
                if (u == null) continue;

                if (objectName == 'Account') {
                    toInsert.add(new AccountTeamMember(
                        AccountId = rec.Id,
                        UserId = u.Id,
                        TeamMemberRole = rule.Team_Role__c,
                        AccountAccessLevel = rule.Access_Level__c
                    ));
                }
                else if (objectName == 'Contact') {
                    toInsert.add(new Contact_Team__c(
                        Contact__c = rec.Id,
                        Team_Member__c = u.Id,
                        TeamMemberRole__c = rule.Team_Role__c,
                        Access_Level__c = rule.Access_Level__c
                    ));
                }
                else if (objectName == 'Lead') {
                    toInsert.add(new Lead_Team__c(
                        Lead__c = rec.Id,
                        Team_Member__c = u.Id,
                        TeamMemberRole__c = rule.Team_Role__c,
                        Access_Level__c = rule.Access_Level__c
                    ));
                }
                else if (objectName == 'Opportunity') {
                    toInsert.add(new OpportunityTeamMember(
                        OpportunityId = rec.Id,
                        UserId = u.Id,
                        TeamMemberRole = rule.Team_Role__c
                    ));
                }
                
            }
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
    }

    private static void deleteExistingTeams(
        String objectName,
        Set<Id> recordIds
    ) {

        if (objectName == 'Account') {
            delete [SELECT Id FROM AccountTeamMember
                    WHERE AccountId IN :recordIds];
        }
        else if (objectName == 'Contact') {
            delete [SELECT Id FROM Contact_Team__c
                    WHERE Contact__c IN :recordIds];
        }
        else if (objectName == 'Lead') {
            delete [SELECT Id FROM Lead_Team__c
                    WHERE Lead__c IN :recordIds];
        }
        else if (objectName == 'Opportunity') {
            delete [SELECT Id FROM OpportunityTeamMember
                    WHERE OpportunityId IN :recordIds];
        }
        
    }
}