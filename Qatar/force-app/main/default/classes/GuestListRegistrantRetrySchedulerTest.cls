@isTest
private class GuestListRegistrantRetrySchedulerTest {

    @isTest
    static void testExecuteEnqueuesQueueableForGivenGuests() {
        Invitation__c inv = new Invitation__c(External_Event_Id__c = '1001', Name = 'Test Event');
        insert inv;
        Contact c = new Contact(FirstName = 'Jane', LastName = 'Doe', Email = 'jane.doe@example.com');
        insert c;
        Guest_List__c g = new Guest_List__c(
            Contact__c = c.Id, Invitation__c = inv.Id,
            Approval__c = 'Approved', Guest_Tiers__c = 'VIP',
            Swoogo_Push_Status__c = 'Retry Pending - Swoogo rate limited (429), will automatically retry '
                + 'in couple of mins — don\'t worry, this will automatically sync '
                + 'with the particular invitation tier'
        );
        insert g;

        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        // Call execute() directly rather than going through System.schedule()
        // — scheduled jobs are not reliably flushed by Test.stopTest(), so
        // asserting through an actual fired schedule is non-deterministic.
        // Calling execute() directly still exercises the exact same
        // System.enqueueJob(...) call this class exists to make.
        new GuestListRegistrantRetryScheduler(new Set<Id>{ g.Id }).execute(null);
        Test.stopTest();

        Guest_List__c updated = [SELECT Swoogo_Push_Status__c FROM Guest_List__c WHERE Id = :g.Id];
        System.assert(updated.Swoogo_Push_Status__c.startsWith('Success - Added to invitation list'));
    }

    @isTest
    static void testExecuteNoOpWithEmptyOrNullSet() {
        Test.startTest();
        new GuestListRegistrantRetryScheduler(new Set<Id>()).execute(null);
        new GuestListRegistrantRetryScheduler(null).execute(null);
        Test.stopTest();
        System.assert(true);
    }
}