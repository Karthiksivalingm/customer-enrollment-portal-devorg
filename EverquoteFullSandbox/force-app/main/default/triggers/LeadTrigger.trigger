/*
 * LeadTrigger.trigger
 *
 * Single trigger for the Lead object (Salesforce best practice: one trigger
 * per object). All logic is delegated to LeadHandler, which consolidates
 * the logic formerly spread across UpdateReferral, UpdateLeadMobilePhone,
 * LeadOwnerUpdated, etcd8_LeadTrigger, LifeLeadCreated, ResetLeadWhenLost,
 * LeadOutcomeUpdated and this trigger's own LeadTriggerHandler.
 */
trigger LeadTrigger on Lead (before insert, before update, after insert, after update) {
	new LeadHandler().run();
}