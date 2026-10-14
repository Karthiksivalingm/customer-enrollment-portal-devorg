/** - - - - - - - - - - - - - - - - - - - - - -
 * Purpose: Purpose of this class is test behaviour 
 * and cover DeleteFilesInIntergroupCommObject.cls
 * - - - - - - - - - - - - - - - - - - - - - -
 * Revision History:
 * Date          Version      Author                Changes
 * 2020-12-08     1.0         Robert Szollosy       initial dev
 * 2021-01-08     1.1         Michaela Tarhanicova  add FOR UPDATE to select. (It should lock an record for this test class)
 */
@isTest(seeAllData=true)
public class DeleteFilesInIntergroupCommObject_Test {
    /**
     * Because the Case and Intergroup_Communication__c are shared by Salesforce 2 Salesforce,
     * we need in test class used anotation seeAllData=true. We need case records to be 
     * already accepted in second salesforce enviroment. 
     * For this reason we cannot created test case in the test class but we need to get case from real world. :)
     * Good article:
     * http://cropredysfdc.com/2014/11/17/s2s-salesforce-to-salesforce-adventures/
     */

     /**
	 * This test method testPos_AllFiles contains unit tests for cover DeleteFilesInIntergroupCommObject class.
	 * Scenario: Create attachment on Intergroup_Communication__c object.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
     * 1. Test: Create 1 Intergroup_Communication__c.
     *          Create 1 file on Intergroup_Communication__c.
     *          When the ContentDocumentLink is insered, the queueble job is called.
 	 * Expectations: All files are deleted.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
	 */
    @isTest
    static void testPos_AllFiles(){
		String unitTestName = 'testPos_AllFiles';

        //Create test data
        // We need to get the REAL case because of Salesforce 2 Salesforce.
        Case[] lstCases = [SELECT Id FROM Case WHERE IsShared__c = true LIMIT 1 FOR UPDATE];      
        System.assertEquals(1, lstCases.size(), 'At least one case should existi in the salesforce. Thank you.');

        Intergroup_Communication__c objIntergroupComm = new Intergroup_Communication__c(
            Case__c = lstCases[0].Id
        );
        insert objIntergroupComm;

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
                LinkedEntityId =  objIntergroupComm.id,
                ContentDocumentId = lstContentVersions[i].ContentDocumentId,
                shareType = 'V'
            ));
        }               
        
        //RUN TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before start test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before start test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StartTest();
  
        // System.enqueueJob(new DeleteFilesInIntergroupCommObject(**SOME DATA***));
        insert lstContentDocumentLinks;       
        
        // STOP TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StopTest();

        Integer cdlSize = [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId = :objIntergroupComm.id];
        System.AssertEquals(0, cdlSize,
        'All files related to this record were deleted. But ' + cdlSize +' files still exists.');

        //GOVERNOR_LIMITS
	    system.debug(LoggingLevel.ERROR, 'SOQL query usage at the end of ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage at the end of ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
    }//end testPos_AllFiles
  
    /**
	 * This test method testNeg_AllFiles contains unit tests for cover DeleteFilesInIntergroupCommObject class.
	 * Scenario: Create attachment on Intergroup_Communication__c object.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
     * 1. Test: Create 1 Account.
     *          When the ContentDocumentLink is insered, the queueble job is called.
 	 * Expectations: File is present.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
	 */
    @isTest    
    static void testNeg_AllFiles(){
		String unitTestName = 'testNeg_AllFiles';

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
        
        //RUN TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before start test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before start test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StartTest();
  
        // System.enqueueJob(new DeleteFilesInIntergroupCommObject(**SOME DATA***));
        insert lstContentDocumentLinks;       
        
        // STOP TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StopTest();

        Integer cdlSize = [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId = :objAcc.id];
        System.AssertEquals(size, cdlSize,
        'All files related to this record should not be deleted.');

        //GOVERNOR_LIMITS
	    system.debug(LoggingLevel.ERROR, 'SOQL query usage at the end of ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage at the end of ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
    }//end testNeg_AllFiles

    /**
	 * This test method testMoreFiles_AllFiles contains unit tests for cover DeleteFilesInIntergroupCommObject class.
	 * Scenario: Create attachment on Intergroup_Communication__c object.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
     * 1. Test: Create 1 Intergroup_Communication__c.
     *          Create 1 Case.
     *          Create 1 Account.
     *          Create 3 files on Intergroup_Communication__c.
     *          When the ContentDocumentLink is insered, the queueble job is called.
 	 * Expectations: 2 Files are present.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
	 */
    @isTest
    static void testMoreFiles_AllFiles(){
        String unitTestName = 'testMoreFiles_AllFiles';
        
        //Create test data
        list<id> listIDs = new list<id>();
            
        // We need to get the REAL case because of Salesforce 2 Salesforce.
        Case[] lstCases = [SELECT Id FROM Case WHERE IsShared__c = true LIMIT 1 FOR UPDATE];      
        System.assertEquals(1, lstCases.size(), 'At least one case should existi in the salesforce. Thank you.');
     
        Intergroup_Communication__c objIntergroupComm = new Intergroup_Communication__c(
            Case__c = lstCases[0].Id
        );
        insert objIntergroupComm;
     
        Account objAcc = new Account(Name = 'Acc_'+unitTestName);
        insert objAcc;
     
        listIDs.add(lstCases[0].id);
        listIDs.add(objIntergroupComm.id);
        listIDs.add(objAcc.id);

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
        
        //RUN TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before start test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before start test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StartTest();
  
        // System.enqueueJob(new DeleteFilesInIntergroupCommObject(**SOME DATA***));
        insert lstContentDocumentLinks;       
        
        // STOP TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StopTest();

        Integer cdlSize = [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId = :listIDs];
        System.AssertEquals(listIDs.size()-1, cdlSize,
        'All files related to this recrd were deleted. But ' + cdlSize +' files still exists');

        //GOVERNOR_LIMITS
	    system.debug(LoggingLevel.ERROR, 'SOQL query usage at the end of ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage at the end of ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
    }//end testMoreFiles_AllFiles
}