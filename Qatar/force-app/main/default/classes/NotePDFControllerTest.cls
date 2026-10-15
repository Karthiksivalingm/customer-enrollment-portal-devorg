@isTest
private class NotePDFControllerTest {

    @isTest
    static void testControllerWithValidCvId() {
        ContentNote note = new ContentNote();
        note.Title   = 'PDF Controller Test Note';
        note.Content = Blob.valueOf('<p>Test content for PDF controller</p>');
        insert note;

        ContentVersion cv = [
            SELECT Id
            FROM ContentVersion
            WHERE ContentDocumentId = :note.Id
            AND IsLatest = true
            LIMIT 1
        ];

        Test.startTest();
        PageReference pageRef = Page.NotePDFTemplate;
        pageRef.getParameters().put('cvId',      cv.Id);
        pageRef.getParameters().put('eventName', 'Test Event Name');
        Test.setCurrentPage(pageRef);

        NotePDFController controller = new NotePDFController();
        Test.stopTest();

        System.assertEquals('Test Event Name', controller.title, 'Title should match event name');
        System.assertNotEquals('', controller.content,           'Content should not be empty');
    }

    @isTest
    static void testControllerWithNoCvId() {
        Test.startTest();
        PageReference pageRef = Page.NotePDFTemplate;
        pageRef.getParameters().put('eventName', 'Test Event');
        Test.setCurrentPage(pageRef);

        NotePDFController controller = new NotePDFController();
        Test.stopTest();

        System.assertEquals('Test Event', controller.title, 'Title should be set');
        System.assertEquals('',           controller.content, 'Content should be empty');
    }

    @isTest
    static void testControllerWithNoParams() {
        Test.startTest();
        PageReference pageRef = Page.NotePDFTemplate;
        Test.setCurrentPage(pageRef);

        NotePDFController controller = new NotePDFController();
        Test.stopTest();

        System.assertEquals('Untitled', controller.title, 'Title should default to Untitled');
        System.assertEquals('',         controller.content, 'Content should be empty');
    }
}