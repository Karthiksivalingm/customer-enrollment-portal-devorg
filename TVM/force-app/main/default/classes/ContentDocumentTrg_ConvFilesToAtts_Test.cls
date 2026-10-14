/** - - - - - - - - - - - - - - - - - - - - - -
 * Purpose: Purpose of this class is test behaviour 
 * and cover ContentDocumentTrg_ConvFilesToAtts.cls
 * - - - - - - - - - - - - - - - - - - - - - -
 * Revision History:
 * Date          Version      Author                 Changes
 * 2020-12-08     1.0         Robert Szollosy       initial dev
 */
@IsTest(seeAllData=false)
public  class ContentDocumentTrg_ConvFilesToAtts_Test {
    
    /**
	 * This test method testPosInsert1AttWithoutInterComm contains unit tests for cover AttachmentTriggerHelper class.
	 * Scenario: Create attachment on Account object. The IsPartnerShared flag is not updated.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
     * 1. Test: Create 1 account.
     *          Create 1 attachment. ParentId = account mention above.
     *          Insert attachment.
 	 * Expectations: The IsPartnerShared = false.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
	 */
    @isTest
    static void testPos_1ConntetDocument(){
		String unitTestName = 'testPos_1ConntetDocument';

        //Create test data
        Account objAcc = new Account(Name = 'Acc_'+unitTestName);
        insert objAcc;

        Integer size = 1;

        ContentVersion[] lstContentVersions = new ContentVersion[]{};
        ContentDocumentLink[] lstContentDocumentLinks = new ContentDocumentLink[]{};

        for(Integer i = 0; i < size; i++){
            lstContentVersions.add(new ContentVersion(
                Title = 'Test',
                PathOnClient = 'Test.jpg',
                VersionData = Blob.valueOf('Test Content Data'),
                IsMajorVersion = true
            ));
        }

        insert lstContentVersions;

        lstContentVersions = [SELECT Id, Title, ContentDocumentId 
                                FROM ContentVersion 
                                WHERE Id IN :lstContentVersions];

        for(Integer i = 0; i < size; i++){
            lstContentDocumentLinks.add(new ContentDocumentLink(
                LinkedEntityId =  objAcc.id,
                ContentDocumentId = lstContentVersions[i].ContentDocumentId,
                shareType = 'V'
            ));
        }   
        
        insert lstContentDocumentLinks;

        map<Id,Id> mapLinkedEntityIdByContentDocId = new map<Id,Id>();
        for(ContentDocumentLink tmpCDL : lstContentDocumentLinks){
            mapLinkedEntityIdByContentDocId.put(tmpCDL.ContentDocumentId, tmpCDL.LinkedEntityId);
        }

        //RUN TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before start test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before start test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StartTest();

        Attachment[] lstAttach = ContentDocumentTrg_ConvFilesToAtts.convertFilesToAttchs(mapLinkedEntityIdByContentDocId);
            
        // STOP TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StopTest();
    
        System.assertEquals(size, lstAttach.size(), 
        'It was expected that ' + size + 'attachment will be created but we got '+ lstAttach.size());
        System.assertEquals(objAcc.Id, lstAttach[0].ParentId, 
        'Incorrect ParentId for new attachment');

       //GOVERNOR_LIMITS
	    system.debug(LoggingLevel.ERROR, 'SOQL query usage at the end of ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage at the end of ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
    }//end  testPos_1ConntetDocument()

    /**
	 * This test method testPos_2ConntetDocument contains unit tests for cover AttachmentTriggerHelper class.
	 * Scenario: Create attachment on Account object. The IsPartnerShared flag is not updated.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
     * 1. Test: Create 1 account.
     *          Create 1 case.
     *          Create 2 attachment. ParentId = account / case mention above.
     *          Insert attachment.
 	 * Expectations: The IsPartnerShared = false.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
	 */ 
    @isTest
    static void testPos_2ConntetDocument(){
		String unitTestName = 'testPos_2ConntetDocument';

        //Create test data
        Account objAcc = new Account(Name = 'Acc_'+unitTestName);
        insert objAcc;
        Case objCase = new Case(
            Status_Filtered__c= 'New',
            Origin = 'Web'
        );
        insert objCase;

        Integer size = 2;

        ContentVersion[] lstContentVersions = new ContentVersion[]{};
        ContentDocumentLink[] lstContentDocumentLinks = new ContentDocumentLink[]{};

        ContentVersion objCVAccount = new ContentVersion(
            Title = 'Test_Acc',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        lstContentVersions.Add(objCVAccount);

        ContentVersion objCVCase = new ContentVersion(
            Title = 'Test_Case',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        lstContentVersions.Add(objCVCase);
        
        insert lstContentVersions;

        // We expected that 1 -> objCVAccount, and 0 -> objCVCase
        lstContentVersions = [SELECT Id, Title, ContentDocumentId 
                                FROM ContentVersion 
                                WHERE Id IN :lstContentVersions
                                Order By Title DESC];

        for(Integer i = 0; i < size; i++){
            lstContentDocumentLinks.add(new ContentDocumentLink(
                LinkedEntityId =  i == 1 ? objAcc.id : objCase.id,
                ContentDocumentId = lstContentVersions[i].ContentDocumentId,
                shareType = 'V'
            ));
        }   
        
        insert lstContentDocumentLinks;

        map<Id,Id> mapLinkedEntityIdByContentDocId = new map<Id,Id>();
        for(ContentDocumentLink tmpCDL : lstContentDocumentLinks){
            mapLinkedEntityIdByContentDocId.put(tmpCDL.ContentDocumentId, tmpCDL.LinkedEntityId);
        }

        //RUN TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before start test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before start test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StartTest();
		
        Attachment[] lstAttach = ContentDocumentTrg_ConvFilesToAtts.convertFilesToAttchs(mapLinkedEntityIdByContentDocId);
            
        // STOP TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StopTest();
            
        System.assertEquals(size, lstAttach.size(), 
        'It was expected that ' + size + 'attachment will be created but we got '+ lstAttach.size());

        //We got 2 records.
        Integer resAcc = 0;
        Integer resCase = 0;

        for(Attachment tmpAtt : lstAttach){
            if(tmpAtt.ParentId ==  objAcc.id && tmpAtt.Name.contains(objCVAccount.Title)){
                resAcc += 1;
            }else if(tmpAtt.ParentId ==  objCase.id && tmpAtt.Name.contains(objCVCase.Title)){
                resCase += 1;
            }
        }
        
        System.assertEquals(1, resAcc, 'New attachment for the account was created incorrectly');
        System.assertEquals(1, resCase, 'New attachment for the case was created incorrectly');

       //GOVERNOR_LIMITS
	    system.debug(LoggingLevel.ERROR, 'SOQL query usage at the end of ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage at the end of ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
    }//end  testPos_2ConntetDocument

    /**
	 * This test method testNull contains unit tests for cover ContentDocumentTrg_ConvFilesToAtts class.
	 * Scenario: Create attachment on Account object. The IsPartnerShared flag is not updated.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
     * 1. Test: Send NULL to convertFilesToAttchs(size)
 	 * Expectations: The code should not crash.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
	 */
    @isTest
    static void testNull(){
		String unitTestName = 'testNull';

        //RUN TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before start test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before start test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StartTest();

        Attachment[] lstAttach = ContentDocumentTrg_ConvFilesToAtts.convertFilesToAttchs(NULL);
            
        // STOP TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StopTest();
    
        System.assertEquals(0, lstAttach.size(), 
        'It was expected that 0 attachment will be created but we got '+ lstAttach.size());
        
       //GOVERNOR_LIMITS
	    system.debug(LoggingLevel.ERROR, 'SOQL query usage at the end of ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage at the end of ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
    }//end  testNull()

    /**
	 * This test method testMoreFiles_AllFiles contains unit tests for cover ContentDocumentTrg_ConvFilesToAtts class.
	 * Scenario: Create attachment on Account object. The IsPartnerShared flag is not updated.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
     * 1. Test: Create a list of IDs
     *          Query 1 profile.
     *          Create 1 User.
     *          Create 1 Task.
     *          Create 1 contact.
     *          Create 1 Account.
     *          Create 1 Case.
     *          Insert attachment.
     * Map mapLinkedEntityIdByContentDocId is created.
 	 * Expectations: System asserts that listIDs[i] and lstAttach[i].ParentId match.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
	 */
    @isTest
    static void testMoreFiles_AllFiles(){
		String unitTestName = 'testMoreFiles_AllFiles';
        list<id> listIDs = new list<id>();
        //Create test data
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'asdfwe', Email='testUserName12332@testing.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='testUserName12332@testing.com');
        insert u;

        Task objTask = new Task(Status = 'Not Started', Subject = 'Email', Priority = 'Normal', OwnerId = u.Id );
        insert objTask;
             
        Contact objContact = new Contact(LastName ='TestName' );
        insert objContact;
        
        Account objAcc = new Account(Name = 'Acc_'+unitTestName);
        insert objAcc;
        
        Case objCase = new Case(Status_Filtered__c= 'Open');
        insert objCase;

        listIDs.add(objTask.id);
        listIDs.add(objContact.id);
        listIDs.add(objAcc.id);
        listIDs.add(objCase.id);

        Integer size = listIDs.size();

        ContentVersion[] lstContentVersions = new ContentVersion[]{};
        ContentDocumentLink[] lstContentDocumentLinks = new ContentDocumentLink[]{};

        for(Integer i = 0; i < size; i++){
            lstContentVersions.add(new ContentVersion(
                Title = 'Test',
                PathOnClient = 'Test.jpg',
                VersionData = Blob.valueOf('Test Content Data'),
                IsMajorVersion = true
            ));
        }

        insert lstContentVersions;

        lstContentVersions = [SELECT Id, Title, ContentDocumentId 
                                FROM ContentVersion 
                                WHERE Id IN :lstContentVersions];

        for(Integer i = 0; i < size; i++){
            lstContentDocumentLinks.add(new ContentDocumentLink(
                LinkedEntityId =  listIDs.get(i),
                ContentDocumentId = lstContentVersions[i].ContentDocumentId,
                shareType = 'V'
            ));
        }               
        insert lstContentDocumentLinks;
        map<Id,Id> mapLinkedEntityIdByContentDocId = new map<Id,Id>();
        for(ContentDocumentLink tmpCDL : lstContentDocumentLinks){
            mapLinkedEntityIdByContentDocId.put(tmpCDL.ContentDocumentId, tmpCDL.LinkedEntityId);
        }
        //RUN TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before start test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before start test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StartTest();
  
        Attachment[] lstAttach = ContentDocumentTrg_ConvFilesToAtts.convertFilesToAttchs(mapLinkedEntityIdByContentDocId);             
        
        // STOP TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StopTest();

        System.assertEquals(size, lstAttach.size(), 
        'It was expected that ' + size + 'attachment will be created but we got '+ lstAttach.size());
        
        for(Integer i = 0; i < size; i++){
            System.assertEquals(true,listIds.contains(lstAttach[i].ParentId), 
            'Incorrect ParentId for new attachment');
        }

        //GOVERNOR_LIMITS
	    system.debug(LoggingLevel.ERROR, 'SOQL query usage at the end of ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage at the end of ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
    }//end testMoreFiles_AllFiles
}