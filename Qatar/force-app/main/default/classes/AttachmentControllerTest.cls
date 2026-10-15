@IsTest
private class AttachmentControllerTest {

    @IsTest
    static void testGetAttachmentUrl() {
        // Create a dummy parent record (Account) with required field
        Account acc = new Account(
            Name = 'Test Account',
            BillingCountry = 'India' // Required by validation rule
        );
        insert acc;

        // Create a test attachment with image content type
        Attachment att = new Attachment(
            Name = 'TestImage.png',
            ParentId = acc.Id,
            Body = Blob.valueOf('Test Image Body'),
            ContentType = 'image/png'
        );
        insert att;

        // Call the method
        Test.startTest();
        String url = AttachmentController.getAttachmentUrl(acc.Id);
        Test.stopTest();

        // Validate the result
        System.assertNotEquals(null, url, 'URL should not be null');
        System.assert(url.contains(att.Id), 'URL should contain attachment Id');
        System.assert(url.startsWith('/servlet/servlet.FileDownload?file='), 'URL format is correct');
    }

    @IsTest
    static void testNoAttachmentFound() {
        // Create a dummy parent record (Account) with required field
        Account acc2 = new Account(
            Name = 'No Attachment Account',
            BillingCountry = 'India' // Required by validation rule
        );
        insert acc2;

        Test.startTest();
        String url = AttachmentController.getAttachmentUrl(acc2.Id);
        Test.stopTest();

        // Expecting null since there are no image attachments
        System.assertEquals(null, url, 'URL should be null when no attachment exists');
    }
}