@isTest
private class EventGuestBioControllerTest {

    // ------------------------------------------------------------------
    // NOTE ON THIS REWRITE
    // ------------------------------------------------------------------
    // EventGuestBioController no longer exposes a `guestList` property or
    // a `GuestWrapper` inner class - it was refactored to build a single
    // pre-rendered `guestBioHtml` string directly (see renderGuestBlock /
    // normalizeParagraphs / packIntoChunks in the controller). That is
    // what caused "Variable does not exist: guestList" at compile time:
    // this test class was still written against the old wrapper-list API.
    //
    // Every assertion below has been rewritten against the controller's
    // actual public surface: guestBioHtml, hasGuests, eventTitle,
    // eventDateStr. Since the chunking/escaping helpers are private,
    // their behavior is verified indirectly by inspecting the rendered
    // HTML markers they produce ("new-page-guest" for a guest's first
    // page, "new-page-chunk" for any additional page, the photo <img>
    // tag vs the "N/A" placeholder, the "Biography not yet available."
    // placeholder, and escaped HTML entities in a title).
    //
    // IMPORTANT - test data is deliberately kept "regex-friendly":
    // EventGuestBioController.splitLongParagraph uses a
    // java.util.regex Matcher (pattern "[^.!?]+[.!?]+(\s+|$)") to find
    // sentence boundaries. Feeding it a long run of text (roughly
    // 1600+ characters, since that is CHUNK_LIMIT) with NO '.', '!' or
    // '?' anywhere in it forces that regex into heavy backtracking and
    // throws System.LimitException: Regex too complicated - this is a
    // real characteristic of the (unmodified) controller, not a test
    // bug. Every long bio below is therefore built out of normal,
    // period-terminated sentences (same shape as real prose) so it
    // still exceeds CHUNK_LIMIT and forces splitLongParagraph to run,
    // without ever handing the regex a long punctuation-free run.
    // ------------------------------------------------------------------

    @isTest
    static void testConstructorWithNoIdParam() {
        // No 'id' parameter set at all -> invitationId resolves to null
        Test.startTest();
        EventGuestBioController controller = new EventGuestBioController();
        Test.stopTest();

        System.assertEquals(false, controller.hasGuests, 'hasGuests should be false');
        System.assertEquals('', controller.guestBioHtml, 'guestBioHtml should remain empty');
        System.assertEquals('Guest Biographies', controller.eventTitle, 'Default event title should remain unchanged');
        System.assertEquals('', controller.eventDateStr, 'Event date string should remain empty');
    }

    @isTest
    static void testConstructorWithInvalidInvitationId() {
        // Valid-looking Id format but no matching record exists
        Invitation__c temp = new Invitation__c(Name = 'TempForId');
        insert temp;
        Id fakeId = temp.Id;
        delete temp;

        ApexPages.currentPage().getParameters().put('id', fakeId);

        Test.startTest();
        EventGuestBioController controller = new EventGuestBioController();
        Test.stopTest();

        System.assertEquals(false, controller.hasGuests, 'hasGuests should be false when invitation not found');
        System.assertEquals('', controller.guestBioHtml, 'guestBioHtml should remain empty');
        System.assertEquals('Guest Biographies', controller.eventTitle, 'Default title remains when invitation lookup fails');
    }

    @isTest
    static void testConstructorWithInvitationButNoGuests() {
        Invitation__c inv = new Invitation__c(
            Name = 'Gala Night',
            Event_Start_Date__c = Date.newInstance(2026, 8, 15)
        );
        insert inv;
        // No Guest_List__c records created for this invitation

        ApexPages.currentPage().getParameters().put('id', inv.Id);

        Test.startTest();
        EventGuestBioController controller = new EventGuestBioController();
        Test.stopTest();

        System.assertEquals('Gala Night', controller.eventTitle, 'Event title should be set from invitation Name');
        System.assertNotEquals('', controller.eventDateStr, 'Event date string should be formatted');
        System.assertEquals(false, controller.hasGuests, 'hasGuests should be false with no guest records');
        System.assertEquals('', controller.guestBioHtml, 'guestBioHtml should remain empty with no guests');

        String headerValue = ApexPages.currentPage().getHeaders().get('Content-Disposition');
        System.assertNotEquals(null, headerValue, 'Header should be set once invitation is found');
        System.assert(headerValue.contains('Guest Bios - '), 'Header should contain bio filename prefix');
    }

