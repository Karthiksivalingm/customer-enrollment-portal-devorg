@isTest
public class triggerOn_ContentDocumentLink_Test {

@isTest public static void mainBioDoc(){
        
        //Create Document Parent Record
        Contact acc = new Contact(LastName='Test Contact',FirstName='datas');
        Insert acc;
        
        //Create Document
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document Bio';
        cv.PathOnClient = 'TestDocumentBio.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        Insert cv;
        
        //Get Content Documents
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
        
        //Create ContentDocumentLink 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = acc.Id;
        cdl.ContentDocumentId = conDocId;
        cdl.shareType = 'V';
        Insert cdl;
    	delete [Select Id from ContentDocument Where ID=:conDocId];
    }
    @isTest public static void mainProjectDoc(){
        
        //Create Document Parent Record
        Contact acc = new Contact(LastName='Test Contact',FirstName='datas');
        Insert acc;
        
        //Create Document
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document Project';
        cv.PathOnClient = 'TestDocumentProject.pdf';
        cv.VersionData = Blob.valueOf('Test Content of Project');
        cv.IsMajorVersion = true;
        Insert cv;
        
        //Get Content Documents
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
        
        //Create ContentDocumentLink 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = acc.Id;
        cdl.ContentDocumentId = conDocId;
        cdl.shareType = 'V';
        Insert cdl;
    }
    
     @isTest public static void contactProjects(){
        
        //Create Document Parent Record
        Contact acc = new Contact(LastName='Test Contact',FirstName='datas');
        Insert acc;
        Project__c proj = new Project__c();
        proj.Contact__c = acc.id;
         proj.Date__c = date.today();
         insert proj; 
        
         //Create Document
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document Project';
        cv.PathOnClient = 'TestDocumentProject.pdf';
        cv.VersionData = Blob.valueOf('Test Content of Project');
        cv.IsMajorVersion = true;
        Insert cv;
        
        //Get Content Documents
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
        
        //Create ContentDocumentLink 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = proj.Id;
        cdl.ContentDocumentId = conDocId;
        cdl.shareType = 'V';
        Insert cdl;
    }
     
    @isTest public static void contactMeetingNdNotes(){
        
        //Create Document Parent Record
        Contact acc = new Contact(LastName='Test Contact',FirstName='datas');
        Insert acc;
        Meeting_Notes__c meeting = new Meeting_Notes__c();
        meeting.Contact__c = acc.id;
         meeting.Date__c = date.today();
         insert meeting; 
        
         //Create Document
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document Meeting';
        cv.PathOnClient = 'TestDocumentProject.pdf';
        cv.VersionData = Blob.valueOf('Test Content of Project');
        cv.IsMajorVersion = true;
        Insert cv;
        
        //Get Content Documents
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
        
        //Create ContentDocumentLink 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = meeting.Id;
        cdl.ContentDocumentId = conDocId;
        cdl.shareType = 'V';
        Insert cdl;
    }
     @isTest public static void contactCommissionNdPurchase(){
        
        //Create Document Parent Record
        Contact acc = new Contact(LastName='Test Contact',FirstName='datas');
        Insert acc;
        Commissions_Purchases__c cps = new Commissions_Purchases__c();
        cps.Contact__c = acc.id;
         cps.Date__c = date.today();
         insert cps; 
        
         //Create Document
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document commissions';
        cv.PathOnClient = 'TestDocumentProject.pdf';
        cv.VersionData = Blob.valueOf('Test Content of Project');
        cv.IsMajorVersion = true;
        Insert cv;
        
        //Get Content Documents
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
        
        //Create ContentDocumentLink 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = cps.Id;
        cdl.ContentDocumentId = conDocId;
        cdl.shareType = 'V';
        Insert cdl;
         
         
    }
}