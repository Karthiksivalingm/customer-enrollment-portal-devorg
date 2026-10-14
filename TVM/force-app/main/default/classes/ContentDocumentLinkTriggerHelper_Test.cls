/*
* ContentDocumentLinkTriggerHelper_Test
* - - - - - - - - - - - - - - - - - - - - - - 
* Author: Robert Szollosy
* - - - - - - - - - - - - - - - - - - - - - -
* Purpose: Purpose of this class is test behaviour 
* and cover for ContentDocumentLinkTriggerHelper.cls
* - - - - - - - - - - - - - - - - - - - - - -
* Revision History:
* Date          Version      Author                 Changes
* 2020-12-23       1.0       Robert Szollosy       initial dev
* 2021-01-08       1.1       Michaela Tarhanicova  add FOR UPDATE to select. (It should lock an record for this test class)
*/
@isTest(seeAllData=true)
public class ContentDocumentLinkTriggerHelper_Test {
     /**
     * Because the Case and Intergroup_Communication__c are shared by Salesforce 2 Salesforce,
     * we need in test class used anotation seeAllData=true. We need case records to be 
     * already accepted in second salesforce enviroment. 
     * For this reason we cannot created test case in the test class but we need to get case from real world. :)
     * Good article:
     * http://cropredysfdc.com/2014/11/17/s2s-salesforce-to-salesforce-adventures/
     */

     /**
	 * This test method testIntergroupPos contains unit tests for covering ContentDocumentLinkTriggerHelper class.
	 * Scenario: Create attachment on Account object. The IsPartnerShared flag is not updated.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
     * 1. Test: Query 1 case.
     *          Create 1 file on Intergroup_Communication__c.
     *          When the ContentDocumentLink is insered, the queueble job is called.
 	 * Expectations: System asserts that objIntergroupCommunication.id and lstAttachment[0].parentID match.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
	 */
    @isTest
    static void testIntergroupPos(){
        String unitTestName = 'testIntergroupPos';

        //Create test data
        Case[] lstCases = [SELECT Id FROM Case WHERE IsShared__c = true LIMIT 1 FOR UPDATE];      
        System.assertEquals(1, lstCases.size(), 'At least one case should exist in the salesforce. Thank you.');

        Intergroup_Communication__c objIntergroupCommunication = new Intergroup_Communication__c(
            Case__c = lstCases[0].id,
            Name = 'TestIntergroupCommunication'
        );
        insert objIntergroupCommunication;

        Integer size = 1;

        ContentVersion[] lstContentVersions = new ContentVersion[]{};
        ContentDocumentLink[] lstContentDocumentLinks = new ContentDocumentLink[]{};

        for(Integer i = 0; i < size; i++){
            lstContentVersions.add(new ContentVersion(
                Title = 'TestTitle',
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
                LinkedEntityId = objIntergroupCommunication.id,
                ContentDocumentId = lstContentVersions[i].ContentDocumentId,
                shareType = 'V'
            ));
        }          

        //RUN TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before start test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before start test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StartTest();

        insert lstContentDocumentLinks; 
        
        // STOP TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StopTest();
        
        Attachment[] lstAttachment = [SELECT ID,parentID FROM Attachment WHERE parentID = :objIntergroupCommunication.id];
        System.AssertEquals(1,lstAttachment.size(),'We are expecting 1 attachment for related record of intergroup communication.');
        System.assertEquals(objIntergroupCommunication.id, lstAttachment[0].parentID, 
        'ObjIntergroupCommunication.id and lstAttachment.parentID do not match');
    }//end testIntergroupPos
}