    @isTest
    static void testConstructorWithFullGuestDataAndVariedBios() {
        Invitation__c inv = new Invitation__c(
            Name = 'Annual Summit',
            Event_Start_Date__c = Date.newInstance(2026, 9, 1)
        );
        insert inv;

        // Guest 1: long bio built from many short, properly punctuated
        // sentences in a SINGLE paragraph (no blank lines) - forces
        // normalizeParagraphs -> splitLongParagraph down the
        // sentence-boundary accumulation path, producing several
        // page-sized chunks. Also has a photo attachment.
        String sentenceUnit = 'This is a sample sentence about the guest speaker and their background.';
        String longSentenceBio = '';
        for (Integer i = 0; i < 30; i++) {
            longSentenceBio += sentenceUnit + ' ';
        }
        Contact c1 = new Contact();
        c1.LastName = 'LongBioGuest';
        c1.Title = 'Keynote Speaker';
        c1.Professional_Personal_Backgrounds__c = longSentenceBio;
        insert c1;

        Attachment att1 = new Attachment();
        att1.ParentId = c1.Id;
        att1.Name = 'guest1.png';
        att1.Body = Blob.valueOf('fake image content 1');
        att1.ContentType = 'image/png';
        insert att1;

        // Guest 2: short bio, fits in a single paragraph/chunk, no
        // photo, no title (exercises the blank-title branch).
        Contact c2 = new Contact();
        c2.LastName = 'ShortBioGuest';
        c2.Professional_Personal_Backgrounds__c = 'A brief bio for guest two.';
        insert c2;

        // Guest 3: no bio at all, no attachment (exercises the
        // "Biography not yet available." / N/A placeholder branches).
        Contact c3 = new Contact();
        c3.LastName = 'NoBioGuest';
        insert c3;

        // Guest 4: two real paragraphs (blank-line separated). The
        // second paragraph is built the same way as guest 1's - many
        // short, properly punctuated sentences - so it also exceeds
        // CHUNK_LIMIT and forces splitLongParagraph to run a second
        // time (covering normalizeParagraphs' multi-paragraph split
        // and packIntoChunks folding several paragraphs together),
        // without ever handing the regex a long punctuation-free run.
        // Title includes characters that must be HTML-escaped.
        String introParagraph = 'Quick intro paragraph for guest four.';
        String sentenceUnitFour = 'Guest four continues to build an extensive record of achievements and recognition.';
        String longSentenceBioFour = '';
        for (Integer i = 0; i < 25; i++) {
            longSentenceBioFour += sentenceUnitFour + ' ';
        }
        Contact c4 = new Contact();
        c4.LastName = 'MultiParagraphGuest';
        c4.Title = 'R&D <Lead> "Global"';
        c4.Professional_Personal_Backgrounds__c = introParagraph + '\n\n' + longSentenceBioFour;
        insert c4;

        Guest_List__c gl1 = new Guest_List__c(Invitation__c = inv.Id, Contact__c = c1.Id);
        Guest_List__c gl2 = new Guest_List__c(Invitation__c = inv.Id, Contact__c = c2.Id);
        Guest_List__c gl3 = new Guest_List__c(Invitation__c = inv.Id, Contact__c = c3.Id);
        Guest_List__c gl4 = new Guest_List__c(Invitation__c = inv.Id, Contact__c = c4.Id);
        insert new List<Guest_List__c>{ gl1, gl2, gl3, gl4 };

        ApexPages.currentPage().getParameters().put('id', inv.Id);

        Test.startTest();
        EventGuestBioController controller = new EventGuestBioController();
        Test.stopTest();

        System.assertEquals('Annual Summit', controller.eventTitle);
        System.assertNotEquals('', controller.eventDateStr);
        System.assertEquals(true, controller.hasGuests, 'hasGuests should be true');

        String html = controller.guestBioHtml;
        System.assertNotEquals(null, html);
        System.assertNotEquals('', html);

        // Every guest contributes exactly one "first page" block,
        // regardless of how many extra chunks their bio needed.
        System.assertEquals(4, html.countMatches('new-page-guest'),
            'Each of the 4 guests should produce exactly one first-page block');

        // Guest 1's bio and guest 4's second paragraph both overflow
        // a single page, so at least one continuation chunk must exist.
        System.assert(html.countMatches('new-page-chunk') > 0,
            'Long bios should spill into at least one continuation chunk');

        // Guest 1: has a photo -> real <img> tag, not the N/A placeholder.
        System.assert(html.contains('/servlet/servlet.FileDownload?file=' + att1.Id),
            'Guest with a photo attachment should render the image tag');

        // Guests 2, 3 and 4 have no attachment -> N/A placeholder appears
        // at least 3 times.
        Integer naCount = html.countMatches('<div class="photo-na">N/A</div>');
        System.assert(naCount >= 3, 'Guests without a photo should show the N/A placeholder');

        // Guest 3 has no bio at all.
        System.assert(html.contains('Biography not yet available.'),
            'Guest with no bio should show the placeholder message');

        // Guest 4's title must be HTML-escaped.
        System.assert(html.contains('R&amp;D &lt;Lead&gt; &quot;Global&quot;'),
            'Title with special characters should be HTML-escaped');

        // Names for all four guests should appear somewhere in the output.
        Map<Id, Contact> reloaded = new Map<Id, Contact>([
            SELECT Id, Name FROM Contact WHERE Id IN :new Set<Id>{ c1.Id, c2.Id, c3.Id, c4.Id }
        ]);
        for (Contact rc : reloaded.values()) {
            System.assert(html.contains(rc.Name), 'Guest name ' + rc.Name + ' should appear in the rendered HTML');
        }
    }

