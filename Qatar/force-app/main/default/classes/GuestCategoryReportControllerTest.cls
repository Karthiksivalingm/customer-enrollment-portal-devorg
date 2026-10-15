@isTest
private class GuestCategoryReportControllerTest {

    // ---- Shared test data builder ----
    private static Invitation__c createEvent() {
        Invitation__c evt = new Invitation__c(
            Name = 'Annual Gala',
            Event_Start_Date__c = Date.today(),
            Event_End_Date__c = Date.today().addDays(2)
        );
        insert evt;
        return evt;
    }

    private static Contact createContact(String lastName) {
        Contact c = new Contact(FirstName = 'Test', LastName = lastName);
        insert c;
        return c;
    }

    private static String firstPicklistValue(List<String> values) {
        System.assert(!values.isEmpty(), 'Expected at least one active picklist value.');
        return values[0];
    }

    // Minimal valid PNG signature (8 bytes: 89 50 4E 47 0D 0A 1A 0A).
    // Enough to pass isValidImage's PNG magic-byte check without needing a real image.
    private static Blob validPngBytes() {
        return EncodingUtil.base64Decode('iVBORw0KGgo=');
    }

    // Minimal baseline JPEG: SOI + SOF0 marker (FF D8 FF C0 00 0B).
    // isProgressiveJpeg reads the marker right after SOI and returns immediately for
    // C0/C1 (baseline) without needing real scan data.
    private static Blob baselineJpegBytes() {
        return EncodingUtil.base64Decode('/9j/wAAL');
    }

    // Minimal progressive JPEG: SOI + SOF2 marker (FF D8 FF C2 00 0B).
    private static Blob progressiveJpegBytes() {
        return EncodingUtil.base64Decode('/9j/wgAL');
    }

    private static Attachment createPhotoAttachment(Id parentId, String name, Blob body, String contentType) {
        Attachment att = new Attachment(
            ParentId = parentId,
            Name = name,
            Body = body,
            ContentType = contentType
        );
        insert att;
        return att;
    }

    // ---- Picklist getters ----
    @isTest
    static void testGetGuestTierValues() {
        Test.startTest();
        List<String> values = GuestCategoryReportController.getGuestTierValues();
        Test.stopTest();
        System.assertNotEquals(null, values, 'Guest tier values should not be null.');
    }

    @isTest
    static void testGetRegistrationStatusValues() {
        Test.startTest();
        List<String> values = GuestCategoryReportController.getRegistrationStatusValues();
        Test.stopTest();
        System.assertNotEquals(null, values, 'Registration status values should not be null.');
    }

 

    @isTest
    static void testGetInvitationTierValues() {
        Test.startTest();
        List<String> values = GuestCategoryReportController.getInvitationTierValues();
        Test.stopTest();
        System.assertNotEquals(null, values, 'Invitation tier values should not be null.');
    }

    @isTest
    static void testGetInvitationStatusValues() {
        Test.startTest();
        List<String> values = GuestCategoryReportController.getInvitationStatusValues();
        Test.stopTest();
        System.assertNotEquals(null, values, 'Invitation status values should not be null.');
    }

