trigger CommissionPaidTrigger on Payment_Batch__c (after update) {
    Set<Id> paidBatchIds = new Set<Id>();
    for (Payment_Batch__c pb : Trigger.new) {
        Payment_Batch__c oldPb = Trigger.oldMap.get(pb.Id);
        if (pb.Status__c == 'Paid' && oldPb.Status__c != 'Paid') {
            paidBatchIds.add(pb.Id);
        }
    }
    if (paidBatchIds.isEmpty()) return;
    List<AggregateResult> agentTotals = [
        SELECT Agent__c,
               Payment_Batch__c batchId,
               SUM(Net_Amount__c) totalAmount,
               MIN(Payment_Period__c) period
        FROM Commission_Record__c
        WHERE Payment_Batch__c IN :paidBatchIds
        AND Agent__c != null
        GROUP BY Agent__c, Payment_Batch__c
    ];
    if (agentTotals.isEmpty()) return;
    List<Commission_Paid__e> events = new List<Commission_Paid__e>();
    for (AggregateResult ar : agentTotals) {
        // FIX (client UAT, PB-0018): this used to read
        // Payment_Batch__r.Payment_Period__c — the PARENT Payment_Batch__c
        // record's own field of the same name, which holds unrelated data,
        // not the Commission_Record__c's own Payment_Period__c ("YYYY-MM",
        // e.g. "2026-08", confirmed correct via SOQL on the CR itself).
        // That wrong-object read is exactly why the event arrived at GO AMS
        // as "0009-01-01 to 0009-01-31" — the stray value read off the
        // batch record, once run through the old date-range math below,
        // produced year 0009. Now reads Payment_Period__c directly off
        // Commission_Record__c.
        //
        // ALSO FIX: per the client's own request ("send the field as-is
        // without date-range transformation — our subscriber already
        // accepts the YYYY-MM format directly"), this no longer converts
        // the period into a Date / start-end range at all. The old
        // Date.valueOf()/daysInMonth() block is removed entirely — the
        // raw "YYYY-MM" string is passed straight through.
        Object periodObj = ar.get('period');
        String periodStr = periodObj == null ? '' : String.valueOf(periodObj);
        events.add(new Commission_Paid__e(
            Contact_ID__c   = String.valueOf(ar.get('Agent__c')),
            Batch_ID__c     = String.valueOf(ar.get('batchId')),
            Total_Amount__c = String.valueOf(ar.get('totalAmount')),
            Period__c       = periodStr
        ));
    }
    // Publish + error handling moved to CommissionPaidHelper.publishEvents
    // (same try/catch, same Error_Log__c fields, same behavior) — only
    // relocated so a test-only flag on the helper can force the catch
    // branch for coverage, since triggers have no static members a test
    // class can reach into.
    CommissionPaidHelper.publishEvents(events);
}