public with sharing class syncLeadOwnerToOdie {
  public class LeadToSync {
    @InvocableVariable(required=true label='Lead RecordId')
    public String leadRecordId;
  }

  @InvocableMethod(label='LeadOwnerSync')
  public static void sync(List<LeadToSync> leadsToSync) {
    List<Id> leadsId = new List<Id>();

    for (LeadToSync leadToSync : leadsToSync) {
      leadsId.add(leadToSync.leadRecordId);
    }

    OdieWrapper.syncLeadOwnerToOdieFuture(leadsId);
  }
}