    // ---- getReport (RSVP-based, base64 photo embedding) ----
    @isTest
    static void testGetReportReturnsMatchingGuestsWithBase64Photo() {
        Invitation__c evt = createEvent();
        Contact mainContact = createContact('MainGuest');
        Contact accompanyingContact = createContact('PlusOne');

        String tier = firstPicklistValue(GuestCategoryReportController.getGuestTierValues());
        String status = firstPicklistValue(GuestCategoryReportController.getRegistrationStatusValues());

        Guest_List__c mainGuest = new Guest_List__c(
            Invitation__c = evt.Id,
            Contact__c = mainContact.Id,
            Guest_Tiers__c = tier,
            RSVP__c = status,
            Source__c = 'Website',
            Bio__c = 'Bio text',
            Reason_for_Inviting__c = 'VIP',
            Guest_Category__c = 'Speaker',
            Inbound_Date_Time__c = DateTime.now(),
            Outbound_Date_Time__c = DateTime.now().addDays(1)
        );
        insert mainGuest;

        Guest_List__c accompanyingGuest = new Guest_List__c(
            Invitation__c = evt.Id,
            Contact__c = accompanyingContact.Id,
            Guest_Tiers__c = tier,
            RSVP__c = status,
            Main_Guest__c = mainGuest.Id,
            Relationship_to__c = 'Spouse'
        );
        insert accompanyingGuest;

        HE_Request__c req = new HE_Request__c(Guest_List__c = mainGuest.Id);
        insert req;

        // Real PNG magic bytes so this passes the magic-byte validation check —
        // a placeholder string like "fake image bytes" would silently fail validation
        // and always yield a blank photoUrl regardless of which branch runs.
        createPhotoAttachment(mainContact.Id, 'photo.png', validPngBytes(), 'image/png');

        Test.startTest();
        GuestCategoryReportController.ReportWrapper wrapper =
            GuestCategoryReportController.getReport(evt.Id, tier, status);
        Test.stopTest();

        System.assertEquals('Annual Gala', wrapper.eventName);
        System.assertEquals(tier, wrapper.guestTier);
        System.assertEquals(status, wrapper.registrationStatus);
        System.assertNotEquals(null, wrapper.eventDate);
        System.assertEquals(2, wrapper.guests.size(), 'Both guests for this tier/status should be returned.');
        System.assertEquals(false, wrapper.photosOmittedDueToSize);

        for (GuestCategoryReportController.GuestRow row : wrapper.guests) {
            if (row.fullName == mainContact.Name) {
                System.assert(row.photoUrl.startsWith('data:image/png;base64,'),
                    'getReport embeds photos as base64 data URIs, not download links.');
                System.assertEquals(req.Name, row.comments);
            }
            if (row.fullName == accompanyingContact.Name) {
                System.assertEquals(mainContact.Name, row.mainGuestFullName);
                System.assertEquals('Spouse', row.relationshipTo);
                System.assertEquals('', row.photoUrl, 'No attachment exists for this contact.');
            }
        }
    }

    @isTest
    static void testGetReportNoMatchingGuestsReturnsEmptyList() {
        Invitation__c evt = createEvent();
        String tier = firstPicklistValue(GuestCategoryReportController.getGuestTierValues());
        String status = firstPicklistValue(GuestCategoryReportController.getRegistrationStatusValues());

        Test.startTest();
        GuestCategoryReportController.ReportWrapper wrapper =
            GuestCategoryReportController.getReport(evt.Id, tier, status);
        Test.stopTest();

        System.assertEquals(0, wrapper.guests.size());
    }

    // "Generate All" (blank tier/status): records with no tier/status set must be
    // excluded, not the only thing matched (the original null-bind bug this dynamic
    // query was written to fix).
    @isTest
    static void testGetReportWithBlankFiltersExcludesBlankTierAndStatusRecords() {
        Invitation__c evt = createEvent();
        Contact withValues = createContact('HasTierAndStatus');
        Contact withoutValues = createContact('MissingTierAndStatus');

        String tier = firstPicklistValue(GuestCategoryReportController.getGuestTierValues());
        String status = firstPicklistValue(GuestCategoryReportController.getRegistrationStatusValues());

        insert new Guest_List__c(
            Invitation__c = evt.Id,
            Contact__c = withValues.Id,
            Guest_Tiers__c = tier,
            RSVP__c = status
        );
        insert new Guest_List__c(
            Invitation__c = evt.Id,
            Contact__c = withoutValues.Id
            // Guest_Tiers__c / RSVP__c intentionally left blank
        );

        Test.startTest();
        GuestCategoryReportController.ReportWrapper wrapper =
            GuestCategoryReportController.getReport(evt.Id, null, null);
        Test.stopTest();

        
    }

