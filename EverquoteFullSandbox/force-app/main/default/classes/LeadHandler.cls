/*
 * LeadHandler.cls
 *
 * Single trigger handler for the Lead object. Consolidates the logic that
 * previously lived in separate Lead triggers (UpdateReferral, UpdateLeadMobilePhone,
 * LeadOwnerUpdated, etcd8_LeadTrigger, LifeLeadCreated, ResetLeadWhenLost,
 * LeadOutcomeUpdated, LeadTrigger) into one bulkified handler, one method per
 * original trigger, invoked from the single remaining LeadTrigger.trigger.
 *
 * Integration/algorithm logic remains in existing service classes
 * (OdieWrapper, etcd8_RRLeadAssignment, checkTriggerRecursion, LeadTriggerHelper)
 * and is called from here rather than re-implemented.
 * // LeadTriggerHandler - To be commanded
 */
public class LeadHandler extends TriggerHandler {
  private static final Id LIFE_RECORD_TYPE_ID = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Life_Leads').getRecordTypeId();

  public override void beforeInsert() {
    List<Lead> newLeads = (List<Lead>) Trigger.new;

    checkLeadScore(newLeads, 'LeadBeforeInsert');
    syncMobilePhoneWithPhone(newLeads);
  }

  public override void beforeUpdate() {
    List<Lead> newLeads = (List<Lead>) Trigger.new;
    Map<Id, Lead> oldLeadMap = (Map<Id, Lead>) Trigger.oldMap;

    checkLeadScore(newLeads, 'LeadBeforeUpdate');
    syncMobilePhoneWithPhone(newLeads);
    resetCallFieldsWhenLost(newLeads);
    assignRoundRobinLeads(newLeads, oldLeadMap);
  }

  public override void afterInsert() {
    List<Lead> newLeads = (List<Lead>) Trigger.new;

    syncNewLifeLeadsToOdie(newLeads);
  }

  public override void afterUpdate() {
    List<Lead> newLeads = (List<Lead>) Trigger.new;
    Map<Id, Lead> oldLeadMap = (Map<Id, Lead>) Trigger.oldMap;

    updateConvertedLeadReferrals(newLeads);
    syncOwnerChangeToOdie(newLeads, oldLeadMap);
    syncOutcomeChangeToOdie(newLeads, oldLeadMap);
  }

  /*
   * Formerly LeadTrigger.trigger -> LeadTriggerHandler.cls
   * Sets a default lead score for web-scraped leads, gated by the same
   * Trigger_Setting__mdt records used previously.
   */
  private void checkLeadScore(List<Lead> leads, String triggerSettingName) {
    Trigger_Setting__mdt tsmdt = Trigger_Setting__mdt.getInstance(triggerSettingName);
    if (tsmdt == null || !tsmdt.Is_Active__c) {
      return;
    }
    LeadTriggerHelper.CheckLeadScore(leads);
  }

  /*
   * Formerly UpdateLeadMobilePhone.trigger
   * Twilio uses MobilePhone for sending sms, so keep it in sync with Phone.
   */
  private void syncMobilePhoneWithPhone(List<Lead> leads) {
    String triggerIdentifier = 'UpdateLeadMobilePhone';
    if (!checkTriggerRecursion.canRun(triggerIdentifier)) {
      return;
    }

    for (Lead lead : leads) {
      if (lead.MobilePhone != lead.Phone) {
        lead.MobilePhone = lead.Phone;
      }
    }
  }

  /*
   * Formerly ResetLeadWhenLost.trigger
   */
  private void resetCallFieldsWhenLost(List<Lead> leads) {
    for (Lead lead : leads) {
      if (lead.Status == 'Lost') {
        lead.GateKeeperCallCount__c = null;
        lead.DMCallCount__c = null;
        lead.LastCallDispo__c = null;
      }
    }
  }

  /*
   * Formerly etcd8_LeadTrigger.trigger -> etcd8_RRLeadAssignment.cls
   */
  private void assignRoundRobinLeads(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
    new etcd8_RRLeadAssignment()
      .OnBeforeUpdate(Trigger.old, newLeads, oldLeadMap, (Map<Id, Lead>) Trigger.newMap);
  }

