@isTest
public class TESTCopyFileAsAttachment {
	@isTest
    private static void CopyFileAsAttachment() {
        Case testcase = new Case(
        	OEM__c='KIA',
        	Case_Category__c='Production Support'
        );
		upsert testcase;
        
        ContentVersion contentVersionInsert = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert contentVersionInsert;
        
        ContentVersion contentVersionSelect = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionInsert.Id LIMIT 1];
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        System.assertEquals(documents.size(), 1);
        
        ContentDocumentLink id1 = new ContentDocumentLink(
        	ContentDocumentId=documents[0].Id,
            LinkedEntityId=testcase.Id
        );
        
		upsert id1;
        
        List<List<ContentDocumentLink>> tests = new List<List<ContentDocumentLink>>();
        
        tests.add(new List<ContentDocumentLink>{id1});
        
        Test.startTest();
        CopyFileAsAttachment.createAttachments(tests);
        Test.stopTest();
	}
}