public with sharing class ODANewLifeLeadController {

    @AuraEnabled
    public static Id createNewLifeLead(Lead newLifeLead) {
        // create record in Salesforce
        RecordType lifeLeadRecordType = [ SELECT Id FROM RecordType WHERE DeveloperName = 'Life_Leads'];

        // create Form and LSS record through Odie
        String eqLeadUuid = OdieWrapper.createRecordsForNewSalesforceLead(newLifeLead);
        newLifeLead.EqLeadUuid__c = eqLeadUuid;
        newLifeLead.RecordTypeId = lifeLeadRecordType.Id;
        insert newLifeLead;

        return newLifeLead.Id;
    }

    @AuraEnabled
    public static Lead findById(String leadId) {
        return ODALeadController.findById(leadId);
    }
}