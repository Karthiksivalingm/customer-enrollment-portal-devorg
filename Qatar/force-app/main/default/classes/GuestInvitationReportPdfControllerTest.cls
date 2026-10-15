@isTest
private class GuestInvitationReportPdfControllerTest {

    private static Invitation__c createEvent() {
        Invitation__c evt = new Invitation__c(
            Name = 'Invitation PDF Test Event',
            Event_Start_Date__c = Date.today(),
            Event_End_Date__c = Date.today().addDays(1)
        );
        insert evt;
        return evt;
    }

    @isTest
    static void testConstructorLoadsReportAndStripsHtml() {
        Invitation__c evt = createEvent();
        Contact mainContact = new Contact(FirstName = 'Test', LastName = 'InviteMain');
        insert mainContact;
        Contact accompanyingContact = new Contact(FirstName = 'Test', LastName = 'InvitePlusOne');
        insert accompanyingContact;

        String tier = GuestCategoryReportController.getGuestTierValues().isEmpty()
            ? null : GuestCategoryReportController.getGuestTierValues()[0];
        String invitationStatus = GuestCategoryReportController.getInvitationStatusValues().isEmpty()
            ? null : GuestCategoryReportController.getInvitationStatusValues()[0];
        System.assertNotEquals(null, tier, 'Test org must have at least one active Guest Tier value.');
        System.assertNotEquals(null, invitationStatus, 'Test org must have at least one active Invitation Status value.');

        Guest_List__c mainGuest = new Guest_List__c(
            Invitation__c = evt.Id,
            Contact__c = mainContact.Id,
            Guest_Tiers__c = tier,
            Invitation_Status__c = invitationStatus,
            Invitation_Tier__c = tier,
            Source__c = '<i>Website</i>',
            Bio__c = '<p>Bio &amp; details</p>',
           // Reason_for_Inviting__c = '<a href="http://example.com">Click here</a>',
            Guest_Category__c = 'Speaker',
            Inbound_Date_Time__c = DateTime.now(),
            Outbound_Date_Time__c = DateTime.now().addDays(1)
        );
        insert mainGuest;

        Guest_List__c accompanyingGuest = new Guest_List__c(
            Invitation__c = evt.Id,
            Contact__c = accompanyingContact.Id,
            Guest_Tiers__c = tier,
            Invitation_Status__c = invitationStatus,
            Invitation_Tier__c = tier,
            Relationship_to__c = '<span>Spouse</span>'
        );
        insert accompanyingGuest;

        HE_Request__c req = new HE_Request__c(Guest_List__c = mainGuest.Id);
        insert req;

        PageReference pageRef = Page.GuestInvitationReportPdf;
        pageRef.getParameters().put('eventId', evt.Id);
        pageRef.getParameters().put('tier', tier);
        pageRef.getParameters().put('status', invitationStatus);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        GuestInvitationReportPdfController controller = new GuestInvitationReportPdfController();
        Test.stopTest();

        System.assertEquals(null, controller.errorMessage, 'No error expected on a valid request.');
        System.assertNotEquals(null, controller.report);
        System.assertEquals('Invitation PDF Test Event', controller.report.eventName);
        // registrationStatus on the wrapper carries invitation status for header display
        System.assertEquals(invitationStatus, controller.report.registrationStatus);
        System.assertEquals(2, controller.report.guests.size());

        GuestInvitationReportPdfController.PdfGuestRow mainRow;
        GuestInvitationReportPdfController.PdfGuestRow accompanyingRow;
        for (GuestInvitationReportPdfController.PdfGuestRow row : controller.report.guests) {
            if (row.fullName == mainContact.Name) {
                mainRow = row;
            } else if (row.fullName == accompanyingContact.Name) {
                accompanyingRow = row;
            }
        }

        
       
       
    }

    @isTest
    static void testConstructorHandlesInvalidEventIdGracefully() {
        PageReference pageRef = Page.GuestInvitationReportPdf;
        pageRef.getParameters().put('eventId', 'not-a-valid-id');
        pageRef.getParameters().put('tier', 'Local');
        pageRef.getParameters().put('status', 'Accepted');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        GuestInvitationReportPdfController controller = new GuestInvitationReportPdfController();
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

        PageReference pageRef = Page.GuestInvitationReportPdf;
        pageRef.getParameters().put('eventId', deletedId);
        pageRef.getParameters().put('tier', 'Local');
        pageRef.getParameters().put('status', 'Accepted');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        GuestInvitationReportPdfController controller = new GuestInvitationReportPdfController();
        Test.stopTest();

        System.assertEquals(null, controller.report, 'Report should not be populated when the event no longer exists.');
        System.assertNotEquals(null, controller.errorMessage);
    }

    @isTest
    static void testConstructorHandlesNoMatchingGuests() {
        Invitation__c evt = createEvent();
        String tier = GuestCategoryReportController.getGuestTierValues().isEmpty()
            ? null : GuestCategoryReportController.getGuestTierValues()[0];
        String invitationStatus = GuestCategoryReportController.getInvitationStatusValues().isEmpty()
            ? null : GuestCategoryReportController.getInvitationStatusValues()[0];

        PageReference pageRef = Page.GuestInvitationReportPdf;
        pageRef.getParameters().put('eventId', evt.Id);
        pageRef.getParameters().put('tier', tier);
        pageRef.getParameters().put('status', invitationStatus);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        GuestInvitationReportPdfController controller = new GuestInvitationReportPdfController();
        Test.stopTest();

        System.assertEquals(null, controller.errorMessage);
        System.assertNotEquals(null, controller.report);
        System.assertEquals(0, controller.report.guests.size());
    }

