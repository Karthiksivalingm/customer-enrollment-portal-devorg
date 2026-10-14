@isTest
public class TESTTouchpointAPI {
    @isTest
    private static void testTouchpointAPI() {
        List<String> testtext = new List<String>();
        testtext.add('59109-RID-{7618||somevalue}{7619||othervalue}');
        testtext.add('59109-RID-{7618||somevalue}{7619||othervalue}');
        testtext.add('59109-RID-{7618||somevalue}{7619||othervalue}');
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());
        Integer callouts = Limits.getCallouts();
        TouchpointAPIInvocable.invokeapexcallout(testtext);
        Test.stopTest();
    }
}