/*
 * LeadOutcomeUpdated.trigger
 *
 * Sync changes made to Lead_Outcome__c to ODIE
 *
 * Created By:      Daniel Voicu (dvoicu@everquote.com)
 * Created Date:    Apr 21, 2020
 */

trigger LeadOutcomeUpdated on Lead(after update) {
    
    
  String identifier = 'LeadOutcomeUpdated';

  if (checkTriggerRecursion.canRun(identifier)) {
    for (Lead newL : Trigger.new) {
      Lead oldL = Trigger.oldMap.get(newL.Id);

      Lead oldLead = Trigger.oldMap.get(newL.Id);
      String oldOutcome = (String) oldL.Lead_Outcome__c;
      String newOutcome = (String) newL.Lead_Outcome__c;

      if (oldOutcome != newOutcome) {
        // update sales disposition on ODIE
        OdieWrapper.updateFormDisposition(newL.Id);
      }
    }
  }

}