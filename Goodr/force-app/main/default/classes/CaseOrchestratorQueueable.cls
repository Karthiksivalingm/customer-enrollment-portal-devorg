public with sharing class CaseOrchestratorQueueable 
implements Queueable {
    
    private List<Case> newCases;
    private Map<Id, Case> oldMap;
    
    public CaseOrchestratorQueueable(List<Case> newCases,
                                     Map<Id, Case> oldMap) {
                                         this.newCases = newCases;
                                         this.oldMap = oldMap;
                                     }
    
    public void execute(QueueableContext context) {
        
        CaseOrchestrationEngine.process(newCases, oldMap);
        
    }
}