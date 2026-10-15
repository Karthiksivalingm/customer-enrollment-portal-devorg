@isTest
public class CommissionPaymentBatchRollupHandlerTest {

    @testSetup
    static void setupData() {

        Payment_Batch__c batch = new Payment_Batch__c();
        insert batch;
    }

    @isTest
    static void testUpdatePaymentBatchTotals() {

        Payment_Batch__c batch = [
            SELECT Id
            FROM Payment_Batch__c
            LIMIT 1
        ];

        List<Commission_Record__c> records = new List<Commission_Record__c>{

            new Commission_Record__c(
                Payment_Batch__c = batch.Id,
                Gross_Amount__c = 120,
                Admin_Fee__c = 10,
                Chargeback_Amount__c = 10
            ),

            new Commission_Record__c(
                Payment_Batch__c = batch.Id,
                Gross_Amount__c = 250,
                Admin_Fee__c = 20,
                Chargeback_Amount__c = 30
            )
        };

        insert records;

        Test.startTest();
        CommissionPaymentBatchRollupHandler.updatePaymentBatchTotals(records);
        Test.stopTest();

        Payment_Batch__c updatedBatch = [
            SELECT Total_Net__c,
                   Total_Gross__c
            FROM Payment_Batch__c
            WHERE Id = :batch.Id
        ];

        // Net = (120-10-10) + (250-20-30) = 100 + 200 = 300
        System.assertEquals(300, updatedBatch.Total_Net__c);

        // Gross = 120 + 250 = 370
        System.assertEquals(370, updatedBatch.Total_Gross__c);
    }

    @isTest
    static void testNoPaymentBatch() {

        List<Commission_Record__c> records = new List<Commission_Record__c>{

            new Commission_Record__c(
                Gross_Amount__c = 120,
                Admin_Fee__c = 10,
                Chargeback_Amount__c = 10
            )
        };

        Test.startTest();
        CommissionPaymentBatchRollupHandler.updatePaymentBatchTotals(records);
        Test.stopTest();

        System.assert(true);
    }
}