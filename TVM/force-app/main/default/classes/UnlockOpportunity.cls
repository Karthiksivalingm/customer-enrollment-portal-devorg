public class UnlockOpportunity {
  @InvocableMethod(label='Unlock Opps' description='Unlocks an Opportunity that had been Approved' category='Opportunities')
  public static void getOpportunity(List<Opportunity> ids) {
    //Check locked records
    for (Opportunity opp : ids) {
        if(Approval.isLocked(opp.id)){
            Approval.unlock(opp.id);
		}
    }
  }
}