public class CommissionPaymentBatchRollupHandler {

    public static void updatePaymentBatchTotals(List<Commission_Record__c> records){

        Set<Id> batchIds = new Set<Id>();

        for(Commission_Record__c rec : records){
            if(rec.Payment_Batch__c != null){
                batchIds.add(rec.Payment_Batch__c);
            }
        }

        if(batchIds.isEmpty()){
            return;
        }

        Map<Id, Decimal> netMap = new Map<Id, Decimal>();
        Map<Id, Decimal> grossMap = new Map<Id, Decimal>();

        for(AggregateResult ar : [

            SELECT
                Payment_Batch__c batchId,
                SUM(Net_Amount__c) totalNet,
                SUM(Gross_Amount__c) totalGross

            FROM Commission_Record__c

            WHERE Payment_Batch__c IN :batchIds

            GROUP BY Payment_Batch__c

        ]){

            netMap.put(
                (Id)ar.get('batchId'),
                (Decimal)ar.get('totalNet')
            );

            grossMap.put(
                (Id)ar.get('batchId'),
                (Decimal)ar.get('totalGross')
            );
        }

        List<Payment_Batch__c> updates = new List<Payment_Batch__c>();

        for(Id batchId : batchIds){

            updates.add(new Payment_Batch__c(
                Id = batchId,
                Total_Net__c = netMap.containsKey(batchId) ? netMap.get(batchId) : 0,
                Total_Gross__c = grossMap.containsKey(batchId) ? grossMap.get(batchId) : 0
            ));
        }

        if(!updates.isEmpty()){
            update updates;
        }
    }
}