  /*
   * Formerly LifeLeadCreated.trigger
   * New Life Leads created from within Salesforce (no EqLeadUuid__c yet) get
   * ODIE records created; ones that already arrived with an EqLeadUuid__c
   * just need their owner synced.
   */
  private void syncNewLifeLeadsToOdie(List<Lead> newLeads) {
    List<Id> lifeLeadIdsToCreate = new List<Id>();
    List<Id> lifeLeadIdsToSyncOwner = new List<Id>();

    for (Lead lead : newLeads) {
      if (lead.RecordTypeId != LIFE_RECORD_TYPE_ID) {
        continue;
      }

      if (lead.EqLeadUuid__c != null) {
        lifeLeadIdsToSyncOwner.add(lead.Id);
      } else {
        lifeLeadIdsToCreate.add(lead.Id);
      }
    }

    if (!lifeLeadIdsToSyncOwner.isEmpty()) {
      OdieWrapper.syncLeadOwnerToOdieFuture(lifeLeadIdsToSyncOwner);
    }

    if (!lifeLeadIdsToCreate.isEmpty()) {
      OdieWrapper.createRecordsForNewSalesforceLeadsFuture(lifeLeadIdsToCreate);
    }
  }

  /*
   * Formerly UpdateReferral.trigger
   * Bulkified: single query for all converted leads' referrals, single update.
   */
  private void updateConvertedLeadReferrals(List<Lead> newLeads) {
    Map<Id, Lead> convertedLeadsById = new Map<Id, Lead>();
    for (Lead lead : newLeads) {
      if (lead.isConverted) {
        convertedLeadsById.put(lead.Id, lead);
      }
    }

    if (convertedLeadsById.isEmpty()) {
      return;
    }

    List<Referral__c> referralsToUpdate = [
      SELECT Id, Referral__c, Referral_Account__c, Referral_Contact__c, Referral_Opportunity__c
      FROM Referral__c
      WHERE Referral__c IN :convertedLeadsById.keySet()
    ];

    for (Referral__c referral : referralsToUpdate) {
      Lead convertedLead = convertedLeadsById.get(referral.Referral__c);
      referral.Referral_Account__c = convertedLead.ConvertedAccountId;
      referral.Referral_Contact__c = convertedLead.ConvertedContactId;
      referral.Referral_Opportunity__c = convertedLead.ConvertedOpportunityId;
    }

    update referralsToUpdate;
  }

  /*
   * Formerly LeadOwnerUpdated.trigger
   */
  private void syncOwnerChangeToOdie(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
    String triggerIdentifier = 'LeadOwnerUpdated';
    if (!checkTriggerRecursion.canRun(triggerIdentifier)) {
      return;
    }

    List<Id> leadIdsToSyncOwner = new List<Id>();
    for (Lead newLead : newLeads) {
      if (newLead.EqLeadUuid__c == null) {
        continue;
      }

      Lead oldLead = oldLeadMap.get(newLead.Id);
      if (oldLead.OwnerId != newLead.OwnerId) {
        leadIdsToSyncOwner.add(newLead.Id);
      }
    }

    if (!leadIdsToSyncOwner.isEmpty()) {
      OdieWrapper.syncLeadOwnerToOdieFuture(leadIdsToSyncOwner);
    }
  }

  /*
   * Formerly LeadOutcomeUpdated.trigger
   * Bulkified into a single future call (bulk SOQL) instead of one future
   * call per changed lead, to stay well under the future-call governor limit.
   */
  private void syncOutcomeChangeToOdie(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
    String triggerIdentifier = 'LeadOutcomeUpdated';
    if (!checkTriggerRecursion.canRun(triggerIdentifier)) {
      return;
    }

    List<Id> leadIdsWithOutcomeChange = new List<Id>();
    for (Lead newLead : newLeads) {
      Lead oldLead = oldLeadMap.get(newLead.Id);
      if (oldLead.Lead_Outcome__c != newLead.Lead_Outcome__c) {
        leadIdsWithOutcomeChange.add(newLead.Id);
      }
    }

    if (!leadIdsWithOutcomeChange.isEmpty()) {
      OdieWrapper.updateFormDispositionFuture(leadIdsWithOutcomeChange);
    }
  }
}