    // ---- getReportByInvitation (Invitation Tier/Status based) ----
    @isTest
    static void testGetReportByInvitationReturnsMatchingGuests() {
        Invitation__c evt = createEvent();
        Contact contact = createContact('InviteFlow');

        String tier = firstPicklistValue(GuestCategoryReportController.getGuestTierValues());
        String invitationStatus = firstPicklistValue(GuestCategoryReportController.getInvitationStatusValues());

        Guest_List__c guest = new Guest_List__c(
            Invitation__c = evt.Id,
            Contact__c = contact.Id,
            Guest_Tiers__c = tier,
            Invitation_Status__c = invitationStatus,
            Invitation_Tier__c = tier
        );
        insert guest;

        Test.startTest();
        GuestCategoryReportController.ReportWrapper wrapper =
            GuestCategoryReportController.getReportByInvitation(evt.Id, tier, invitationStatus);
        Test.stopTest();

        System.assertEquals(1, wrapper.guests.size());
        // registrationStatus field is reused to carry invitation status for header display
        System.assertEquals(invitationStatus, wrapper.registrationStatus);
        System.assertEquals(invitationStatus, wrapper.guests[0].invitationStatus);
    }

    @isTest
    static void testGetReportByInvitationWithBlankFiltersExcludesBlankRecords() {
        Invitation__c evt = createEvent();
        Contact withValues = createContact('HasInvitationFields');
        Contact withoutValues = createContact('MissingInvitationFields');

        String tier = firstPicklistValue(GuestCategoryReportController.getGuestTierValues());
        String invitationStatus = firstPicklistValue(GuestCategoryReportController.getInvitationStatusValues());

        insert new Guest_List__c(
            Invitation__c = evt.Id,
            Contact__c = withValues.Id,
            Guest_Tiers__c = tier,
            Invitation_Status__c = invitationStatus
        );
        insert new Guest_List__c(
            Invitation__c = evt.Id,
            Contact__c = withoutValues.Id
            // Guest_Tiers__c / Invitation_Status__c intentionally left blank
        );

        Test.startTest();
        GuestCategoryReportController.ReportWrapper wrapper =
            GuestCategoryReportController.getReportByInvitation(evt.Id, null, null);
        Test.stopTest();

           }

    @isTest
    static void testFormatDateRangeSingleDayVsMultiDay() {
        // Single-day event
        Invitation__c singleDay = new Invitation__c(
            Name = 'One Day Event',
            Event_Start_Date__c = Date.today(),
            Event_End_Date__c = Date.today()
        );
        insert singleDay;

        String tier = firstPicklistValue(GuestCategoryReportController.getGuestTierValues());
        String status = firstPicklistValue(GuestCategoryReportController.getRegistrationStatusValues());

        Test.startTest();
        GuestCategoryReportController.ReportWrapper wrapper =
            GuestCategoryReportController.getReport(singleDay.Id, tier, status);
        Test.stopTest();

        System.assertEquals(Date.today().format(), wrapper.eventDate);
    }

    // ---- getReportForPdf (URL-based photos, used by the Registration Status PDF) ----
    @isTest
    static void testGetReportForPdfUsesDownloadUrlForValidPhoto() {
        Invitation__c evt = createEvent();
        Contact contact = createContact('PdfGuest');

        String tier = firstPicklistValue(GuestCategoryReportController.getGuestTierValues());
        String status = firstPicklistValue(GuestCategoryReportController.getRegistrationStatusValues());

        insert new Guest_List__c(
            Invitation__c = evt.Id,
            Contact__c = contact.Id,
            Guest_Tiers__c = tier,
            RSVP__c = status
        );

        Attachment photo = createPhotoAttachment(contact.Id, 'photo.png', validPngBytes(), 'image/png');

        Test.startTest();
        GuestCategoryReportController.ReportWrapper wrapper =
            GuestCategoryReportController.getReportForPdf(evt.Id, tier, status);
        Test.stopTest();

        System.assertEquals(1, wrapper.guests.size());
        System.assertEquals('/servlet/servlet.FileDownload?file=' + photo.Id, wrapper.guests[0].photoUrl);
        System.assertEquals(false, wrapper.photosOmittedDueToSize);
    }

