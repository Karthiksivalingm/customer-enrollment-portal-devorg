/*
 * TaskLead.trigger
 * Assigns the owner of a Lead to the Task's Assigned To User for Incoming Calls (only on first call)
 * Once a lead is assigned to an agent (generally due to the automation once they take the 1st call
 * associated with that lead) - the lead should NOT be reassigned to a new agent unless manually done by a Manager.
 *
 * Created By:      Daniel Bailey (dbailey@opfocus.com)
 * Created Date:    Dec 9, 2019
 *
 * Updated By:      Daniel Voicu (dvoicu@everquote.com)
 * Updated Date:    Apr 8, 2020
 */
trigger TaskLead on Task(after insert) {
  Id pongDeveloperId = '0051a000002j8TUAAY';
  Id inboundLifeQueueId = '00G2g000000HbBiEAK';

  // Prefix for lead object Ids (Three character prefix for all Lead objects)
  String leadPrefix = Lead.sObjectType.getDescribe().getKeyPrefix();

  // Prefix for user object Ids (Three character prefix for all User objects)
  String userPrefix = User.sObjectType.getDescribe().getKeyPrefix();

  // A mapping of lead Ids and the Lead update to process
  Map<Id, Lead> leadsToUpdate = new Map<Id, Lead>();

  // List with relevant new tasks
  List<Task> relevantNewTasks = new List<Task>();

  // List with WhoId for each relevant task
  List<Id> relevantTasksWhoIds = new List<Id>();

  // Go through all new tasks and find any that look up to a Lead
  for (Task t : Trigger.new) {
    // WhoId is required for this trigger
    if (String.isBlank(t.WhoId)) {
      continue;
    }

    // Get whoId prefix from task
    String whoPrefix = ((String) t.WhoId).substring(0, 3);

    // We only care about Lead Tasks that are Inbound Calls
    if (!leadPrefix.equalsIgnoreCase(whoPrefix) || t.CallType != 'Inbound') {
      continue;
    }

    relevantTasksWhoIds.add(t.WhoId);
    relevantNewTasks.add(t);
  }

  // Get the related leads for the relevant tasks in this trigger
  Map<Id, Lead> leads = new Map<Id, Lead>(
    [SELECT Id, OwnerId FROM Lead WHERE Id IN :relevantTasksWhoIds]
  );

  // Go through all relevant tasks and check if leads should be updated
  for (Task t : relevantNewTasks) {
    Lead lead = leads.get(t.WhoId);

    String leadOwnerPrefix = ((String) lead.OwnerId).substring(0, 3);
    // Skip updating lead owner if already owned by an agent except Pong Developer
    if (
      (userPrefix.equalsIgnoreCase(leadOwnerPrefix) && lead.OwnerId != pongDeveloperId) ||
      lead.OwnerId != inboundLifeQueueId
    ) {
      continue;
    }

    // Skip updating lead owner if current owner is not Inbound Life Queue
    if (lead.OwnerId != inboundLifeQueueId) {
      continue;
    }

    // Set the lead owner to match the task owner (assigned to)
    leadsToUpdate.put(t.WhoId, new Lead(Id = t.WhoId, OwnerId = t.OwnerId));
  }

  // Update any leads that have changes
  if (!leadsToUpdate.isEmpty()) {
    update leadsToUpdate.values();
  }
}