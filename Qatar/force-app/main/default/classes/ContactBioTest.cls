@isTest
private class ContactBioTest {

    @isTest
    static void testContactBioController() {
        // Step 1: Create a Contact record
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@test.com',
            Phone = '9999999999',
            Title = 'Manager',
            Instagram_Handle__c = '@johndoe',
            Professional_Personal_Backgrounds__c = 'Paragraph1\nParagraph2\n' +
                String.join(new List<String>{'ExtraContent '}, '\n').repeat(100),
            Email_Office__c = 'john.office@test.com',
            Company__c = 'Test Company'
        );
        insert con;

        // Step 2: Create an Attachment (latest image)
        Attachment att = new Attachment(
            Name = 'profile.jpg',
            Body = Blob.valueOf('SampleImage'),
            ParentId = con.Id,
            ContentType = 'image/jpeg'
        );
        insert att;

        // Step 3: Simulate Visualforce page context with Contact Id parameter
        Test.startTest();
        PageReference pageRef = Page.ContactBio; // Make sure VF page name = ContactBio
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', con.Id);

        // Step 4: Instantiate controller
        ContactBio controller = new ContactBio();

        Test.stopTest();

        // Step 5: Assertions
        System.assertNotEquals(null, controller.Con, 'Contact should be fetched');
        System.assertEquals(con.Id, controller.Con.Id, 'Fetched Contact should match inserted one');
        System.assertNotEquals(null, controller.Attach, 'Attachment should be fetched');
        System.assert(controller.Attach.ContentType.startsWith('image'), 'Attachment should be image type');
        System.assert(controller.ParagraphChunks.size() > 0, 'Paragraph chunks should be populated');

        // Verify header (filename set)
        String headerValue = ApexPages.currentPage().getHeaders().get('Content-Disposition');
        System.assert(headerValue.contains('Bio - John Doe'), 'Filename header should contain Contact name');
    }

    @isTest
    static void testContactBio_NoAttachment_NoBackground() {
        // Step 1: Create a Contact without background text
        Contact con = new Contact(
            FirstName = 'Jane',
            LastName = 'Smith',
            Email = 'jane.smith@test.com'
        );
        insert con;

        // Step 2: Simulate VF context
        Test.startTest();
        PageReference pageRef = Page.ContactBio;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', con.Id);

        // Step 3: Instantiate controller
        ContactBio controller = new ContactBio();
        Test.stopTest();

        // Step 4: Assertions
        System.assertNotEquals(null, controller.Con, 'Contact should be fetched');
        System.assertEquals(null, controller.Attach, 'No attachment should be found');
        System.assertEquals(0, controller.ParagraphChunks.size(), 'No paragraphs should be split');
    }
}