@isTest
private class PurchaseOrderFilesControllerTest {

    private static Id storeRtId =
        Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Store Location').getRecordTypeId();

    private static Account createAccount(String name) {
        Account acc = new Account(
            Name               = name,
            RecordTypeId       = storeRtId,
            ShippingStreet     = '1 Test Street',
            ShippingCity       = 'New York',
            ShippingState      = 'NY',
            ShippingPostalCode = '10001',
            ShippingCountry    = 'US'
        );
        insert acc;
        return acc;
    }

    @TestSetup
    static void makeData() {
        Account acc = createAccount('Test PO Account');

        ContentVersion cv1 = new ContentVersion(
            Title            = 'Invoice_001',
            PathOnClient     = 'Invoice_001.pdf',
            VersionData      = Blob.valueOf('pdf content one'),
            Document_Type__c = 'Purchase Order'
        );
        insert cv1;

        ContentVersion cv1Fetched = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv1.Id
        ];
        insert new ContentDocumentLink(
            ContentDocumentId = cv1Fetched.ContentDocumentId,
            LinkedEntityId    = acc.Id,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );

        ContentVersion cv2 = new ContentVersion(
            Title        = 'General_Doc',
            PathOnClient = 'General_Doc.docx',
            VersionData  = Blob.valueOf('word content')
        );
        insert cv2;

