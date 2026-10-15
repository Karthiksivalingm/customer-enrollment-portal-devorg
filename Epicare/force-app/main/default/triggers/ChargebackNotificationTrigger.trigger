trigger ChargebackNotificationTrigger on Commission_Record__c (after insert) {
  List<Commission_Paid__e> events = new List<Commission_Paid__e>();
    
    for (Commission_Record__c cr : Trigger.new) {
        // Only fire for Chargeback type
        if (cr.Compensation_Type__c == 'Chargeback') {
            events.add(new Commission_Paid__e(
                Contact_ID__c   = String.valueOf(cr.Agent__c),
                Batch_ID__c     = String.valueOf(cr.Payment_Batch__c),
                Total_Amount__c = String.valueOf(cr.Chargeback_Amount__c),
                Period__c       = cr.Payment_Period__c
            ));
        }
    }
    
    if (!events.isEmpty()) {
        List<Database.SaveResult> results = EventBus.publish(events);
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                for (Database.Error err : results[i].getErrors()) {
                    System.debug('Chargeback PE Error: ' + err.getMessage());
                }
            }
        }
   }   
}