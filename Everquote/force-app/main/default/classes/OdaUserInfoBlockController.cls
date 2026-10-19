public with sharing class OdaUserInfoBlockController {
    
    @AuraEnabled(Cacheable=false)
    public static LeadAndFieldSet getLeadUserInfo(Id leadId) {
        LeadAndFieldSet returnValue = new LeadAndFieldSet();
        String query = 'SELECT ';

        for(Schema.FieldSetMember f : SObjectType.Lead.FieldSets.ODA_Info_Block.getFields()) {
            query += f.getFieldPath() + ', ';
            returnValue.labels.add(f.getLabel());
            returnValue.apiNames.add(f.getFieldPath());
        }
        query += 'Id FROM Lead WHERE Id = \''+ leadId + '\'';
        List<Lead> leads = (List<Lead>) Database.query(query);
        if (!leads.isEmpty()) {
            returnValue.lead = leads.get(0);
        }

        return returnValue;
    }

    public class LeadAndFieldSet {
        @AuraEnabled public List<String> labels;
        @AuraEnabled public List<String> apiNames;
        @AuraEnabled public Lead lead;

        public LeadAndFieldSet() {
            this.labels = new List<String>();
            this.apiNames = new List<String>();
        }
    }
}