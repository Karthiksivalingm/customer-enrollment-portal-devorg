@isTest
public class NiprSSNsearchFlowInvokerTest {
    
    private static Contact createTestContact() {
        Contact con = new Contact(
            LastName = 'TestContact',
            FirstName = 'Unit',
            Email = 'unit.test@example.com'
        );
        insert con;
        return con;
    }
    
    @isTest
    static void testInvokeSSNSearchWithMock() {
        // Arrange: Create a Contact
        Contact con = createTestContact();
        
        // Prepare request wrapper
        NiprSSNsearchFlowInvoker.RequestWrapper req = new NiprSSNsearchFlowInvoker.RequestWrapper();
        req.contactId = con.Id;
        
        List<NiprSSNsearchFlowInvoker.RequestWrapper> reqList = new List<NiprSSNsearchFlowInvoker.RequestWrapper>();
        reqList.add(req);
        
        // Set the mock for HTTP callout
        Test.setMock(HttpCalloutMock.class, new NiprSSNsearchMock());
        
        Test.startTest();
        // Act: Call the invocable method
        NiprSSNsearchFlowInvoker.invokeSSNSearch(reqList);
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, reqList.size(), 'One request should be processed');
        System.assertEquals(con.Id, reqList[0].contactId, 'Contact Id should match');
    }
}