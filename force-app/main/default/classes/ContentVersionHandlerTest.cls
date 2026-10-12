@isTest
private class ContentVersionHandlerTest {

    private static Id storeRtId =
        Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Store Location').getRecordTypeId();

    private static Account createAccount(String name) {
        Account acc = new Account(
            Name                = name,
            RecordTypeId        = storeRtId,
            ShippingStreet      = '1 Test Street',
            ShippingCity        = 'New York',
            ShippingState       = 'NY',
            ShippingPostalCode  = '10001',
            ShippingCountry     = 'US'
        );
        insert acc;
        return acc;
    }

    // ── Helper: Account + EmailMessage(RelatedToId) + email-linked PO file ───
    private static Id createEmailLinkedDoc(Account acc, String title) {
        EmailMessage em = new EmailMessage(
            Subject     = 'PO Email',
            FromAddress = 'vendor@example.com',
            ToAddress   = 'team@company.com',
            RelatedToId = acc.Id
        );
        insert em;

        ContentVersion cv = new ContentVersion(
            Title        = title,
            PathOnClient = title + '.pdf',
            VersionData  = Blob.valueOf('content for ' + title)
        );
        insert cv;

        Id docId = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id
        ].ContentDocumentId;

        // Linking to EmailMessage fires ContentDocumentLinkHandler,
        // which auto-creates the Account CDL + tags as 'Purchase Order'
        insert new ContentDocumentLink(
            ContentDocumentId = docId,
            LinkedEntityId    = em.Id,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );

