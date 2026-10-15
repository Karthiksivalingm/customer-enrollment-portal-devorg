@isTest
private class TestProfilePictureController {

    // Helper to create a Contact we can attach files to
    private static Id createContact() {
        Contact cn = new Contact(FirstName = 'ABC', LastName = 'Test');
        insert cn;
        return cn.Id;
    }

    // Helper to create an image Attachment on a parent record
    private static Attachment createAttachment(Id parentId, String name, String contentType, Blob body) {
        Attachment attach = new Attachment();
        attach.Name = name;
        attach.Body = body;
        attach.ParentId = parentId;
        attach.ContentType = contentType;
        insert attach;
        return attach;
    }

    @isTest
    static void testGetProfilePicture_returnsLatestImage() {
        Id conId = createContact();
        Attachment firstInserted = createAttachment(conId, 'Should Be Overtaken', 'image/jpeg', Blob.valueOf('older body'));
        createAttachment(conId, 'Ignored - Not Latest', 'image/png', Blob.valueOf('other body'));

        // Records inserted in the same transaction can share an identical LastModifiedDate,
        // so ordering by it alone is not reliable. Force firstInserted to be the most recently
        // modified by performing a distinct update on it.
        firstInserted.Name = 'Newest Image';
        update firstInserted;

        Test.startTest();
        Attachment result = ProfilePictureController.getProfilePicture(conId);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected an attachment to be returned');
        System.assertEquals('Newest Image', result.Name, 'Expected most recently modified image to be returned');
    }

    @isTest
    static void testGetProfilePictureBase64_returnsDataUri() {
        Id conId = createContact();
        createAttachment(conId, 'Profile.png', 'image/png', Blob.valueOf('small image body'));

        Test.startTest();
        String result = ProfilePictureController.getProfilePictureBase64(conId);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected a base64 data URI to be returned');
        System.assert(result.startsWith('data:image/png;base64,'), 'Expected proper data URI prefix');
    }

    @isTest
    static void testGetProfilePictureBase64_noAttachment_returnsNull() {
        Id conId = createContact();

        Test.startTest();
        String result = ProfilePictureController.getProfilePictureBase64(conId);
        Test.stopTest();

        System.assertEquals(null, result, 'Expected null when no image attachment exists');
    }

    @isTest
    static void testGetProfilePictureBase64_tooLarge_throwsException() {
        Id conId = createContact();

        // Build a body larger than 2,000,000 bytes using doubling, since Apex strings are
        // immutable and repeated single-chunk concatenation (O(n^2)) exceeds the CPU time limit.
        String bigString = '0123456789';
        while (bigString.length() < 2100000) {
            bigString += bigString;
        }
        createAttachment(conId, 'Huge.png', 'image/png', Blob.valueOf(bigString));

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            ProfilePictureController.getProfilePictureBase64(conId);
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Expected AuraHandledException for oversized image');
    }

    @isTest
    static void testSaveAttachment_insertsNewWhenNoneExists() {
        Id conId = createContact();
        String base64Body = EncodingUtil.base64Encode(Blob.valueOf('brand new image'));

        Test.startTest();
        Id newId = ProfilePictureController.saveAttachment(conId, 'newFile.png', base64Body, 'image/png');
        Test.stopTest();

        System.assertNotEquals(null, newId, 'Expected a new attachment Id to be returned');

        List<Attachment> results = [SELECT Id, Name, ContentType, ParentId FROM Attachment WHERE ParentId = :conId];
        System.assertEquals(1, results.size(), 'Expected exactly one attachment to exist');
        System.assertEquals('newFile.png', results[0].Name);
    }

    @isTest
    static void testSaveAttachment_updatesExistingInsteadOfDuplicating() {
        Id conId = createContact();
        Attachment original = createAttachment(conId, 'original.png', 'image/png', Blob.valueOf('original body'));

        String base64Body = EncodingUtil.base64Encode(Blob.valueOf('updated image body'));

        Test.startTest();
        Id resultId = ProfilePictureController.saveAttachment(conId, 'updated.jpg', base64Body, 'image/jpeg');
        Test.stopTest();

        System.assertEquals(original.Id, resultId, 'Expected existing attachment to be updated, not a new one created');

        List<Attachment> results = [SELECT Id, Name, ContentType, Body FROM Attachment WHERE ParentId = :conId];
        System.assertEquals(1, results.size(), 'Expected no duplicate attachment to be created');
        System.assertEquals('updated.jpg', results[0].Name);
        System.assertEquals('image/jpeg', results[0].ContentType);
        System.assertEquals('updated image body', results[0].Body.toString());
    }

    @isTest
    static void testDeleteAttachment_removesImageAttachments() {
        Id conId = createContact();
        createAttachment(conId, 'toDelete1.png', 'image/png', Blob.valueOf('body 1'));
        createAttachment(conId, 'toDelete2.gif', 'image/gif', Blob.valueOf('body 2'));

        Test.startTest();
        ProfilePictureController.deleteAttachment(conId);
        Test.stopTest();

        List<Attachment> remaining = [SELECT Id FROM Attachment WHERE ParentId = :conId];
        System.assertEquals(0, remaining.size(), 'Expected all image attachments to be deleted');
    }

    @isTest
    static void testDeleteAttachment_noAttachments_doesNotThrow() {
        Id conId = createContact();

        Test.startTest();
        try {
            ProfilePictureController.deleteAttachment(conId);
            System.assert(true, 'Expected no exception when there is nothing to delete');
        } catch (Exception ex) {
            System.assert(false, 'Did not expect an exception: ' + ex.getMessage());
        }
        Test.stopTest();
    }
}