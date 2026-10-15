public class ContactactiveTriggerHandler {

    public static void updateActiveAgentCount(Set<Id> accountIds){

        // Get count of active agents for each Account
        Map<Id, Integer> activeAgentCountMap = new Map<Id, Integer>();

        for(AggregateResult ar : [
            SELECT AccountId accId, COUNT(Id) total
            FROM Contact
            WHERE AccountId IN :accountIds
            AND Agent_Status__c = 'Active'
            GROUP BY AccountId
        ]){
            activeAgentCountMap.put(
                (Id) ar.get('accId'),
                (Integer) ar.get('total')
            );
        }

        List<Account> accountsToUpdate = new List<Account>();

        for(Id accId : accountIds){

            Integer activeCount = 0;

            if(activeAgentCountMap.containsKey(accId)){
                activeCount = activeAgentCountMap.get(accId);
            }

            accountsToUpdate.add(new Account(
                Id = accId,
                Total_Active_Agents__c = activeCount
            ));
        }

        if(!accountsToUpdate.isEmpty()){
            update accountsToUpdate;
        }
    }
}