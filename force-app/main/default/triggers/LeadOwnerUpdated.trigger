/*
 * LeadOwnerUpdated.trigger
 *
 * Sync changes made to Lead Owner to ODIE
 *
 * Created By:      Daniel Voicu (dvoicu@everquote.com)
 * Created Date:    Jun 30, 2020
 */

trigger LeadOwnerUpdated on Lead(after update) {
     String identifier = 'LeadOwnerUpdated';

  if (checkTriggerRecursion.canRun(identifier)) {
    Id[] leadIdsToSyncOwner = new List<Id>();
    for (Lead newLeadVersion : Trigger.new) {
      Lead oldLeadVersion = Trigger.oldMap.get(newLeadVersion.Id);

      if (newLeadVersion.EqLeadUuid__c == null) {
        continue;
      }

      if (oldLeadVersion.OwnerId != newLeadVersion.OwnerId) {
        // update form owner on ODIE
        leadIdsToSyncOwner.add(newLeadVersion.Id);
      }
    }

    if (!leadIdsToSyncOwner.isEmpty()) {
      OdieWrapper.syncLeadOwnerToOdieFuture(leadIdsToSyncOwner);
    }
  }

}