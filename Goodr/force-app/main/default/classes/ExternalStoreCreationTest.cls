@IsTest
public class ExternalStoreCreationTest {

    @TestSetup
    static void createTestLead() {
        Lead testLead = new Lead(
            LastName = 'TestLead',
            Company = 'Test Company',
            Status = 'Open - Not Contacted',
            Email = 'testlead@example.com',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert testLead;
    }
    
    @IsTest
    static void testCreateStoresFromTypeformResponse_US_Simple() {
        Lead l = new Lead(
            LastName = 'SimpleLead', 
            Company = 'TestCo',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert l;
    
        List<String> refs = new List<String>{
            '638fe573-1acb-477b-ace9-f0fb9fc6e1fe', // street
            '10065097-d56e-41ab-9e03-5ff0c9b381a4', // city
            'aae6b704-76e4-4c45-92a7-5e89bb563cc0', // state
            'f034fdc2-0e03-48c8-8511-eb9d9733c12d', // zip
            '759d3a08-2f34-4c6b-9e58-b7e294315605'  // area
        };
    
        List<Object> answers = new List<Object>{
            new Map<String, Object>{ 'field' => new Map<String, Object>{ 'ref' => refs[0] }, 'text' => 'Main St 1' },
            new Map<String, Object>{ 'field' => new Map<String, Object>{ 'ref' => refs[1] }, 'text' => 'Springfield' },
            new Map<String, Object>{ 'field' => new Map<String, Object>{ 'ref' => refs[2] }, 'text' => 'IL' },
            new Map<String, Object>{ 'field' => new Map<String, Object>{ 'ref' => refs[3] }, 'text' => '62704' },
            new Map<String, Object>{ 'field' => new Map<String, Object>{ 'ref' => refs[4] }, 'number' => 1200 }
        };
        Map<String, Object> latestResponse = new Map<String, Object>{ 'answers' => answers };
    
        List<Store__c> stores = new List<Store__c>();
        Test.startTest();
        ExternalStoreCreation.createStoresFromTypeformResponse(latestResponse, l.Id, stores, 'S0t1jVLc');
        Test.stopTest();
    
        System.assertEquals(1, stores.size(), 'Store should be created');
        System.assertEquals('Main St 1, Springfield, IL, 62704, US', stores[0].Address__c);
        System.assertEquals(1200, stores[0].Store_Square_Footage__c);
	}

    @IsTest
    static void testCreateStoresFromTypeformResponse_NoAnswers() {
        Map<String, Object> latestResponse = new Map<String, Object>{};
        List<Store__c> storesToInsert = new List<Store__c>();

        Test.startTest();
        ExternalStoreCreation.createStoresFromTypeformResponse(latestResponse, '001xxxxxxxxxxxx', storesToInsert, 'someFormId');
        Test.stopTest();

        System.assertEquals(0, storesToInsert.size(), 'Stores should not be created');
    }
}