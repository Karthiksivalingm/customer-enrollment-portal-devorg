public with sharing class ODALeadOutcomeController {
  @AuraEnabled
  public static Lead getById(String leadId) {
    Lead lead = [
      SELECT Id, Lead_Outcome__c, Policy_Number__c, EqLeadUuid__c, Phone
      FROM Lead
      WHERE Id = :leadId
    ];
    return lead;
  }

  @AuraEnabled
  public static string getLeadOutcomeOptions() {
    Schema.DescribeSObjectResult objSchema = Lead.sObjectType.getDescribe();
    Map<String, Schema.SObjectField> fieldMap = objSchema.fields.getmap();

    List<Schema.Picklistentry> picklistEntries = fieldmap.get('lead_outcome__c')
      .getDescribe()
      .getpicklistValues();

    List<Map<String, String>> leadOutcomeOptions = new List<Map<String, String>>();
    for (Schema.PicklistEntry pckEntry : picklistEntries) {
      Map<String, String> option = new Map<String, String>{
        'label' => pckEntry.getLabel(),
        'value' => pckEntry.getValue()
      };

      leadOutcomeOptions.add(option);
    }

    return JSON.serialize(leadOutcomeOptions);
  }

  @AuraEnabled
public static Lead updateLeadOutcome(Id leadId, String leadOutcome) {
    Lead newLead = new Lead(
        Id = leadId,
        Lead_Outcome__c = leadOutcome
    );

    try {
        update newLead;
        return getById(newLead.Id);
    } catch (DmlException e) {
        throw new AuraHandledException(
            'Unable to update the Lead outcome. Please try again.'
        );
    }
}
}