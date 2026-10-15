@isTest
public class TriggerNAICProducerCodeTest {
    @isTest
    static void testInsertTrigger() {
        // Create test data
        NAICProducerCode__c npn = new NAICProducerCode__c(
            Name = 'Test NPN',
           NPNNumber__c='17595388');

        Test.startTest();
        insert npn; // Should fire After Insert and enqueue NIPRAddTargets
        Test.stopTest(); // Executes the queued job
    }
    
    @isTest
    static void testDeleteTrigger() {
        NAICProducerCode__c npn = new NAICProducerCode__c(
            Name = 'To Delete',
            NPNNumber__c='17595388');
        insert npn;

        Test.startTest();
        delete npn; // Should fire After Delete and enqueue NIPRRemoveTargets
        Test.stopTest(); // Executes the queued job
    }
}