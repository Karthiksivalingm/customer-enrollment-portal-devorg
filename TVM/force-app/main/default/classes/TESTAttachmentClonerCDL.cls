@isTest
private class TESTAttachmentClonerCDL {
    
    @testSetup static void setup() {
        // create accounts
        List<Account> acctList = new List<Account>();
        acctList.add(new Account(Name = 'TestAcct (1)',Quickbase_Record_ID__c = '100077'));
        acctList.add(new Account(Name = 'TestAcct (2)',Quickbase_Record_ID__c = '100078'));
        acctList.add(new Account(Name = 'TestAcct (3)',Quickbase_Record_ID__c = '100079'));
        acctList.add(new Account(Name = 'TestAcct (4)',Quickbase_Record_ID__c = '100080'));
        insert acctList;

        // create ContentVersions
        list<ContentVersion> cvList = new list<ContentVersion>();
        cvList.add( new ContentVersion(Title = 'test1',PathOnClient = 'Test1.txt',VersionData = Blob.valueOf('test data 1'), IsMajorVersion = true) );
        cvList.add( new ContentVersion(Title = 'test2',PathOnClient = 'Test2.txt',VersionData = Blob.valueOf('test data 2'), IsMajorVersion = true) );
        cvList.add( new ContentVersion(Title = 'test3',PathOnClient = 'Test3.txt',VersionData = Blob.valueOf('test data 3'), IsMajorVersion = true) );
        insert cvList;

        // retrieve Ids for ContentDocuments created on insert of ContentVersions
        list<Id> cdIdList = new list<Id>();
        for (ContentDocument cd : [SELECT Id, LatestPublishedVersionId
                                   FROM ContentDocument
                                   WHERE (LatestPublishedVersionId = :cvList[0].Id 
                                          OR LatestPublishedVersionId = :cvList[1].Id
                                          OR LatestPublishedVersionId = :cvList[2].Id)
                                   ORDER BY Title]) {
            cdIdList.add(cd.Id);
        }
        system.assertEquals(3, cdIdList.size());
        
        // create ContentDocumentLink links. 2 for TestAcct (1) and 1 for TestAcct (2)
        list<ContentDocumentLink> cdlList = new list<ContentDocumentLink>();
        cdlList.add(new ContentDocumentLink(ContentDocumentId=cdIdList[0], LinkedEntityId=acctList[0].Id, ShareType='V'));
        cdlList.add(new ContentDocumentLink(ContentDocumentId=cdIdList[1], LinkedEntityId=acctList[0].Id, ShareType='V'));
        cdlList.add(new ContentDocumentLink(ContentDocumentId=cdIdList[2], LinkedEntityId=acctList[1].Id, ShareType='V'));
        insert cdlList; 
    }

    @isTest static void testDocumentClone() {
        AttachmentClonerCDL pbcd;
        list<AttachmentClonerCDL> pbcdList = new list<AttachmentClonerCDL>();
        list<Account> acctList = [SELECT Id FROM Account ORDER BY Name];

        // clone from account (1) to (2) - 2 docs
        pbcdList.add(new AttachmentClonerCDL(acctList[0].Id, acctList[1].Id) );
        // clone from account (1) to (3) - 2 docs
        pbcdList.add(new AttachmentClonerCDL(acctList[0].Id, acctList[2].Id) );
        // clone from account (1) to (4) - 2 docs
        pbcdList.add(new AttachmentClonerCDL(acctList[0].Id, acctList[3].Id) );
        // clone from account (2) to (4) - 1 doc
        pbcdList.add(new AttachmentClonerCDL(acctList[1].Id, acctList[3].Id) );
        
        // run AttachmentClonerCDL method
        AttachmentClonerCDL.cloneDocuments(pbcdList);

        // check total number documents
        system.assertEquals(10, [SELECT count() FROM ContentDocument]);
        // check documents linked per account
        system.assertEquals(2, [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId=:acctList[0].Id]);
        system.assertEquals(3, [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId=:acctList[1].Id]);
        system.assertEquals(2, [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId=:acctList[2].Id]);
        system.assertEquals(3, [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId=:acctList[3].Id]);
    }
}