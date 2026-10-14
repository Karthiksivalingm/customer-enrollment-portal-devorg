public class CaseQueueTeamJob implements Queueable {

    private Map<Id, Case> caseMap;

    public CaseQueueTeamJob(Map<Id, Case> caseMap) {
        this.caseMap = caseMap;
    }

    public void execute(QueueableContext context) {

        Set<Id> queueIds = new Set<Id>();

        for (Case c : caseMap.values()) {
            if (c.OwnerId != null &&
                String.valueOf(c.OwnerId).startsWith('00G')) {
                queueIds.add(c.OwnerId);
            }
        }

        if (queueIds.isEmpty()) return;

        Map<Id, Group> queueMap = new Map<Id, Group>(
            [SELECT Id, Name FROM Group WHERE Id IN :queueIds]
        );

        List<CaseTeamMember> teamToInsert = new List<CaseTeamMember>();
        List<Case> casesToUpdate = new List<Case>();

        for (Case c : caseMap.values()) {

            if (!queueMap.containsKey(c.OwnerId)) continue;

            String queueName = queueMap.get(c.OwnerId).Name;

            // Example: Cluster mapping logic
            List<User> clusterUsers = [
                SELECT Id, Name
                FROM User
                WHERE IsActive = true
                AND Department = :queueName
            ];

            Id acctManagerId;

            for (User u : clusterUsers) {

                teamToInsert.add(new CaseTeamMember(
                    ParentId = c.Id,
                    MemberId = u.Id
                ));

                if (u.Title == 'Acct Mngr') {
                    acctManagerId = u.Id;
                }
            }

            if (acctManagerId != null) {
                casesToUpdate.add(new Case(
                    Id = c.Id,
                    OwnerId = acctManagerId
                ));
            }
        }

        if (!teamToInsert.isEmpty()) {
            insert teamToInsert;
        }

        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
    }
}