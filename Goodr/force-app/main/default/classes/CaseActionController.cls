public with sharing class CaseActionController {
    
    @AuraEnabled
    public static void resolveCase(Id caseId) {
        if(caseId == null) {
            throw new AuraHandledException('Case Id is required');
        }
        
        Case c = [SELECT Id, Status FROM Case WHERE Id = :caseId LIMIT 1];
        c.Status = 'Resolved';
        update c;
    }

    @AuraEnabled
    public static void changeStatus(Id caseId, String newStatus) {
        if(caseId == null) {
            throw new AuraHandledException('Case Id is required');
        }

        if(String.isBlank(newStatus)) {
            throw new AuraHandledException('New Status is required');
        }

        Case c = [SELECT Id, Status FROM Case WHERE Id = :caseId LIMIT 1];
        c.Status = newStatus;
        update c;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getCaseStatusesExcludingResolved() {
        List<CaseStatus> statuses = [
            SELECT MasterLabel 
            FROM CaseStatus 
            WHERE MasterLabel != 'Resolved'
            ORDER BY SortOrder
        ];
        
        List<String> statusList = new List<String>();
        for(CaseStatus cs : statuses) {
            if(cs.MasterLabel != 'Resolved') {
                statusList.add(cs.MasterLabel);
            }
        }
        return statusList;
    }
}