    // ---- Coverage added 2026-08: the LWC's Download PDF button now calls
    //      getPdfBase64 imperatively instead of just navigating to a URL (see
    //      guestInvitationReport.js) — this method previously had no test at all. ----
    @isTest
    static void testGetPdfBase64ReturnsDecodableBase64() {
        Invitation__c evt = createEvent();
        Contact guestContact = new Contact(FirstName = 'Test', LastName = 'DownloadGuest');
        insert guestContact;

        String tier = GuestCategoryReportController.getGuestTierValues().isEmpty()
            ? null : GuestCategoryReportController.getGuestTierValues()[0];
        String invitationStatus = GuestCategoryReportController.getInvitationStatusValues().isEmpty()
            ? null : GuestCategoryReportController.getInvitationStatusValues()[0];
        System.assertNotEquals(null, tier, 'Test org must have at least one active Guest Tier value.');
        System.assertNotEquals(null, invitationStatus, 'Test org must have at least one active Invitation Status value.');

        insert new Guest_List__c(
            Invitation__c = evt.Id,
            Contact__c = guestContact.Id,
            Guest_Tiers__c = tier,
            Invitation_Status__c = invitationStatus,
            Invitation_Tier__c = tier
        );

        Test.startTest();
        // Test.isRunningTest() is true here, so the controller takes the stub-Blob
        // branch rather than calling getContentAsPDF() (unsupported in test context).
        String base64Pdf = GuestInvitationReportPdfController.getPdfBase64(evt.Id, tier, invitationStatus);
        Test.stopTest();

        System.assertNotEquals(null, base64Pdf, 'getPdfBase64 should always return a value, even in test context.');
        System.assert(base64Pdf.length() > 0, 'Returned base64 string should not be empty.');
        // Confirms the return value is actually valid base64 the LWC can decode into a Blob,
        // not just a non-null string.
        Blob decoded = EncodingUtil.base64Decode(base64Pdf);
        System.assertEquals('Test PDF content', decoded.toString());
    }

    @isTest
    static void testGetPdfBase64NormalizesBlankFiltersToAll() {
        Invitation__c evt = createEvent();

        Test.startTest();
        // Blank tier/status should normalize to ALL rather than error, same as the
        // constructor's normalizeFilter behavior for the navigated-to VF page.
        String base64Pdf = GuestInvitationReportPdfController.getPdfBase64(evt.Id, null, null);
        Test.stopTest();

        System.assertNotEquals(null, base64Pdf);
        System.assert(base64Pdf.length() > 0);
    }

    // ---- Coverage added 2026-08: PdfReport.guestCount and photosOmittedDueToSize
    //      were added for the "Total Guests" header line and photo-omission signal,
    //      but nothing asserted them. ----
    @isTest
    static void testReportExposesGuestCountAndPhotosOmittedFlag() {
        Invitation__c evt = createEvent();
        Contact contactOne = new Contact(FirstName = 'Test', LastName = 'CountGuestOne');
        Contact contactTwo = new Contact(FirstName = 'Test', LastName = 'CountGuestTwo');
        insert new List<Contact>{ contactOne, contactTwo };

        String tier = GuestCategoryReportController.getGuestTierValues().isEmpty()
            ? null : GuestCategoryReportController.getGuestTierValues()[0];
        String invitationStatus = GuestCategoryReportController.getInvitationStatusValues().isEmpty()
            ? null : GuestCategoryReportController.getInvitationStatusValues()[0];
        System.assertNotEquals(null, tier, 'Test org must have at least one active Guest Tier value.');
        System.assertNotEquals(null, invitationStatus, 'Test org must have at least one active Invitation Status value.');

        insert new List<Guest_List__c>{
            new Guest_List__c(
                Invitation__c = evt.Id,
                Contact__c = contactOne.Id,
                Guest_Tiers__c = tier,
                Invitation_Status__c = invitationStatus,
                Invitation_Tier__c = tier
            ),
            new Guest_List__c(
                Invitation__c = evt.Id,
                Contact__c = contactTwo.Id,
                Guest_Tiers__c = tier,
                Invitation_Status__c = invitationStatus,
                Invitation_Tier__c = tier
            )
        };

        PageReference pageRef = Page.GuestInvitationReportPdf;
        pageRef.getParameters().put('eventId', evt.Id);
        pageRef.getParameters().put('tier', tier);
        pageRef.getParameters().put('status', invitationStatus);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        GuestInvitationReportPdfController controller = new GuestInvitationReportPdfController();
        Test.stopTest();

        System.assertEquals(null, controller.errorMessage);
        System.assertNotEquals(null, controller.report);
        System.assertEquals(2, controller.report.guests.size());
        System.assertEquals(controller.report.guests.size(), controller.report.guestCount,
            'guestCount should always match the actual number of rows in the report.');
        // Neither contact has a photo attachment, so nothing should be flagged as omitted.
        System.assertEquals(false, controller.report.photosOmittedDueToSize);
    }
}