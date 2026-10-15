/*
 * TaskHandler.cls
 * Consolidated handler for all Task-object trigger logic, per Salesforce
 * "one trigger per object" best practice.
 *
 * Methods (mapped 1:1 to the original standalone triggers, logic unchanged):
 *   - updateUserRoleAndProfile   <- TaskUpdateUserRole.trigger (before insert)
 *   - setReminderDateTime        <- TaskSetReminder.trigger (before insert, before update)
 *   - assignLeadOwnerOnFirstCall <- TaskLead.trigger (after insert)
 *   - notifyCTI                  <- TaskNotifyCTI.trigger (after insert, after update)
 *
 * All methods operate on bulk collections (List/Set/Map) — no SOQL or DML
 * inside loops — so this class is safe for bulk Task DML of any size.
 */
public class TaskHandler {

    // Reused across methods to avoid repeated describe calls
    private static final String LEAD_PREFIX = Lead.sObjectType.getDescribe().getKeyPrefix();
    private static final String USER_PREFIX = User.sObjectType.getDescribe().getKeyPrefix();

    /*
     * Formerly: TaskUpdateUserRole.trigger (before insert)
     * Update User Role and User Profile with the current role and profile of the owner.
     */
    public static void updateUserRoleAndProfile(List<Task> newTasks) {
        Set<Id> ownerIds = new Set<Id>();

        for (Task t : newTasks) {
            if (t.OwnerId != null && String.valueOf(t.OwnerId).startsWith('005')) {
                ownerIds.add(t.OwnerId);
            }
        }

        if (ownerIds.isEmpty()) {
            return;
        }

        Map<Id, User> userMap = new Map<Id, User>(
            [SELECT Id, UserRole.Name, Profile.Name FROM User WHERE Id IN :ownerIds]
        );

        for (Task t : newTasks) {
            User u = userMap.get(t.OwnerId);
            if (u != null) {
                t.User_Role__c = u.UserRole != null ? u.UserRole.Name : null;
                t.User_Profile__c = u.Profile.Name;
            }
        }
    }

    /*
     * Formerly: TaskSetReminder.trigger (before insert, before update)
     * Set ReminderDateTime__c to ReminderDateTime to use in reports.
     */
    public static void setReminderDateTime(List<Task> changeTasks) {
        for (Task change_task : changeTasks) {
            change_task.ReminderDateTime__c = change_task.ReminderDateTime;
        }
    }

    /*
     * Formerly: TaskLead.trigger (after insert)
     * Assigns the owner of a Lead to the Task's Assigned To User for Incoming Calls
     * (only on first call). Once a lead is assigned to an agent (generally due to the
     * automation once they take the 1st call associated with that lead) - the lead
     * should NOT be reassigned to a new agent unless manually done by a Manager.
     */
    public static void assignLeadOwnerOnFirstCall(List<Task> newTasks) {

        // Query Pong Developer user by base username using LIKE, since Salesforce
        // appends a sandbox suffix (e.g. '.eqfullsb') to usernames in sandboxes,
        // but leaves production usernames unsuffixed. This resolves correctly
        // in production and every sandbox without needing separate hardcoded values.
        Id pongDeveloperId;
        List<User> pongDevUsers = [
            SELECT Id FROM User
            WHERE Username LIKE 'pongdeveloper@everquote.com%'
            LIMIT 1
        ];
        if (!pongDevUsers.isEmpty()) {
            pongDeveloperId = pongDevUsers[0].Id;
        }

        // Query Inbound Life Queue by DeveloperName instead of Id — DeveloperName
        // is stable across production and every sandbox (Id is org-specific and
        // can differ between environments or break if the queue is ever recreated).
        Id inboundLifeQueueId;
        List<Group> inboundQueues = [
            SELECT Id FROM Group
            WHERE DeveloperName = 'Inbound_Life_Queue'
            AND Type = 'Queue'
            LIMIT 1
        ];
        if (!inboundQueues.isEmpty()) {
            inboundLifeQueueId = inboundQueues[0].Id;
        }

        // If either lookup fails (record missing/deleted/renamed in this org/sandbox),
        // safely exit rather than proceeding with a null comparison
        if (pongDeveloperId == null || inboundLifeQueueId == null) {
            return;
        }

        // A mapping of lead Ids and the Lead update to process
        Map<Id, Lead> leadsToUpdate = new Map<Id, Lead>();
        // List with relevant new tasks
        List<Task> relevantNewTasks = new List<Task>();
        // Set with WhoId for each relevant task (Set avoids duplicate binds on bulk inserts)
        Set<Id> relevantTasksWhoIds = new Set<Id>();

        // Go through all new tasks and find any that look up to a Lead
        for (Task t : newTasks) {
            // WhoId is required for this trigger
            if (String.isBlank(t.WhoId)) {
                continue;
            }
            // Get whoId prefix from task
            String whoPrefix = ((String) t.WhoId).substring(0, 3);
            // We only care about Lead Tasks that are Inbound Calls
            if (!LEAD_PREFIX.equalsIgnoreCase(whoPrefix) || t.CallType != 'Inbound') {
                continue;
            }
            relevantTasksWhoIds.add(t.WhoId);
            relevantNewTasks.add(t);
        }

        if (relevantNewTasks.isEmpty()) {
            return;
        }

        // Get the related leads for the relevant tasks in this trigger
        Map<Id, Lead> leads = new Map<Id, Lead>(
            [SELECT Id, OwnerId FROM Lead WHERE Id IN :relevantTasksWhoIds]
        );

        // Go through all relevant tasks and check if leads should be updated
        for (Task t : relevantNewTasks) {
            Lead lead = leads.get(t.WhoId);
            if (lead == null) {
                continue;
            }
            String leadOwnerPrefix = ((String) lead.OwnerId).substring(0, 3);

            // Skip updating lead owner if already owned by an agent except Pong Developer
            if (
                (USER_PREFIX.equalsIgnoreCase(leadOwnerPrefix) && lead.OwnerId != pongDeveloperId) ||
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

    /*
     * Formerly: TaskNotifyCTI.trigger (after insert, after update)
     * Notifies CTI of a Task change. Matches original behavior: one callout per
     * trigger invocation (not per record), since sendUpdate() takes no record data.
     */
    public static void notifyCTI() {
        NotifyCTI.sendUpdate('task');
    }
}