public class CaseTriggerHelper {

    private static final Map<String, String> QUEUE_DEV_NAME_TO_CLUSTER = new Map<String, String>{
        'Cluster_1' => 'Cluster 1', 
        'Cluster_2' => 'Cluster 2', 
        'Cluster_3' => 'Cluster 3',
        'Cluster_4' => 'Cluster 4'  
    };
    
    public static void assignCaseCluster(List<Case> newCases) {

        Set<String> queueDevNames = QUEUE_DEV_NAME_TO_CLUSTER.keySet();
        Map<Id, String> ownerIdToClusterMap = new Map<Id, String>();

        // NEW (Added around line 13): Query queues once and store results
        List<Group> queueGroups = [
            SELECT Id, DeveloperName 
            FROM Group 
            WHERE Type = 'Queue' 
            AND DeveloperName IN :queueDevNames
        ];

        // Existing logic preserved
        for (Group queue : queueGroups) {
            ownerIdToClusterMap.put(queue.Id, QUEUE_DEV_NAME_TO_CLUSTER.get(queue.DeveloperName));
        }

        // Existing logic preserved
        for (Case c : newCases) {
            if (String.isBlank(c.Cluster__c) && ownerIdToClusterMap.containsKey(c.OwnerId)) {
                c.Case_Cluster__c = ownerIdToClusterMap.get(c.OwnerId);
            }
        }
    }
}