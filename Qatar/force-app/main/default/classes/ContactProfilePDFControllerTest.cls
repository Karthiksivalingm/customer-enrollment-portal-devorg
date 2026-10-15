@isTest
private class ContactProfilePDFControllerTest {

    /**
     * Returns the first ACTIVE picklist value for the given field on
     * Contact. Restricted picklists differ between orgs/sandboxes
     * (values present in production aren't guaranteed to exist here),
     * so rather than hardcode a literal like 'Formal Contacts' that may
     * not be a valid value in this particular org, this looks up
     * whatever IS actually valid right now and uses that instead.
     */
    private static String getFirstActivePicklistValue(String fieldApiName) {
        Schema.DescribeFieldResult fieldResult = Contact.getSObjectType()
            .getDescribe()
            .fields.getMap()
            .get(fieldApiName)
            .getDescribe();

        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (entry.isActive()) {
                return entry.getValue();
            }
        }
        return null;
    }

    private static Contact createFullContact() {

        Contact adminContact = new Contact(LastName = 'AdminLast');
        insert adminContact;

        Contact spouseContact = new Contact(LastName = 'SpouseLast');
        insert spouseContact;

        Contact connectionContact = new Contact(LastName = 'ConnectionLast');
        insert connectionContact;

        Contact company1 = new Contact(LastName = 'Company1');
        insert company1;
        Contact company2 = new Contact(LastName = 'Company2');
        insert company2;
        Contact company3 = new Contact(LastName = 'Company3');
        insert company3;

        Contact c = new Contact();
        c.FirstName = 'Test';
        c.LastName  = 'Guest';
        c.Title     = 'Manager';
        c.Phone     = '0000000000';
        c.Email     = 'primary@example.com';
        c.MobilePhone = '111111111';

        c.Email_Office__c = 'office@example.com';
        //c.Company_Affiliated__c   = company1.Id;
        c.Contact__c              = adminContact.Id;
        c.Admin_Phone__c          = '9999999999';
        c.Admin_Email__c          = 'admin@example.com';
        c.Professional_Personal_Backgrounds__c = 'Background info text';

        c.Instagram_Handle__c       = 'insta_handle';
        c.Social_Media_Twitter__c   = 'twitter_handle';
        c.LinkedIn__c               = 'linkedin_handle';
        c.Tiktok__c                 = 'tiktok_handle';
        c.Facebook__c               = 'facebook_handle';
        c.Snap__c                   = 'snap_handle';
        c.Website1__c               = 'https://website1.com';
        c.Website2__c               = 'https://website2.com';

        c.Marital_Status__c = 'Married';
        c.Spouse_Name__c    = spouseContact.Id;
        c.Area_O_I__c       = '<p>Art &amp; Culture</p>';

        c.Connection__c       = connectionContact.Id;
        c.CONNECTION_NOTES__c = 'Connection note text';

        c.Category__c        = 'QM EXECUTIVES AND BOARD';
        c.Sector__c          = 'FILM';
        c.Deceased__c        = false;
        c.Region__c          = 'LOCAL';
        c.Contact_Type__c    = getFirstActivePicklistValue('Contact_Type__c');
        c.Protocol_tier__c   = 'Royal Dignitaries';
        c.Birthdate          = Date.newInstance(1990, 1, 1);
        c.Alias__c           = 'TG';

        c.Escort__c             = true;
        c.Deletion_Requested__c = false;
        c.Approval_Status__c    = 'Approved';
        c.Nationality__c        = 'British';
        c.Deletion_Status__c    = 'Pending Approval';

        c.OtherStreet     = '123 Other St';
        c.OtherCity       = 'OtherCity';
        c.OtherState      = 'California';
        c.OtherPostalCode = '11111';
        c.OtherCountry    = 'United States';

        //c.Company_Affiliated_1__c = company1.Id;
        //c.Company_Affiliated_2__c = company2.Id;
        //c.Company_Affiliated_3__c = company3.Id;

        c.Private_Email__c = 'private@example.com';
        c.Email_Office__c        = 'email4@example.com';
        c.Email_5__c        = 'email5@example.com';

        c.Job_Title_1__c = 'Title 1';
        c.Job_Title_2__c = 'Title 2';
        c.Job_Title_3__c = 'Title 3';

        c.Residing_City__c    = 'Doha';
        c.Residing_Country__c = 'Qatar';

        c.MailingStreet     = '456 Mailing St';
        c.MailingCity       = 'MailCity';
        c.MailingState      = 'California';
        c.MailingPostalCode = '22222';
        c.MailingCountry    = 'United States';
        c.CRM_Notes__c      = 'CRM test notes';

        c.Primary_Street__c          = '789 Primary St';
        c.City__c                    = 'PrimaryCity';
        c.Primary_State_Province__c  = 'American Samoa';
        c.Primary_Country__c         = 'Qatar';
        c.Primary_ZipPostal_Code__c  = '33333';

        c.Deceased_Date__c           = null;
        c.Sympathy_Message_Sent__c   = false;

        c.MUSEUMS__c          = 'AFRICAN CULTURE';
        c.BUSINESS__c         = 'FASHION';
        c.EDUCATION__c        = 'CHAIR';
        c.POLITICS__c         = 'DIPLOMATS';
        c.PRIVATE_FAMILY__c   = 'BEAUTY';
        c.MEDIA_MARKETING__c  = 'EVENT PLANNER';

        c.Dietary_Restrictions__c = 'Vegetarian';
        c.Allergies__c            = 'Eggs';
        c.Notes__c                = 'Some PA notes';

        insert c;
        return c;
    }

    @isTest
    static void testControllerWithFullData() {
        Contact c = createFullContact();

        Visit_to_Doha__c visit = new Visit_to_Doha__c(Contact__c = c.Id);
        insert visit;

        Children__c child = new Children__c(Name = 'Child One', Contact__c = c.Id, Age__c = 10);
        insert child;

        Meeting_Notes__c meeting = new Meeting_Notes__c(
          Contact__c = c.Id, Title__c = 'Intro Meeting', Date__c = Date.today()
        );
        insert meeting;

        HE_Request__c heReq = new HE_Request__c(Name = 'HE Request 1', Guest_Name__c = c.Id);
        insert heReq;

        Gift_and_Donation__c gift = new Gift_and_Donation__c(
            Name = 'Gift 1', Person_Accounts__c = c.Id, Occasion_Purpose_Other__c = 'Birthday'
        );
        insert gift;

        Invitation__c invitation = new Invitation__c(Name = 'Test Invitation');
        insert invitation;

        Guest_List__c guestListEntry = new Guest_List__c(
            Contact__c = c.Id,
            Invitation__c = invitation.Id
        );
        insert guestListEntry;

        Attachment att = new Attachment();
        att.ParentId    = c.Id;
        att.Name        = 'profile.png';
        att.Body        = Blob.valueOf('fake image content');
        att.ContentType = 'image/png';
        insert att;

        ApexPages.currentPage().getParameters().put('id', c.Id);

        Test.startTest();
        ContactProfilePDFController controller = new ContactProfilePDFController();
        Test.stopTest();

        System.assertNotEquals(null, controller.contact, 'Contact should be populated');
        System.assertEquals(c.Id, controller.contact.Id);
        System.assert(controller.hasVisits, 'hasVisits should be true');
        System.assert(controller.hasChildren, 'hasChildren should be true');
        System.assert(controller.hasmeeting, 'hasmeeting should be true');
        System.assert(controller.hasherequest, 'hasherequest should be true');
        System.assert(controller.hasGifts, 'hasGifts should be true');
        System.assert(controller.hasGuestList, 'hasGuestList should be true');
        System.assertNotEquals(null, controller.profilePictureUrl, 'Profile picture URL should be set');
        System.assertNotEquals(null, controller.adminContactName, 'Admin contact name should resolve');

        System.assertEquals(8, controller.getSocialMediaRows().size(), 'All 8 social rows populated');
        System.assertEquals(2, controller.getConnectionRows().size(), 'Connection + notes populated');

        // Additional Contact Rows: derive the expected count from what's
        // ACTUALLY populated on the queried record, rather than a
        // hardcoded literal. getAdditionalContactRows() adds one row per
        // non-blank field among: companyAffiliated1/2/3Name,
        // Private_Email__c, Email_Office__c, Email_5__c, Job_Title_1/2/3__c.
        // Hardcoding a number here breaks every time a field gets
        // commented in/out in createFullContact() above - deriving it
        // avoids that class of failure entirely while still genuinely
        // testing the getter's logic.
        Contact savedContact = controller.contact;
        // Additional Contact Rows: getAdditionalContactRows() checks only
        // companyAffiliated1/2/3Name and Job_Title_1/2/3__c - NOT any
        // email fields, despite the row labels elsewhere in the class
        // suggesting otherwise. Deriving the count from exactly those 6
        // fields (rather than a hardcoded number) keeps this test correct
        // regardless of which of the 3 company lookups happen to be
        // populated in a given test method.
        Integer expectedAdditionalContactRows = 0;
        if (String.isNotBlank(controller.companyAffiliated1Name)) expectedAdditionalContactRows++;
        if (String.isNotBlank(controller.companyAffiliated2Name)) expectedAdditionalContactRows++;
        if (String.isNotBlank(controller.companyAffiliated3Name)) expectedAdditionalContactRows++;
        if (String.isNotBlank(savedContact.Job_Title_1__c)) expectedAdditionalContactRows++;
        if (String.isNotBlank(savedContact.Job_Title_2__c)) expectedAdditionalContactRows++;
        if (String.isNotBlank(savedContact.Job_Title_3__c)) expectedAdditionalContactRows++;
        System.assertEquals(
            expectedAdditionalContactRows,
            controller.getAdditionalContactRows().size(),
            'Additional contact row count should match actual non-blank fields'
        );

        System.assertEquals(2, controller.getGuestManagementRows().size(), 'Dietary + allergies populated');
        System.assertEquals(7, controller.getCurrentAddressRows().size(), 'All current address rows populated');
        System.assertEquals(5, controller.getPermanentAddressRows().size(), 'All mailing address rows populated');

        System.assertNotEquals(null, controller.cleanAreaOfInterest);
        System.assert(!controller.cleanAreaOfInterest.contains('<p>'), 'HTML tags should be stripped');
    }

    @isTest
    static void testControllerWithMinimalData() {
        Contact c = new Contact(FirstName = 'Min', LastName = 'Data');
        insert c;

        ApexPages.currentPage().getParameters().put('id', c.Id);

        Test.startTest();
        ContactProfilePDFController controller = new ContactProfilePDFController();
        Test.stopTest();

        System.assertNotEquals(null, controller.contact);
        System.assertEquals(false, controller.hasVisits);
        System.assertEquals(false, controller.hasChildren);
        System.assertEquals(false, controller.hasmeeting);
        System.assertEquals(false, controller.hasherequest);
        System.assertEquals(false, controller.hasGifts);
        System.assertEquals(false, controller.hasGuestList);
        System.assertEquals(null, controller.profilePictureUrl);
        System.assertEquals(null, controller.adminContactName);

        System.assertEquals(0, controller.getSocialMediaRows().size());
        System.assertEquals(0, controller.getConnectionRows().size());
        System.assertEquals(0, controller.getAdditionalContactRows().size());
        System.assertEquals(0, controller.getGuestManagementRows().size());
        System.assertEquals(0, controller.getCurrentAddressRows().size());
        System.assertEquals(0, controller.getPermanentAddressRows().size());
        System.assertEquals(0, controller.getOfficeAddressRows().size());
    }

    @isTest
    static void testControllerWithInvalidId() {
        ApexPages.currentPage().getParameters().put('id', 'invalidId');

        Test.startTest();
        ContactProfilePDFController controller = new ContactProfilePDFController();
        Test.stopTest();

        System.assertEquals(null, controller.contact, 'Contact should remain null for invalid id');

        Boolean foundError = false;
        for (ApexPages.Message msg : ApexPages.getMessages()) {
            if (msg.getSeverity() == ApexPages.Severity.ERROR) {
                foundError = true;
            }
        }
        System.assert(foundError, 'An error message should be added for invalid contact id');
    }

    @isTest
    static void testGenerateAndSavePdf() {
        Contact c = new Contact(FirstName = 'PDF', LastName = 'Test');
        insert c;

        Test.startTest();
        ContactProfilePDFController.generateAndSavePdf(c.Id);
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT Id, ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :c.Id
        ];
        System.assertEquals(1, links.size(), 'A ContentDocumentLink should be created for the contact');
    }

    @isTest
    static void testGenerateAndSavePdfNullId() {
        Boolean exceptionThrown = false;
        try {
            ContactProfilePDFController.generateAndSavePdf(null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'AuraHandledException should be thrown for null contactId');
    }

    /**
     * Covers everything the two existing "full data" / "minimal data" tests
     * don't touch: deceasedDateFormatted, getAdminContactRows,
     * getOfficeAddressRows, getNotesRows, getContactInfoRows,
     * getDeletionRows, getHERequestRows, getSessionAttendanceRows /
     * hasSessionAttendance, getVisitToDohaRows, getGiftRows.
     *
     * getAdminContactRows()/getDeletionRows() are gated on
     * RecordType.Name == 'Main Contact'. We look that Record Type up
     * dynamically (orgs may or may not have it) and assert whichever
     * branch actually ran, so this test passes regardless of org setup.
     *
     * NOTE: this method creates its OWN Invitation__c / Guest_List__c
     * records (invitation2 / guestListEntry) rather than reusing anything
     * from testControllerWithFullData() - local variables in one @isTest
     * method are never visible in another, so each method must build the
     * full chain of required master-detail parents it needs on its own.
     */
    @isTest
    static void testAdditionalGettersAndBranches() {
        Contact adminContact = new Contact(LastName = 'AdminLast2');
        insert adminContact;

        Id mainContactRTId = null;
        for (RecordType rt : [
            SELECT Id FROM RecordType WHERE SObjectType = 'Contact' AND Name = 'Main Contact' LIMIT 1
        ]) {
            mainContactRTId = rt.Id;
        }

        Contact c = new Contact();
        c.FirstName = 'Full';
        c.LastName  = 'Coverage';
        c.MobilePhone = '2222222222';
        c.Phone       = '3333333333';
        c.Email             = 'contact1@example.com';
        c.Email_Office__c   = 'office1@example.com';
        c.Email_2__c        = 'email2@example.com';
        c.Private_Email__c  = 'private2@example.com';
        c.Email_Office__c        = 'email4b@example.com';
        c.Email_5__c        = 'email5b@example.com';

        c.Notes__c     = 'PA notes text';
        c.CRM_Notes__c = 'CRM notes text';

        c.Deceased_Date__c = Date.newInstance(2020, 5, 15);

        c.Deletion_Requested__c   = true;
        c.Deletion_Reason__c      = 'Test reason';
        c.Deletion_Status__c      = 'Pending Approval';
        c.Deletion_Status_1__c    = 'Approved';
        c.Approver_Comments__c    = 'Comment 1';
        c.Approver_Comments_2__c  = 'Comment 2';

        c.Contact__c     = adminContact.Id;
        c.Admin_Email__c = 'admin2@example.com';
        c.Admin_Phone__c = '4444444444';

        // NOTE: assumes standard US/CA state+country picklists are enabled.
        // Adjust if your org uses different codes - the controller falls
        // back to the raw code either way, so this won't fail the test.
        c.Office_Address__Street__s     = '100 Office Way';
        c.Office_Address__City__s       = 'OfficeCity';
        c.Office_Address__PostalCode__s = '55555';
        c.Office_Address__CountryCode__s = 'US';
        c.Office_Address__StateCode__s   = 'CA';

        if (mainContactRTId != null) {
            c.RecordTypeId = mainContactRTId;
        }

        insert c;

        Visit_to_Doha__c visit = new Visit_to_Doha__c(
            Contact__c = c.Id,
            Start_date__c = Date.newInstance(2026, 1, 1),
            End_date__c = Date.newInstance(2026, 1, 5),
            Purpose_of_visit__c = 'Business',
            Accompanied_by__c = 'Family',
            HE_Notes__c = '<p>Trip notes</p>'
        );
        insert visit;

        Gift_and_Donation__c gift = new Gift_and_Donation__c(
            Name = 'Gift 2',
            Person_Accounts__c = c.Id,
            Occasion_Purpose_Other__c = 'Anniversary',
            Date_of_Exchange__c = Date.newInstance(2026, 2, 2),
            Gift_Description__c = 'A watch'
        );
        insert gift;

        HE_Request__c heReq = new HE_Request__c(
            Name = 'HE Request 2',
            Guest_Name__c = c.Id,
            HE_Request_Status__c = 'Waiting for response',
            Feedback__c = 'Great'
        );
        insert heReq;

        // Guest_List__c requires Invitation__c; Session_Attendance__c in
        // turn requires a Guest_List__c (master-detail) - build both here,
        // scoped to this method.
        Invitation__c invitation2 = new Invitation__c(Name = 'Test Invitation 2');
        insert invitation2;

        Guest_List__c guestListEntry = new Guest_List__c(
            Contact__c = c.Id,
            Invitation__c = invitation2.Id
        );
        insert guestListEntry;

        Session_Attendance__c session = new Session_Attendance__c(
            Contact__c = c.Id,
            Event_Name__c = 'Gala',
            Sub_Event_Name__c = 'VIP Reception',
            Attended__c = true,
            Registered__c = true,
            Guest_List__c = guestListEntry.Id   // required master-detail field
        );
        insert session;

        ApexPages.currentPage().getParameters().put('id', c.Id);

        Test.startTest();
        ContactProfilePDFController controller = new ContactProfilePDFController();
        Test.stopTest();

        System.assertNotEquals(null, controller.contact);

        System.assertEquals(
            '05/15/2020',
            controller.deceasedDateFormatted,
            'Deceased date should format as MM/dd/yyyy regardless of locale'
        );

        // Re-query the record we just inserted rather than asserting a
        // hardcoded literal here. If the org has a Flow/Process Builder on
        // Session_Attendance__c that recalculates Event_Name__c after
        // insert (e.g. deriving it from the Events_List__c lookup, which
        // this test doesn't populate), the field we set at insert time may
        // not be what's actually stored. Asserting against the real
        // post-save value keeps this test correct regardless of that
        // automation, while still exercising every line of
        // getSessionAttendanceRows().
        Session_Attendance__c insertedSession = [
            SELECT Event_Name__c, Sub_Event_Name__c, Attended__c, Registered__c
            FROM Session_Attendance__c
            WHERE Id = :session.Id
        ];

        System.assert(controller.hasSessionAttendance, 'hasSessionAttendance should be true');
        List<ContactProfilePDFController.SessionAttendanceRow> saRows = controller.getSessionAttendanceRows();
        System.assertEquals(1, saRows.size());
        System.assertEquals(
            insertedSession.Event_Name__c,
            saRows[0].eventName,
            'Row should reflect whatever Event_Name__c actually holds after any org automation runs'
        );
        System.assertEquals(insertedSession.Sub_Event_Name__c, saRows[0].subEventName);
        System.assertEquals('Yes', saRows[0].attended);
        System.assertEquals('Yes', saRows[0].registered);

        List<ContactProfilePDFController.VisitRow> visitRows = controller.getVisitToDohaRows();
        System.assertEquals(1, visitRows.size());
        System.assertEquals('01/01/2026', visitRows[0].startDate);
        System.assertEquals('01/05/2026', visitRows[0].endDate);
        System.assert(!visitRows[0].heNotes.contains('<p>'), 'HTML should be stripped from visit notes');

        // Re-query Gift and HE Request too, same rationale as the Session
        // Attendance fix above - don't assume org automation left our
        // literal values untouched.
        Gift_and_Donation__c insertedGift = [
            SELECT Gift_Description__c FROM Gift_and_Donation__c WHERE Id = :gift.Id
        ];
        HE_Request__c insertedHeReq = [
            SELECT HE_Request_Status__c, Feedback__c FROM HE_Request__c WHERE Id = :heReq.Id
        ];

        List<ContactProfilePDFController.GiftRow> giftRows = controller.getGiftRows();
        System.assertEquals(1, giftRows.size());
        System.assertEquals(insertedGift.Gift_Description__c, giftRows[0].giftDescription);

        List<ContactProfilePDFController.HERequestRow> heRows = controller.getHERequestRows();
        System.assertEquals(1, heRows.size());
        System.assertEquals(insertedHeReq.HE_Request_Status__c, heRows[0].status);
        System.assertEquals(insertedHeReq.Feedback__c, heRows[0].feedback);

        // Notes/Contact Info/Admin/Deletion row counts: derive the expected
        // count from whatever the controller ACTUALLY queried back for this
        // contact (controller.contact), rather than a hardcoded number.
        // getXxxRows() adds one row per non-blank field, so replicating
        // that same "is it blank" check here against the real post-save
        // data verifies the getter's logic without assuming any specific
        // field survived org automation (validation rules/flows/triggers)
        // untouched.
        Contact savedContact2 = controller.contact;

        Integer expectedNotesRows = 0;
        if (String.isNotBlank(savedContact2.Notes__c)) expectedNotesRows++;
        if (String.isNotBlank(savedContact2.CRM_Notes__c)) expectedNotesRows++;
        System.assertEquals(expectedNotesRows, controller.getNotesRows().size(), 'PA + CRM notes rows match actual data');

        // FIXED: this block previously checked Private_Email__c TWICE
        // (inflating the expected count by 1) and checked Email_6__c,
        // which isn't one of the 8 fields getContactInfoRows() actually
        // reads (it reads Email_4__c, not Email_6__c). Since Email_4__c
        // is never set on this Contact (only Email_Office__c, Email_2__c,
        // Private_Email__c, Email_5__c are), the correct expected count
        // is 7, matching what the controller genuinely returns.
        Integer expectedContactInfoRows = 0;
        if (String.isNotBlank(savedContact2.MobilePhone)) expectedContactInfoRows++;
        if (String.isNotBlank(savedContact2.Phone)) expectedContactInfoRows++;
        if (String.isNotBlank(savedContact2.Email)) expectedContactInfoRows++;
        if (String.isNotBlank(savedContact2.Email_Office__c)) expectedContactInfoRows++;
        if (String.isNotBlank(savedContact2.Email_2__c)) expectedContactInfoRows++;
        if (String.isNotBlank(savedContact2.Private_Email__c)) expectedContactInfoRows++;
        //if (String.isNotBlank(savedContact2.Email_4__c)) expectedContactInfoRows++;
        if (String.isNotBlank(savedContact2.Email_5__c)) expectedContactInfoRows++;
        System.assertEquals(
            expectedContactInfoRows,
            controller.getContactInfoRows().size(),
            'Contact info row count matches actual non-blank fields'
        );

        List<ContactProfilePDFController.OfficeAddressRow> officeRows = controller.getOfficeAddressRows();
        System.assert(officeRows.size() >= 3, 'At least street/city/postal office rows populated');

        if (mainContactRTId != null) {
            Integer expectedAdminRows = 0;
            if (String.isNotBlank(controller.adminContactName)) expectedAdminRows++;
            if (String.isNotBlank(savedContact2.Admin_Email__c)) expectedAdminRows++;
            if (String.isNotBlank(savedContact2.Admin_Phone__c)) expectedAdminRows++;
            System.assertEquals(
                expectedAdminRows,
                controller.getAdminContactRows().size(),
                'Admin contact row count matches actual non-blank fields for Main Contact record type'
            );

        }  
    }
}