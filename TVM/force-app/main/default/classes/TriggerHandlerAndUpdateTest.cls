@isTest
public class TriggerHandlerAndUpdateTest {
    
    @isTest
    static void testTriggerHandlerAndUpdate() {
        // Access TriggerHandler variable
        System.assertEquals(true, TriggerHandler.isFirstTime, 'Default should be true');

        // Change value to cover assignment
        TriggerHandler.isFirstTime = false;
        System.assertEquals(false, TriggerHandler.isFirstTime);

        // Access TriggerUpdate variable
        System.assertEquals(false, TriggerUpdate.firstcall, 'Default should be false');

        // Change value to cover assignment
        TriggerUpdate.firstcall = true;
        System.assertEquals(true, TriggerUpdate.firstcall);
    }
}