        return docId;
    }

    // ── Helper: count CDLs on a doc where LinkedEntityId is an Account ────────
    private static Integer countAccountLinks(Id docId) {
        Integer count = 0;
        for (ContentDocumentLink cdl : [
            SELECT LinkedEntityId FROM ContentDocumentLink
            WHERE ContentDocumentId = :docId
        ]) {
            if (String.valueOf(cdl.LinkedEntityId).startsWith('001')) {
                count++;
            }
        }
        return count;
    }

    // ── Uncheck PO: CDL on Account stays (standard Files list unaffected) ────
    @isTest
    static void testUncheckPO_KeepsAccountLink() {
        Account acc = createAccount('Uncheck Test Account');
        Id docId    = createEmailLinkedDoc(acc, 'PO_Uncheck');

        Test.startTest();
        ContentVersion cv = [
            SELECT Id, Document_Type__c FROM ContentVersion
            WHERE ContentDocumentId = :docId AND IsLatest = true
        ];
        cv.Document_Type__c = null;
        update cv;
        Test.stopTest();

        List<ContentDocumentLink> accountLinks = [
            SELECT Id FROM ContentDocumentLink
            WHERE ContentDocumentId = :docId AND LinkedEntityId = :acc.Id
        ];
        System.assertEquals(1, accountLinks.size(),
            'Account CDL should remain after unchecking PO');

        ContentVersion updated = [
            SELECT Document_Type__c FROM ContentVersion
            WHERE ContentDocumentId = :docId AND IsLatest = true
        ];
        System.assertEquals(null, updated.Document_Type__c,
            'Document_Type__c should be cleared');
    }

    // ── Re-check PO after CDL was removed → handler recreates it ─────────────
    @isTest
    static void testCheckPO_RecreatesAccountLink() {
        Account acc = createAccount('Recreate Link Account');
        Id docId    = createEmailLinkedDoc(acc, 'PO_Recreate');

        delete [
            SELECT Id FROM ContentDocumentLink
            WHERE ContentDocumentId = :docId AND LinkedEntityId = :acc.Id
        ];
        ContentVersion cv = [
            SELECT Id FROM ContentVersion
            WHERE ContentDocumentId = :docId AND IsLatest = true
        ];
        cv.Document_Type__c = null;
        update cv;

        Test.startTest();
        cv.Document_Type__c = 'Purchase Order';
        update cv;
        Test.stopTest();

        List<ContentDocumentLink> accountLinks = [
            SELECT Id FROM ContentDocumentLink
            WHERE ContentDocumentId = :docId AND LinkedEntityId = :acc.Id
        ];
        System.assertEquals(1, accountLinks.size(),
            'CDL should be recreated on Account when PO re-checked');
    }

    // ── No duplicate CDL when toggled off then on, already linked ────────────
    @isTest
    static void testCheckPO_NoDuplicateWhenAlreadyLinked() {
        Account acc = createAccount('No Dupe Account');
        Id docId    = createEmailLinkedDoc(acc, 'PO_NoDupe');

        Test.startTest();
        ContentVersion cv = [
            SELECT Id, Document_Type__c FROM ContentVersion
            WHERE ContentDocumentId = :docId AND IsLatest = true
        ];
        cv.Document_Type__c = null;
        update cv;
        cv.Document_Type__c = 'Purchase Order';
        update cv;
        Test.stopTest();

        Integer linkCount = [
            SELECT COUNT() FROM ContentDocumentLink
            WHERE ContentDocumentId = :docId AND LinkedEntityId = :acc.Id
        ];
        System.assertEquals(1, linkCount,
            'Should not create duplicate CDL on Account');
    }

    // ── Bulk update: multiple files toggled off in one DML ────────────────────
    @isTest
    static void testBulkToggle_MultipleFiles() {
        Account acc = createAccount('Bulk Toggle Account');

        Id doc1 = createEmailLinkedDoc(acc, 'Bulk_1');
        Id doc2 = createEmailLinkedDoc(acc, 'Bulk_2');

        List<ContentVersion> versions = [
            SELECT Id, Document_Type__c FROM ContentVersion
            WHERE ContentDocumentId IN (:doc1, :doc2) AND IsLatest = true
        ];
        for (ContentVersion cv : versions) cv.Document_Type__c = null;

        Test.startTest();
        update versions;
        Test.stopTest();

        List<ContentVersion> updated = [
            SELECT Document_Type__c FROM ContentVersion
            WHERE ContentDocumentId IN (:doc1, :doc2) AND IsLatest = true
        ];
        for (ContentVersion cv : updated) {
            System.assertEquals(null, cv.Document_Type__c,
                'All files in bulk update should be unchecked');
        }
    }

    // ── No-op: unrelated field change, Document_Type__c untouched ────────────
    @isTest
    static void testNoOp_WhenDocumentTypeUnchanged() {
        Account acc = createAccount('NoOp Account');
        Id docId    = createEmailLinkedDoc(acc, 'NoOp_File');

        Test.startTest();
        ContentVersion cv = [
            SELECT Id, Title, Document_Type__c FROM ContentVersion
            WHERE ContentDocumentId = :docId AND IsLatest = true
        ];
        cv.Title = 'NoOp_File_Renamed';
        update cv;
        Test.stopTest();

        Integer linkCount = [
            SELECT COUNT() FROM ContentDocumentLink
            WHERE ContentDocumentId = :docId AND LinkedEntityId = :acc.Id
        ];
        System.assertEquals(1, linkCount,
            'CDL should be unaffected when Document_Type__c does not change');
    }

    // ── Check PO with no resolvable Account (no EmailMessage CDL) → no-op ─────
    @isTest
    static void testCheckPO_NoEmailLink_NoAccountCdlCreated() {
        ContentVersion cv = new ContentVersion(
            Title        = 'Standalone_File',
            PathOnClient = 'Standalone_File.pdf',
            VersionData  = Blob.valueOf('standalone content')
        );
        insert cv;

        Id docId = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id
        ].ContentDocumentId;

        // Scoped to Account-type links only — Salesforce auto-creates a CDL
        // to the owning User (005 prefix) on ContentVersion insert, which is
        // expected platform behavior and not relevant to this handler
        Integer accountLinksBefore = countAccountLinks(docId);
        System.assertEquals(0, accountLinksBefore,
            'Sanity check: standalone file should start with zero Account CDLs');

        Test.startTest();
        ContentVersion toUpdate = [
            SELECT Id, Document_Type__c FROM ContentVersion
            WHERE ContentDocumentId = :docId AND IsLatest = true
        ];
        toUpdate.Document_Type__c = 'Purchase Order';
        update toUpdate;
        Test.stopTest();

        Integer accountLinksAfter = countAccountLinks(docId);
        System.assertEquals(0, accountLinksAfter,
            'No Account CDL should be created since there is no EmailMessage link to resolve from');
    }
}