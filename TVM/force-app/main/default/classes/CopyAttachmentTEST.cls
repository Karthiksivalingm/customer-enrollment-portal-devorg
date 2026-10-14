@isTest
public class CopyAttachmentTEST {
	@isTest
    private static void CopyFileAsAttachment() {
        Case testcasesource = new Case(
        	OEM__c='KIA',
        	Case_Category__c='Production Support'
        );
		upsert testcasesource;
        
        Case testcasedest = new Case(
        	OEM__c='HONDA',
        	Case_Category__c='Production Support'
        );
		upsert testcasedest;
                
        String sid = testcasesource.id;
        String did = testcasedest.id;
        
        Blob b = Blob.valueOf('Test Data');
    	
    	Attachment attachment = new Attachment();
    	attachment.ParentId = sid;
    	attachment.Name = 'Test Attachment for Parent';
    	attachment.Body = b;
    	
    	insert(attachment);
        
        System.Debug(attachment.Id);
        System.Debug(attachment.ParentId);
        
        List <CopyAttachment> testobjlist = new List <CopyAttachment>();
        CopyAttachment testobj = new CopyAttachment(sid, did);
        testobjlist.add(testobj);
                
        Test.startTest();
        CopyAttachment.createAttachments(testobjlist);
        Test.stopTest();
	}

}