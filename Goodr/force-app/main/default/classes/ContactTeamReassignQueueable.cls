public class ContactTeamReassignQueueable implements Queueable {

    private Set<Id> contactIds;

    public ContactTeamReassignQueueable(Set<Id> contactIds) {
        this.contactIds = contactIds;
    }

    public void execute(QueueableContext ctx) {
        List<Contact> freshContacts = [
            SELECT Id, AccountId, Sales_Channel__c, Cluster__c
            FROM Contact
            WHERE Id IN :contactIds
        ];

        if (!freshContacts.isEmpty()) {
            ClusterTeamEngine.assignTeams('Contact', freshContacts);
        }
    }


}