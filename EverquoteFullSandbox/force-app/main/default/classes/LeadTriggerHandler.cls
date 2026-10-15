public class LeadTriggerHandler extends TriggerHandler{
	public override void beforeInsert() {
        Trigger_Setting__mdt tsmdt = Trigger_Setting__mdt.getInstance('LeadBeforeInsert');
        if(tsmdt.Is_Active__c){
            List<Lead> newRecords = (List<Lead>) Trigger.New;
        	LeadTriggerHelper.CheckLeadScore(newRecords);
            
        }
    }

	public override void beforeUpdate() {
        Trigger_Setting__mdt tsmdt = Trigger_Setting__mdt.getInstance('LeadBeforeUpdate');
        if(tsmdt.Is_Active__c){
            List<Lead> newRecords = (List<Lead>) Trigger.New;                    
            LeadTriggerHelper.CheckLeadScore(newRecords);
        }
    }
}