public inherited sharing class LeadManualApproveController {
	
    @AuraEnabled
    public static void approveLead(Id leadId, String action) {
        if (leadId == null) {
            throw new AuraHandledException('Lead Id is required.');
        }
        
        Lead selectedLead = [
            SELECT Id, Status 
            FROM Lead 
            WHERE Id = :leadId 
            LIMIT 1
        ];

        if (action == 'Approved') {
            selectedLead.Status = 'Qualified';
        } else if (action == 'Rejected') {
            selectedLead.Status = 'Manual Rejection';
        } else {
            throw new AuraHandledException('Invalid action: ' + action);
        }

        try {
            update selectedLead;
        } catch (DmlException e) {
            throw new AuraHandledException(e.getDmlMessage(0));
        }
    }
}