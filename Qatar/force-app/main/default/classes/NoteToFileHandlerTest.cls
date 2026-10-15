@isTest
private class NoteToFileHandlerTest {

    @isTest
    static void testNoteToFileHandler() {
        // Create a test Event
        Event testEvent = new Event();
        testEvent.Subject       = 'Test Event';
        testEvent.StartDateTime = DateTime.now();
        testEvent.EndDateTime   = DateTime.now().addHours(1);
        insert testEvent;

        // Create a ContentNote
        ContentNote note = new ContentNote();
        note.Title   = 'Test Note';
        note.Content = Blob.valueOf('<p>This is test note content</p>');
        insert note;

        // Get ContentVersion Id
        ContentVersion cv = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE ContentDocumentId = :note.Id
            AND IsLatest = true
            LIMIT 1
        ];

        List<String> contentDocIds   = new List<String>{ cv.ContentDocumentId };
        List<String> linkedEntityIds = new List<String>{ testEvent.Id };

        Test.startTest();
        System.enqueueJob(new NoteToFileHandler(contentDocIds, linkedEntityIds));
        Test.stopTest();

        // Verify PDF was created
        List<ContentVersion> pdfs = [
            SELECT Id, Title, FileType
            FROM ContentVersion
            WHERE Title LIKE 'HE Notes -%'
        ];

        System.assertNotEquals(0, pdfs.size(), 'PDF should have been generated');
        System.assert(pdfs[0].Title.startsWith('HE Notes -'), 'PDF title should start with HE Notes -');
    }

    @isTest
    static void testNoteToFileHandlerSkipsNonNotes() {
        // Create a test Event
        Event testEvent = new Event();
        testEvent.Subject       = 'Test Event Skip';
        testEvent.StartDateTime = DateTime.now();
        testEvent.EndDateTime   = DateTime.now().addHours(1);
        insert testEvent;

        // Create a regular file (not a note)
        ContentVersion cv = new ContentVersion();
        cv.Title        = 'Regular File';
        cv.PathOnClient = 'RegularFile.txt';
        cv.VersionData  = Blob.valueOf('This is a regular file');
        insert cv;

        ContentVersion insertedCV = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];

        List<String> contentDocIds   = new List<String>{ insertedCV.ContentDocumentId };
        List<String> linkedEntityIds = new List<String>{ testEvent.Id };

        Test.startTest();
        System.enqueueJob(new NoteToFileHandler(contentDocIds, linkedEntityIds));
        Test.stopTest();

        // Verify no PDF was created for non-note file
        List<ContentVersion> pdfs = [
            SELECT Id FROM ContentVersion
            WHERE Title LIKE 'HE Notes -%'
        ];

        System.assertEquals(0, pdfs.size(), 'No PDF should be generated for non-note files');
    }

    @isTest
    static void testTriggerFires() {
        // Create a test Event
        Event testEvent = new Event();
        testEvent.Subject       = 'Trigger Test Event';
        testEvent.StartDateTime = DateTime.now();
        testEvent.EndDateTime   = DateTime.now().addHours(1);
        insert testEvent;

        // Create a ContentNote
        ContentNote note = new ContentNote();
        note.Title   = 'Trigger Test Note';
        note.Content = Blob.valueOf('<p>Trigger test content</p>');
        insert note;

        Test.startTest();
        // Link note to Event — this fires the trigger
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = note.Id;
        cdl.LinkedEntityId    = testEvent.Id;
        cdl.ShareType         = 'V';
        cdl.Visibility        = 'AllUsers';
        insert cdl;
        Test.stopTest();

        // Verify Queueable job was enqueued
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, JobType
            FROM AsyncApexJob
            WHERE JobType = 'Queueable'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertNotEquals(0, jobs.size(), 'Queueable job should have been enqueued');
    }
}