/*
 * LifeLeadCreated.trigger
 * - Callback after a Life Lead is created
 *
 * Created By:      Jacob Murphy (jmurphy@everquote.com)
 * Created Date:    Feb 6, 2020
 */
trigger LifeLeadCreated on Lead(after insert) {
   
  Id[] lifeLeadIdsToUpdate = new List<Id>();
  Id[] lifeLeadIdsToSyncOwner = new List<Id>();

  // Go through all new Life Leads and give them an EqLeadUuid__c value if they do not have one
  // If a Life Lead doesn't have an EqLeadUuid__c value, it means they were created from within Salesforce by an agent
  for (Lead lead : Trigger.new) {
    // only do this for Life Leads
    if (lead.RecordTypeId != '0121a000000VlZ7AAK') {
      continue;
    }
    if (lead.EqLeadUuid__c != null) {
      lifeLeadIdsToSyncOwner.add(lead.Id);
      continue;
    }

    lifeLeadIdsToUpdate.add(lead.Id);
  }

  if (!lifeLeadIdsToSyncOwner.isEmpty()) {
    OdieWrapper.syncLeadOwnerToOdieFuture(lifeLeadIdsToSyncOwner);
  }

  if (!lifeLeadIdsToUpdate.isEmpty()) {
    OdieWrapper.createRecordsForNewSalesforceLeadsFuture(lifeLeadIdsToUpdate);
  }

}