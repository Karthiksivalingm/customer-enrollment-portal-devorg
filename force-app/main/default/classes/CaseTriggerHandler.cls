public class CaseTriggerHandler {
    
    public static void processBeforeInsert(List<Case> newCases) {
        
        List<Case> casesToProcess = new List<Case>();
        
        for (Case c : newCases) {
            if (c.Origin != 'Zendesk') {
                casesToProcess.add(c);
            }
        }
        
        if (!casesToProcess.isEmpty()) {
            CaseTriggerHelper.assignCaseCluster(casesToProcess);
        }
    }
}