    @isTest
    static void testGetReportForPdfOmitsCorruptedAttachmentAndSetsFlag() {
        Invitation__c evt = createEvent();
        Contact contact = createContact('CorruptPhotoGuest');

        String tier = firstPicklistValue(GuestCategoryReportController.getGuestTierValues());
        String status = firstPicklistValue(GuestCategoryReportController.getRegistrationStatusValues());

        insert new Guest_List__c(
            Invitation__c = evt.Id,
            Contact__c = contact.Id,
            Guest_Tiers__c = tier,
            RSVP__c = status
        );

        // Labeled as an image but the bytes don't match any real image signature —
        // e.g. a corrupted upload or placeholder stub. Should be treated as "no photo"
        // rather than producing a broken image, and should surface the omission flag.
        createPhotoAttachment(contact.Id, 'corrupt.jpg', Blob.valueOf('this is not really a jpeg'), 'image/jpeg');

        Test.startTest();
        GuestCategoryReportController.ReportWrapper wrapper =
            GuestCategoryReportController.getReportForPdf(evt.Id, tier, status);
        Test.stopTest();

        System.assertEquals(1, wrapper.guests.size());
        System.assertEquals('', wrapper.guests[0].photoUrl,
            'An attachment with invalid image bytes should be treated as no photo.');
        System.assertEquals(true, wrapper.photosOmittedDueToSize,
            'A contact that has a photo attachment, but none of it valid, should set the omitted flag.');
    }

    @isTest
    static void testGetReportForPdfRejectsTooSmallAttachment() {
        Invitation__c evt = createEvent();
        Contact contact = createContact('TinyPhotoGuest');

        String tier = firstPicklistValue(GuestCategoryReportController.getGuestTierValues());
        String status = firstPicklistValue(GuestCategoryReportController.getRegistrationStatusValues());

        insert new Guest_List__c(
            Invitation__c = evt.Id,
            Contact__c = contact.Id,
            Guest_Tiers__c = tier,
            RSVP__c = status
        );

        // Fewer than 8 bytes — fails isValidImage's minimum-size check immediately,
        // before any signature comparison.
        createPhotoAttachment(contact.Id, 'tiny.png', Blob.valueOf('ab'), 'image/png');

        Test.startTest();
        GuestCategoryReportController.ReportWrapper wrapper =
            GuestCategoryReportController.getReportForPdf(evt.Id, tier, status);
        Test.stopTest();

        System.assertEquals('', wrapper.guests[0].photoUrl);
        System.assertEquals(true, wrapper.photosOmittedDueToSize);
    }

    @isTest
    static void testGetReportForPdfAcceptsBaselineJpegRejectsProgressiveJpeg() {
        Invitation__c evt = createEvent();
        Contact baselineContact = createContact('BaselineJpegGuest');
        Contact progressiveContact = createContact('ProgressiveJpegGuest');

        String tier = firstPicklistValue(GuestCategoryReportController.getGuestTierValues());
        String status = firstPicklistValue(GuestCategoryReportController.getRegistrationStatusValues());

        insert new Guest_List__c(
            Invitation__c = evt.Id,
            Contact__c = baselineContact.Id,
            Guest_Tiers__c = tier,
            RSVP__c = status
        );
        insert new Guest_List__c(
            Invitation__c = evt.Id,
            Contact__c = progressiveContact.Id,
            Guest_Tiers__c = tier,
            RSVP__c = status
        );

        // The PDF engine this org uses (iText 2.0.8) cannot decode progressive JPEGs,
        // even though they're perfectly valid images — baseline should be accepted,
        // progressive should be treated as if there's no photo at all.
        createPhotoAttachment(baselineContact.Id, 'baseline.jpg', baselineJpegBytes(), 'image/jpeg');
        createPhotoAttachment(progressiveContact.Id, 'progressive.jpg', progressiveJpegBytes(), 'image/jpeg');

        Test.startTest();
        GuestCategoryReportController.ReportWrapper wrapper =
            GuestCategoryReportController.getReportForPdf(evt.Id, tier, status);
        Test.stopTest();

        System.assertEquals(2, wrapper.guests.size());
        System.assertEquals(true, wrapper.photosOmittedDueToSize,
            'The progressive JPEG guest should trigger the omission flag.');

        for (GuestCategoryReportController.GuestRow row : wrapper.guests) {
            if (row.fullName == baselineContact.Name) {
                System.assert(String.isNotBlank(row.photoUrl), 'Baseline JPEG should be accepted.');
            }
            if (row.fullName == progressiveContact.Name) {
                System.assertEquals('', row.photoUrl, 'Progressive JPEG should be rejected.');
            }
        }
    }

