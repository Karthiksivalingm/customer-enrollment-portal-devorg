@isTest
private class MinutesOfMeetingFileLWCControllerTest {

    private static final String CATEGORY = 'Minutes of Meeting';

    @TestSetup
    static void setupData() {
        insert new Event(
            Subject       = 'Test Event For MoM Files',
            StartDateTime = DateTime.now(),
            EndDateTime   = DateTime.now().addHours(1)
        );

        insert new Event(
            Subject       = 'Test Event With No Files',
            StartDateTime = DateTime.now(),
            EndDateTime   = DateTime.now().addHours(1)
        );
    }

    // Helper: directly insert a ContentVersion + link it to a record,
    // bypassing uploadMinutesOfMeetingFile, so tests can control the
    // Document_Category__c value independently (e.g. to simulate an
    // existing Agenda file that should NOT show up in MoM results).
    private static Id createLinkedContentVersion(Id recordId, String title, String category) {
        ContentVersion cv = new ContentVersion(
            Title = title,
            PathOnClient = title,
            VersionData = Blob.valueOf('Test file body for ' + title),
            Document_Category__c = category
        );
        insert cv;

        Id contentDocumentId = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ].ContentDocumentId;

        insert new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId    = recordId,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );

        return contentDocumentId;
    }

    @isTest
    static void testUploadMinutesOfMeetingFile_Success() {
        Event evt = [SELECT Id FROM Event WHERE Subject = 'Test Event For MoM Files' LIMIT 1];
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Sample MoM content'));

        Test.startTest();
        Id contentDocumentId = MinutesOfMeetingFileLWCController.uploadMinutesOfMeetingFile(
            evt.Id, 'MoM - Upload Test.docx', base64Data
        );
        Test.stopTest();

        System.assertNotEquals(null, contentDocumentId,
            'Expected a ContentDocumentId to be returned after upload');

        ContentVersion cv = [
            SELECT Title, Document_Category__c, ContentDocumentId, FirstPublishLocationId
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId
            AND IsLatest = true
            LIMIT 1
        ];
        System.assertEquals('MoM - Upload Test.docx', cv.Title);
        System.assertEquals(CATEGORY, cv.Document_Category__c,
            'Uploaded file should be tagged as Minutes of Meeting');
        System.assertEquals(evt.Id, cv.FirstPublishLocationId);

        List<ContentDocumentLink> links = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :contentDocumentId
            AND LinkedEntityId = :evt.Id
        ];
        System.assert(!links.isEmpty(),
            'Uploaded file should be linked to the Event via ContentDocumentLink');
    }

    @isTest
    static void testUploadMinutesOfMeetingFile_InvalidRecordId_ThrowsAuraHandledException() {
        // A well-formed but non-existent record Id should cause the insert
        // of ContentVersion (via FirstPublishLocationId) to fail with a
        // DmlException, which the controller wraps in an AuraHandledException.
        Id fakeRecordId = Id.valueOf('701000000000000AAA'); // fake Event-shaped Id
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Sample content'));

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            MinutesOfMeetingFileLWCController.uploadMinutesOfMeetingFile(
                fakeRecordId, 'Bad Record Test.docx', base64Data
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown,
            'Expected AuraHandledException when FirstPublishLocationId points to a non-existent record');
    }

    @isTest
    static void testGetMinutesOfMeetingFiles_ReturnsOnlyTaggedFiles() {
        Event evt = [SELECT Id FROM Event WHERE Subject = 'Test Event For MoM Files' LIMIT 1];

        // One file tagged as Minutes of Meeting
        createLinkedContentVersion(evt.Id, 'MoM - Test.docx', CATEGORY);
        // One file NOT tagged as Minutes of Meeting (simulates an Agenda file)
        createLinkedContentVersion(evt.Id, 'Agenda - Test.pdf', '');
        // One file with no category set at all
        createLinkedContentVersion(evt.Id, 'Untagged - Test.txt', null);

        Test.startTest();
        List<ContentVersion> results =
            MinutesOfMeetingFileLWCController.getMinutesOfMeetingFiles(evt.Id);
        Test.stopTest();

        System.assertEquals(1, results.size(),
            'Expected only the file tagged as Minutes of Meeting to be returned');
        System.assertEquals('MoM - Test.docx', results[0].Title);
       // System.assertEquals(CATEGORY, results[0].Document_Category__c);
    }

    @isTest
    static void testGetMinutesOfMeetingFiles_NoLinkedFiles_ReturnsEmptyList() {
        Event evt = [SELECT Id FROM Event WHERE Subject = 'Test Event With No Files' LIMIT 1];

        Test.startTest();
        List<ContentVersion> results =
            MinutesOfMeetingFileLWCController.getMinutesOfMeetingFiles(evt.Id);
        Test.stopTest();

        System.assertEquals(0, results.size(),
            'Expected empty list when the record has no linked files at all');
    }

    @isTest
    static void testGetMinutesOfMeetingFiles_LinkedFilesButNoneTagged_ReturnsEmptyList() {
        Event evt = [SELECT Id FROM Event WHERE Subject = 'Test Event For MoM Files' LIMIT 1];

        // Files exist and are linked, but none are tagged as Minutes of Meeting
        createLinkedContentVersion(evt.Id, 'Agenda - Only.pdf', '');

        Test.startTest();
        List<ContentVersion> results =
            MinutesOfMeetingFileLWCController.getMinutesOfMeetingFiles(evt.Id);
        Test.stopTest();

        System.assertEquals(0, results.size(),
            'Expected empty list when linked files exist but none are tagged as Minutes of Meeting');
    }

    @isTest
    static void testTagAsMinutesOfMeeting_Success() {
        Event evt = [SELECT Id FROM Event WHERE Subject = 'Test Event For MoM Files' LIMIT 1];
        Id contentDocumentId = createLinkedContentVersion(evt.Id, 'Untagged File.docx', null);

        Test.startTest();
        MinutesOfMeetingFileLWCController.tagAsMinutesOfMeeting(contentDocumentId);
        Test.stopTest();

        ContentVersion updated = [
            SELECT Document_Category__c
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId
            AND IsLatest = true
            LIMIT 1
        ];
        System.assertEquals(CATEGORY, updated.Document_Category__c,
            'File should be tagged as Minutes of Meeting after calling tagAsMinutesOfMeeting');
    }

    @isTest
    static void testTagAsMinutesOfMeeting_FileNotFound_ThrowsAuraHandledException() {
        // A well-formed but non-existent ContentDocument Id
        Id fakeContentDocumentId = Id.valueOf('069000000000000AAA');

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            MinutesOfMeetingFileLWCController.tagAsMinutesOfMeeting(fakeContentDocumentId);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown,
            'Expected AuraHandledException when no ContentVersion matches the given ContentDocumentId');
    }
}