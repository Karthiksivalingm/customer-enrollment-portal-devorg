@isTest
private class GuestCategoryReportPdfControllerTest {

    private static Invitation__c createEvent() {
        Invitation__c evt = new Invitation__c(
            Name = 'PDF Test Event',
            Event_Start_Date__c = Date.today(),
            Event_End_Date__c = Date.today().addDays(1)
        );
        insert evt;
        return evt;
    }

    @isTest
    static void testConstructorLoadsReportAndStripsHtml() {
        Invitation__c evt = createEvent();
        Contact c = new Contact(FirstName = 'Test', LastName = 'PdfGuest');
        insert c;

        String tier = GuestCategoryReportController.getGuestTierValues().isEmpty()
            ? null : GuestCategoryReportController.getGuestTierValues()[0];
        String status = GuestCategoryReportController.getRegistrationStatusValues().isEmpty()
            ? null : GuestCategoryReportController.getRegistrationStatusValues()[0];
        System.assertNotEquals(null, tier, 'Test org must have at least one active Guest Tier value.');
        System.assertNotEquals(null, status, 'Test org must have at least one active RSVP value.');

        Guest_List__c guest = new Guest_List__c(
            Invitation__c = evt.Id,
            Contact__c = c.Id,
            Guest_Tiers__c = tier,
            RSVP__c = status,
            Reason_for_Inviting__c = '<a href="http://example.com">Click here</a>'
        );
        insert guest;

        PageReference pageRef = Page.GuestCategoryReportPdf;
        pageRef.getParameters().put('eventId', evt.Id);
        pageRef.getParameters().put('tier', tier);
        pageRef.getParameters().put('status', status);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        GuestCategoryReportPdfController controller = new GuestCategoryReportPdfController();
        Test.stopTest();

        System.assertEquals(null, controller.errorMessage, 'No error expected on a valid request.');
        System.assertNotEquals(null, controller.report);
        System.assertEquals('PDF Test Event', controller.report.eventName);
        System.assertEquals(1, controller.report.guests.size());

        GuestCategoryReportPdfController.PdfGuestRow row = controller.report.guests[0];
        System.assertEquals('Click here', row.reasonForAttendance, 'Anchor tag should be stripped, leaving only link text.');
    }

    @isTest
    static void testConstructorHandlesInvalidEventIdGracefully() {
        PageReference pageRef = Page.GuestCategoryReportPdf;
        pageRef.getParameters().put('eventId', 'not-a-valid-id');
        pageRef.getParameters().put('tier', 'Local');
        pageRef.getParameters().put('status', 'Accepted');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        GuestCategoryReportPdfController controller = new GuestCategoryReportPdfController();
        Test.stopTest();

        System.assertEquals(null, controller.report, 'Report should not be populated when an exception occurs.');
        System.assertNotEquals(null, controller.errorMessage, 'An error message should be set.');
        System.assert(controller.errorMessage.startsWith('Unable to load report:'));
    }

    @isTest
    static void testConstructorHandlesMissingEventGracefully() {
        // Build a syntactically valid but non-existent Invitation__c Id by inserting then deleting a record.
        Invitation__c evt = new Invitation__c(Name = 'Temp', Event_Start_Date__c = Date.today());
        insert evt;
        Id deletedId = evt.Id;
        delete evt;

        PageReference pageRef = Page.GuestCategoryReportPdf;
        pageRef.getParameters().put('eventId', deletedId);
        pageRef.getParameters().put('tier', 'Local');
        pageRef.getParameters().put('status', 'Accepted');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        GuestCategoryReportPdfController controller = new GuestCategoryReportPdfController();
        Test.stopTest();

        System.assertEquals(null, controller.report, 'Report should not be populated when the event no longer exists.');
        System.assertNotEquals(null, controller.errorMessage);
    }
}