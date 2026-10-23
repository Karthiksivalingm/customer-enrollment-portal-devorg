@IsTest
private class CertificateAttachmentServiceTest {

    private static Contact newVendor() {
        Account a = new Account(Name = 'Cert Test Vendor', Type = 'Non-Profit');
        insert as system a;
        Id rt = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Sales_Vendor').getRecordTypeId();
        Contact c = new Contact(LastName = 'Cert Test', AccountId = a.Id, RecordTypeId = rt);
        insert as system c;
        return c;
    }

    private static ContentVersion newFile(Id contactId, String title, String category) {
        ContentVersion cv = new ContentVersion(Title = title, PathOnClient = title + '.pdf', VersionData = Blob.valueOf('file ' + title),
            FirstPublishLocationId = contactId, Certificate_Category__c = category);
        insert as system cv;
        return cv;
    }

    private static CertificateAttachmentService.Request req(Id contactId, List<String> versionIds, String category) {
        CertificateAttachmentService.Request r = new CertificateAttachmentService.Request();
        r.contactId = contactId; r.contentVersionIds = versionIds; r.category = category;
        return r;
    }

    private static List<Attachment> attachments(Id contactId) {
        return [SELECT Name, Body FROM Attachment WHERE ParentId = :contactId WITH SYSTEM_MODE ORDER BY Name];
    }

    @IsTest
    static void copiesUploadedCertificateToAttachment() {
        Contact c = newVendor();
        ContentVersion cv = newFile(c.Id, 'COI 2026', 'COI');
        Test.startTest();
        CertificateAttachmentService.copyToAttachments(new List<CertificateAttachmentService.Request>{ req(c.Id, new List<String>{ cv.Id }, 'COI') });
        Test.stopTest();
        List<Attachment> atts = attachments(c.Id);
        System.assertEquals(1, atts.size());
        System.assertEquals('[COI] COI 2026.pdf', atts[0].Name);
        System.assertEquals('file COI 2026', atts[0].Body.toString());
    }

    @IsTest
    static void directlyAddedFilesAreNotCopied() {
        Contact c = newVendor();
        newFile(c.Id, 'Direct upload', null);
        Test.startTest();
        CertificateAttachmentService.copyToAttachments(new List<CertificateAttachmentService.Request>{ req(c.Id, new List<String>(), 'COI') });
        Test.stopTest();
        System.assertEquals(0, attachments(c.Id).size(), 'nothing is copied unless the component passes the file');
    }

    @IsTest
    static void newUploadReplacesSameCategoryAndKeepsOthers() {
        Contact c = newVendor();
        ContentVersion oldCoi = newFile(c.Id, 'Old COI', 'COI');
        ContentVersion w9 = newFile(c.Id, 'W9', 'W-9');
        CertificateAttachmentService.backfill(new Set<Id>{ c.Id });
        System.assertEquals(2, attachments(c.Id).size());
        ContentVersion newCoi = newFile(c.Id, 'New COI', 'COI');
        Test.startTest();
        CertificateAttachmentService.copyToAttachments(new List<CertificateAttachmentService.Request>{ req(c.Id, new List<String>{ newCoi.Id }, 'COI') });
        Test.stopTest();
        List<Attachment> atts = attachments(c.Id);
        System.assertEquals(2, atts.size());
        System.assertEquals('[COI] New COI.pdf', atts[0].Name);
        System.assertEquals('[W-9] W9.pdf', atts[1].Name);
    }

    @IsTest
    static void bulk200Files() {
        Contact c = newVendor();
        List<ContentVersion> files = new List<ContentVersion>();
        for (Integer i = 0; i < 200; i++) {
            files.add(new ContentVersion(Title = 'F' + i, PathOnClient = 'F' + i + '.pdf', VersionData = Blob.valueOf('x' + i),
                FirstPublishLocationId = c.Id, Certificate_Category__c = 'Food Service'));
        }
        insert as system files;
        List<String> ids = new List<String>();
        for (ContentVersion cv : files) { ids.add(cv.Id); }
        Test.startTest();
        CertificateAttachmentService.copyToAttachments(new List<CertificateAttachmentService.Request>{ req(c.Id, ids, 'Food Service') });
        Test.stopTest();
        System.assertEquals(200, attachments(c.Id).size());
    }

    @IsTest
    static void worksForUserWithoutContactEditAccess() {
        Contact c = newVendor();
        ContentVersion cv = newFile(c.Id, 'COI', 'COI');
        User u = [SELECT Id FROM User WHERE Profile.Name = 'Ticket Sales' AND IsActive = true LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            CertificateAttachmentService.copyToAttachments(new List<CertificateAttachmentService.Request>{ req(c.Id, new List<String>{ cv.Id }, 'COI') });
            Test.stopTest();
        }
        System.assertEquals(1, attachments(c.Id).size(), 'the copy runs in system mode for the Upload Certificate flow');
    }
}