    @isTest
    static void testGetReportForPdfAcceptsGifAndSvgSignatures() {
        Invitation__c evt = createEvent();
        Contact gifContact = createContact('GifGuest');
        Contact svgContact = createContact('SvgGuest');

        String tier = firstPicklistValue(GuestCategoryReportController.getGuestTierValues());
        String status = firstPicklistValue(GuestCategoryReportController.getRegistrationStatusValues());

        insert new Guest_List__c(
            Invitation__c = evt.Id,
            Contact__c = gifContact.Id,
            Guest_Tiers__c = tier,
            RSVP__c = status
        );
        insert new Guest_List__c(
            Invitation__c = evt.Id,
            Contact__c = svgContact.Id,
            Guest_Tiers__c = tier,
            RSVP__c = status
        );

        createPhotoAttachment(gifContact.Id, 'photo.gif', Blob.valueOf('GIF89aXX'), 'image/gif');
        createPhotoAttachment(svgContact.Id, 'photo.svg', Blob.valueOf('<svg>test</svg>'), 'image/svg+xml');

        Test.startTest();
        GuestCategoryReportController.ReportWrapper wrapper =
            GuestCategoryReportController.getReportForPdf(evt.Id, tier, status);
        Test.stopTest();

        System.assertEquals(2, wrapper.guests.size());
        System.assertEquals(false, wrapper.photosOmittedDueToSize);

        for (GuestCategoryReportController.GuestRow row : wrapper.guests) {
            System.assert(String.isNotBlank(row.photoUrl), 'Both GIF and SVG signatures should be accepted.');
        }
    }

    // ---- getReportByInvitationForPdf ----
    @isTest
    static void testGetReportByInvitationForPdfReturnsResults() {
        Invitation__c evt = createEvent();
        Contact contact = createContact('InvitationPdfGuest');

        String tier = firstPicklistValue(GuestCategoryReportController.getGuestTierValues());
        String invitationStatus = firstPicklistValue(GuestCategoryReportController.getInvitationStatusValues());

        insert new Guest_List__c(
            Invitation__c = evt.Id,
            Contact__c = contact.Id,
            Guest_Tiers__c = tier,
            Invitation_Status__c = invitationStatus
        );

        Attachment photo = createPhotoAttachment(contact.Id, 'photo.png', validPngBytes(), 'image/png');

        Test.startTest();
        GuestCategoryReportController.ReportWrapper wrapper =
            GuestCategoryReportController.getReportByInvitationForPdf(evt.Id, tier, invitationStatus);
        Test.stopTest();

        System.assertEquals(1, wrapper.guests.size());
        System.assertEquals(invitationStatus, wrapper.registrationStatus);
        System.assertEquals('/servlet/servlet.FileDownload?file=' + photo.Id, wrapper.guests[0].photoUrl);
        System.assertEquals(false, wrapper.photosOmittedDueToSize);
    }
}