        ContentVersion cv2Fetched = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv2.Id
        ];
        insert new ContentDocumentLink(
            ContentDocumentId = cv2Fetched.ContentDocumentId,
            LinkedEntityId    = acc.Id,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );
    }

    @isTest
    static void testGetFiles_FilteredToPurchaseOrders() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<PurchaseOrderFilesController.FileWrapper> results =
            PurchaseOrderFilesController.getPurchaseOrderFiles(acc.Id, true);
        Test.stopTest();

        System.assertEquals(1, results.size(),
            'Should return only 1 Purchase Order file when filterByType = true');
        System.assertEquals('Invoice_001', results[0].title);
        System.assertEquals('Purchase Order', results[0].documentType);
        System.assertNotEquals(null, results[0].downloadUrl,
            'downloadUrl should be populated');
        System.assertNotEquals(null, results[0].contentDocumentId,
            'contentDocumentId should be populated');
    }

    @isTest
    static void testGetFiles_Unfiltered() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<PurchaseOrderFilesController.FileWrapper> results =
            PurchaseOrderFilesController.getPurchaseOrderFiles(acc.Id, false);
        Test.stopTest();

        System.assertEquals(2, results.size(),
            'Should return all 2 files when filterByType = false');
    }

    @isTest
    static void testGetFiles_NoFilesOnRecord() {
        Account emptyAcc = createAccount('Empty Account');

        Test.startTest();
        List<PurchaseOrderFilesController.FileWrapper> results =
            PurchaseOrderFilesController.getPurchaseOrderFiles(emptyAcc.Id, true);
        Test.stopTest();

        System.assertEquals(0, results.size(),
            'Should return empty list when no files are linked');
    }

    @isTest
    static void testGetFiles_WrapperFieldsPopulated() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<PurchaseOrderFilesController.FileWrapper> results =
            PurchaseOrderFilesController.getPurchaseOrderFiles(acc.Id, true);
        Test.stopTest();

        PurchaseOrderFilesController.FileWrapper fw = results[0];
        System.assertNotEquals(null, fw.contentDocumentId);
        System.assertNotEquals(null, fw.title);
        System.assertNotEquals(null, fw.contentSize);
        System.assertNotEquals(null, fw.lastModifiedDate);
        System.assertNotEquals(null, fw.ownerName);
        System.assert(fw.downloadUrl.contains('/sfc/servlet.shepherd/document/download/'),
            'downloadUrl should use the shepherd download path');
    }

    @isTest
    static void testUploadFile_CreatesTaggedFile() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        String base64 = EncodingUtil.base64Encode(Blob.valueOf('test file content'));

        Test.startTest();
        Id docId = PurchaseOrderFilesController.uploadFile(
            base64, 'PO_Upload_Test.pdf', acc.Id
        );
        Test.stopTest();

        System.assertNotEquals(null, docId, 'Should return a ContentDocumentId');

        ContentVersion cv = [
            SELECT Document_Type__c, Title
            FROM ContentVersion
            WHERE ContentDocumentId = :docId
              AND IsLatest = true
        ];
        System.assertEquals('Purchase Order', cv.Document_Type__c,
            'Uploaded file should be tagged as Purchase Order');
        System.assertEquals('PO_Upload_Test.pdf', cv.Title);

        List<ContentDocumentLink> links = [
            SELECT Id FROM ContentDocumentLink
            WHERE ContentDocumentId = :docId
              AND LinkedEntityId = :acc.Id
        ];
        System.assertEquals(1, links.size(),
            'File should be linked to the Account');
    }

    @isTest
    static void testUploadFile_MultipleFiles() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        String base64 = EncodingUtil.base64Encode(Blob.valueOf('content'));

        Test.startTest();
        Id docId1 = PurchaseOrderFilesController.uploadFile(base64, 'PO_A.pdf', acc.Id);
        Id docId2 = PurchaseOrderFilesController.uploadFile(base64, 'PO_B.xlsx', acc.Id);
        Test.stopTest();

        System.assertNotEquals(null, docId1);
        System.assertNotEquals(null, docId2);
        System.assertNotEquals(docId1, docId2,
            'Each upload should create a distinct ContentDocument');
    }

    @isTest
    static void testTagFiles_TagsUntaggedFile() {
        ContentVersion cv = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Title = 'General_Doc'
              AND IsLatest = true
            LIMIT 1
        ];

        Test.startTest();
        PurchaseOrderFilesController.tagFilesAsPurchaseOrder(
            new List<Id>{ cv.ContentDocumentId }
        );
        Test.stopTest();

        ContentVersion updated = [
            SELECT Document_Type__c
            FROM ContentVersion
            WHERE ContentDocumentId = :cv.ContentDocumentId
              AND IsLatest = true
        ];
        System.assertEquals('Purchase Order', updated.Document_Type__c,
            'File should now be tagged as Purchase Order');
    }

    @isTest
    static void testTagFiles_EmptyList() {
        Test.startTest();
        PurchaseOrderFilesController.tagFilesAsPurchaseOrder(new List<Id>());
        Test.stopTest();
        System.assert(true, 'Empty list should be handled without error');
    }

    @isTest
    static void testTagFiles_NullList() {
        Test.startTest();
        PurchaseOrderFilesController.tagFilesAsPurchaseOrder(null);
        Test.stopTest();
        System.assert(true, 'Null list should be handled without error');
    }

    // ── togglePurchaseOrder — checks PO on (new method coverage) ──────────────
    @isTest
    static void testTogglePO_CheckOn() {
        ContentVersion cv = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Title = 'General_Doc'
              AND IsLatest = true
            LIMIT 1
        ];

        Test.startTest();
        PurchaseOrderFilesController.togglePurchaseOrder(cv.ContentDocumentId, true);
        Test.stopTest();

        ContentVersion updated = [
            SELECT Document_Type__c FROM ContentVersion
            WHERE ContentDocumentId = :cv.ContentDocumentId AND IsLatest = true
        ];
        System.assertEquals('Purchase Order', updated.Document_Type__c,
            'togglePurchaseOrder(true) should tag the file as Purchase Order');
    }

    // ── togglePurchaseOrder — unchecks PO off (new method coverage) ───────────
    @isTest
    static void testTogglePO_CheckOff() {
        ContentVersion cv = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Title = 'Invoice_001'
              AND IsLatest = true
            LIMIT 1
        ];

        Test.startTest();
        PurchaseOrderFilesController.togglePurchaseOrder(cv.ContentDocumentId, false);
        Test.stopTest();

        ContentVersion updated = [
            SELECT Document_Type__c FROM ContentVersion
            WHERE ContentDocumentId = :cv.ContentDocumentId AND IsLatest = true
        ];
        System.assertEquals(null, updated.Document_Type__c,
            'togglePurchaseOrder(false) should clear Document_Type__c');
    }

    // ── togglePurchaseOrder — null contentDocumentId is a no-op ───────────────
    @isTest
    static void testTogglePO_NullId_NoOp() {
        Test.startTest();
        PurchaseOrderFilesController.togglePurchaseOrder(null, true);
        Test.stopTest();
        System.assert(true, 'Null contentDocumentId should be handled without error');
    }

    @isTest
    static void testDeleteFile_RemovesDocument() {
        ContentVersion cv = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Title = 'Invoice_001'
              AND IsLatest = true
            LIMIT 1
        ];
        Id docId = cv.ContentDocumentId;

        Test.startTest();
        PurchaseOrderFilesController.deleteFile(docId);
        Test.stopTest();

        List<ContentDocument> remaining = [
            SELECT Id FROM ContentDocument WHERE Id = :docId
        ];
        System.assertEquals(0, remaining.size(),
            'ContentDocument should be deleted');
    }

    @isTest
    static void testDeleteFile_NonExistentId() {
        ContentVersion cv = new ContentVersion(
            Title        = 'Temp',
            PathOnClient = 'Temp.pdf',
            VersionData  = Blob.valueOf('x')
        );
        insert cv;
        ContentVersion fetched = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id
        ];
        Id docId = fetched.ContentDocumentId;
        delete [SELECT Id FROM ContentDocument WHERE Id = :docId];

        Test.startTest();
        PurchaseOrderFilesController.deleteFile(docId);
        Test.stopTest();
        System.assert(true, 'Deleting non-existent file should not throw');
    }
}