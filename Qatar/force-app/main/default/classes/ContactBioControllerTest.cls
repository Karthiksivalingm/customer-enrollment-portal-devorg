@isTest
private class ContactBioControllerTest {

    @isTest
    static void testConstructorWithFullDataAndLongBio() {

        Contact c = new Contact();
        c.LastName = 'Tester';
        c.Title = 'Director';
        c.Birthdate = Date.newInstance(1985, 5, 20);
        c.Phone = '1234567890';
        c.Instagram_Handle__c = 'tester_insta';
        c.Email = 'tester@example.com';
        c.OtherPhone = '0987654321';
        c.Email_Office__c = 'office@example.com';
        c.Salutation = 'Mr.';

        // Build a long biography that forces the chunking logic to split
        // into multiple chunks (chunkLimit = 2000 chars per chunk).
        String longParagraph = ''.leftPad(1500, 'A');
        String bio = longParagraph + '\n' + longParagraph + '\n' + longParagraph;
        c.Professional_Personal_Backgrounds__c = bio;

        insert c;

        Attachment att = new Attachment();
        att.ParentId = c.Id;
        att.Name = 'profile.png';
        att.Body = Blob.valueOf('fake image content');
        att.ContentType = 'image/png';
        insert att;

        ApexPages.currentPage().getParameters().put('id', c.Id);

        Test.startTest();
        ContactBio controller = new ContactBio();
        Test.stopTest();

        System.assertNotEquals(null, controller.Con, 'Contact should be populated');
        System.assertEquals(c.Id, controller.Con.Id);
        System.assertNotEquals(null, controller.Attach, 'Attachment should be populated');
        System.assertEquals('profile.png', controller.Attach.Name);

        System.assert(controller.ParagraphChunks.size() > 1, 'Long bio should be split into multiple chunks');
        System.assertEquals(false, controller.getIsBiographyEmpty(), 'Biography should not be empty');
        System.assertEquals('pdf', controller.getPageRenderAs(), 'Should render as pdf when bio is present');

        String headerValue = ApexPages.currentPage().getHeaders().get('Content-Disposition');
        System.assertNotEquals(null, headerValue, 'Content-Disposition header should be set when Name is present');
        System.assert(headerValue.contains('Bio - '), 'Header should contain the bio filename prefix');
    }

    @isTest
    static void testConstructorWithShortBioSingleChunk() {

        Contact c = new Contact();
        c.LastName = 'Shorty';
        c.Professional_Personal_Backgrounds__c = 'A short single-paragraph biography.';
        insert c;

        ApexPages.currentPage().getParameters().put('id', c.Id);

        Test.startTest();
        ContactBio controller = new ContactBio();
        Test.stopTest();

        System.assertNotEquals(null, controller.Con);
        System.assertEquals(1, controller.ParagraphChunks.size(), 'Short bio should result in exactly one chunk');
        System.assertEquals(false, controller.getIsBiographyEmpty());
        System.assertEquals('pdf', controller.getPageRenderAs());
        System.assertEquals(null, controller.Attach, 'No attachment should be present');
    }

    @isTest
    static void testConstructorWithBlankBiography() {

        Contact c = new Contact();
        c.LastName = 'NoBio';
        // Professional_Personal_Backgrounds__c intentionally left blank
        insert c;

        ApexPages.currentPage().getParameters().put('id', c.Id);

        Test.startTest();
        ContactBio controller = new ContactBio();
        Test.stopTest();

        System.assertNotEquals(null, controller.Con);
        System.assertEquals(0, controller.ParagraphChunks.size(), 'No chunks should be created for blank biography');
        System.assertEquals(true, controller.getIsBiographyEmpty(), 'Biography should be reported as empty');
        System.assertEquals('', controller.getPageRenderAs(), 'Should render as HTML (empty string) when bio is blank');

        String headerValue = ApexPages.currentPage().getHeaders().get('Content-Disposition');
        System.assertNotEquals(null, headerValue, 'Header should still be set since Name is not blank');
    }

    @isTest
    static void testConstructorWithNullId() {

        // Do NOT set the 'id' parameter, so ConId remains null
        Test.startTest();
        ContactBio controller = new ContactBio();
        Test.stopTest();

        System.assertEquals(null, controller.ConId, 'ConId should be null when no id param is provided');
        System.assertEquals(null, controller.Con, 'Con should remain null when ConId is null');
        System.assertEquals(0, controller.ParagraphChunks.size(), 'ParagraphChunks should remain empty');
        System.assertEquals(true, controller.getIsBiographyEmpty(), 'Biography should be considered empty when Con is null');
        System.assertEquals('', controller.getPageRenderAs(), 'Should render as HTML when Con is null');
    }

    @isTest
    static void testConstructorWithNoLastNameStillWorks() {
        // Contact with only required field, ensures Name resolves to something
        // and tests the attachment-not-found branch alongside a populated bio.
        Contact c = new Contact();
        c.LastName = 'Solo';
        c.Professional_Personal_Backgrounds__c = 'Bio text here for solo contact.';
        insert c;

        ApexPages.currentPage().getParameters().put('id', c.Id);

        Test.startTest();
        ContactBio controller = new ContactBio();
        Test.stopTest();

        System.assertNotEquals(null, controller.Con);
        System.assertEquals(null, controller.Attach, 'No attachment exists for this contact');
        System.assertEquals(false, controller.getIsBiographyEmpty());
    }
}