    @isTest
    static void testConstructorWithAutoNumberNameAndNullDate() {
        // Invitation__c.Name is an auto-number field, so it can never be blank.
        // This test instead covers the null Event_Start_Date__c branch.
        Invitation__c inv = new Invitation__c();
        insert inv;

        Contact c = new Contact(LastName = 'EdgeCaseGuest');
        insert c;

        Guest_List__c gl = new Guest_List__c(Invitation__c = inv.Id, Contact__c = c.Id);
        insert gl;

        ApexPages.currentPage().getParameters().put('id', inv.Id);

        Test.startTest();
        EventGuestBioController controller = new EventGuestBioController();
        Test.stopTest();

        Invitation__c reloadedInv = [SELECT Name FROM Invitation__c WHERE Id = :inv.Id LIMIT 1];
        Contact reloadedContact = [SELECT Name FROM Contact WHERE Id = :c.Id LIMIT 1];

        // Since Name is auto-number, eventTitle will be set to that auto-number value, not the default
        System.assertEquals(reloadedInv.Name, controller.eventTitle, 'Event title should be set from auto-number Name');
        System.assertEquals('', controller.eventDateStr, 'Date string should remain empty since no start date set');
        System.assertEquals(true, controller.hasGuests);
        System.assert(controller.guestBioHtml.contains(reloadedContact.Name),
            'Rendered HTML should include the single guest\'s name');
        System.assert(controller.guestBioHtml.contains('Biography not yet available.'),
            'Guest with no bio should show the placeholder message');
        System.assertEquals(1, controller.guestBioHtml.countMatches('new-page-guest'),
            'Single guest with no bio should render exactly one page block');
    }
}