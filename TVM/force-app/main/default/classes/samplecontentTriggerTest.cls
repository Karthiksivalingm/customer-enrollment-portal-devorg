@isTest
Public class samplecontentTriggerTest {
    
   @isTest(seeAllData = true) 
    static void contentversionTriggerTest(){
       
       Account acc = new Account();
       acc.name = 'test';
       insert acc;
       
       opportunity opp = new  opportunity();
       opp.RecordTypeId='0125f000000e5TjAAI';
       opp.name ='test';
       opp.AccountId= acc.id;
       opp.StageName = 'Closed Won';
       opp.CloseDate = system.today();
       insert opp;
       
       
       //List<Opportunity> lstopp = [Select Id from Opportunity where AccountId != null Limit 1];
       
       ContentVersion cv = new ContentVersion();
       cv.Title = 'Test Document';
       cv.PathOnClient = 'TestDocument.pdf';
       cv.VersionData = Blob.valueOf('Test Content');
       cv.IsMajorVersion = true;
       Insert cv;
       
       Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
       ContentDocumentLink cdl = New ContentDocumentLink();
       cdl.LinkedEntityId = opp.Id;
       cdl.ContentDocumentId = conDocId;
       Insert cdl;
       
       ContentVersion cv1 = new ContentVersion();
       cv1.Title = 'Test Document_1';
       cv1.PathOnClient = 'TestDocument_1.pdf';
       cv1.VersionData = Blob.valueOf('Test Content_1');
       cv1.ContentDocumentId = conDocId;
       cv1.IsMajorVersion = true;
       Insert cv1;
           
    }
}