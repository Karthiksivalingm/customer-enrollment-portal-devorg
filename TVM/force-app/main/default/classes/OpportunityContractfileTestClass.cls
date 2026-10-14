@istest
public class OpportunityContractfileTestClass {
    
    @isTest(seeAllData = true)
    static void oppContractFileTriggerTest(){    
                
        /*
        Account objacc = New Account();
        objacc.name = 'test';    
        insert objacc;
        
        Opportunity objopp = new Opportunity();
        objopp.Name='test';
        objopp.RecordTypeId='0125f000000e5TjAAI';    
        objopp.AccountId = objacc.Id;
        objopp.StageName = 'Negotiation';
        objopp.CloseDate = system.today();
        insert objopp;
        */
        
        List<Opportunity> lstopp = [Select Id from Opportunity where AccountId != null AND RecordTypeId='0125f000000e5TjAAI' AND StageName = 'Closed Won' Limit 1];
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        Insert cv;
       
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = lstopp[0].Id;
        cdl.ContentDocumentId = conDocId;
        Insert cdl;

        Opportunity opp = new Opportunity();
        opp.id = lstopp[0].id;
        
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());
        opp.StageName = 'Contract Sent';
        update opp;
        opp.StageName = 'Closed Won';
        update opp;
        test.stopTest(); 
    }
}