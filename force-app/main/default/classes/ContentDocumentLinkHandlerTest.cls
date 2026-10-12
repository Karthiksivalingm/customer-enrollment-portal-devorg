@isTest
private class ContentDocumentLinkHandlerTest {

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

    private static Id createContentDocument(String title) {
        ContentVersion cv = new ContentVersion(
            Title        = title,
            PathOnClient = title + '.pdf',
            VersionData  = Blob.valueOf('file content for ' + title)
        );
        insert cv;
        return [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id
        ].ContentDocumentId;
    }

    // ── Helper: EmailMessage with RelatedToId only (ActivityId is NOT
    //    directly writable via DML — it is system-managed) ──────────────────
    private static EmailMessage createEmailMessage(Account acc, String subject) {
        EmailMessage em = new EmailMessage(
            Subject     = subject,
            FromAddress = 'vendor@example.com',
            ToAddress   = 'team@company.com',
            RelatedToId = acc.Id
        );
        insert em;
        return em;
    }

    // ── Path A: EAC sets RelatedToId directly to Account ─────────────────────
    @isTest
    static void testEAC_RelatedToId_LinksFileToAccount() {
        Account acc = createAccount('EAC Direct Account');
        EmailMessage em = createEmailMessage(acc, 'Purchase Order attached');
        Id docId = createContentDocument('EAC_PO_Direct');

        Test.startTest();
        insert new ContentDocumentLink(
            ContentDocumentId = docId,
            LinkedEntityId    = em.Id,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );
        Test.stopTest();

        List<ContentDocumentLink> accountLinks = [
            SELECT Id FROM ContentDocumentLink
            WHERE ContentDocumentId = :docId
              AND LinkedEntityId = :acc.Id
        ];
        System.assertEquals(1, accountLinks.size(),
            'File should be linked to Account via RelatedToId path');

        ContentVersion cv = [
            SELECT Document_Type__c FROM ContentVersion
            WHERE ContentDocumentId = :docId AND IsLatest = true
        ];
        System.assertEquals('Purchase Order', cv.Document_Type__c,
            'File should be tagged as Purchase Order');
    }

    // ── No duplicate links created if file already on Account ─────────────────
    @isTest
    static void testEAC_NoDuplicateLinkCreated() {
        Account acc = createAccount('No Dupe Account');
        EmailMessage em = createEmailMessage(acc, 'Duplicate test');
        Id docId = createContentDocument('EAC_NoDupe');

        insert new ContentDocumentLink(
            ContentDocumentId = docId,
            LinkedEntityId    = acc.Id,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );

        Test.startTest();
        insert new ContentDocumentLink(
            ContentDocumentId = docId,
            LinkedEntityId    = em.Id,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );
        Test.stopTest();

        List<ContentDocumentLink> accountLinks = [
            SELECT Id FROM ContentDocumentLink
            WHERE ContentDocumentId = :docId
              AND LinkedEntityId = :acc.Id
        ];
        System.assertEquals(1, accountLinks.size(),
            'Should not create a duplicate link on the Account');
    }

    // ── Non-email CDL (e.g. direct Account upload) does not get processed ─────
    @isTest
    static void testNonEmailLink_IsIgnored() {
        Account acc = createAccount('Direct Upload Account');
        Id docId = createContentDocument('Direct_Upload');

        Integer linksBefore = [
            SELECT COUNT() FROM ContentDocumentLink
            WHERE ContentDocumentId = :docId
        ];

        Test.startTest();
        insert new ContentDocumentLink(
            ContentDocumentId = docId,
            LinkedEntityId    = acc.Id,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );
        Test.stopTest();

        Integer linksAfter = [
            SELECT COUNT() FROM ContentDocumentLink
            WHERE ContentDocumentId = :docId
        ];

        System.assertEquals(linksBefore + 1, linksAfter,
            'Trigger should not create extra links for non-email CDLs');
    }

    // ── Bulk: 5 emails with attachments all processed in one trigger call ─────
    @isTest
    static void testBulk_MultipleEmailAttachments() {
        Account acc = createAccount('Bulk Test Account');

        List<EmailMessage> emails = new List<EmailMessage>();
        for (Integer i = 0; i < 5; i++) {
            emails.add(new EmailMessage(
                Subject     = 'Bulk Email ' + i,
                FromAddress = 'vendor' + i + '@example.com',
                ToAddress   = 'team@company.com',
                RelatedToId = acc.Id
            ));
        }
        insert emails;

        List<Id> docIds = new List<Id>();
        for (Integer i = 0; i < 5; i++) {
            docIds.add(createContentDocument('Bulk_PO_' + i));
        }

        List<ContentDocumentLink> emailLinks = new List<ContentDocumentLink>();
        for (Integer i = 0; i < 5; i++) {
            emailLinks.add(new ContentDocumentLink(
                ContentDocumentId = docIds[i],
                LinkedEntityId    = emails[i].Id,
                ShareType         = 'V',
                Visibility        = 'AllUsers'
            ));
        }

        Test.startTest();
        insert emailLinks;
        Test.stopTest();

        Integer accountLinkCount = [
            SELECT COUNT() FROM ContentDocumentLink
            WHERE ContentDocumentId IN :docIds
              AND LinkedEntityId = :acc.Id
        ];
        System.assertEquals(5, accountLinkCount,
            'All 5 bulk email attachments should be linked to Account');

        List<ContentVersion> tagged = [
            SELECT Document_Type__c FROM ContentVersion
            WHERE ContentDocumentId IN :docIds
              AND IsLatest = true
        ];
        for (ContentVersion cv : tagged) {
            System.assertEquals('Purchase Order', cv.Document_Type__c,
                'All bulk files should be tagged as Purchase Order');
        }
    }

    // ── Email related to non-Account record (e.g. Opportunity) — skip it ──────
    @isTest
    static void testEAC_NonAccountRelatedTo_IsSkipped() {
        Account acc = createAccount('Opp Parent');

        Opportunity opp = new Opportunity(
            Name      = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        // RelatedToId points to Opportunity, not Account
        EmailMessage em = new EmailMessage(
            Subject     = 'Opp attachment',
            FromAddress = 'a@b.com',
            ToAddress   = 'c@d.com',
            RelatedToId = opp.Id
        );
        insert em;

        Id docId = createContentDocument('Opp_File');

        Test.startTest();
        insert new ContentDocumentLink(
            ContentDocumentId = docId,
            LinkedEntityId    = em.Id,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );
        Test.stopTest();

        List<ContentDocumentLink> accountLinks = [
            SELECT Id FROM ContentDocumentLink
            WHERE ContentDocumentId = :docId
              AND LinkedEntityId = :acc.Id
        ];
        System.assertEquals(0, accountLinks.size(),
            'File linked to Opp email should not be copied to Account');
    }
}