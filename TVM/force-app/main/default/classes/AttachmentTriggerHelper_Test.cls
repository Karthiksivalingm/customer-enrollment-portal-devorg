/** - - - - - - - - - - - - - - - - - - - - - -
 * AttachmentTriggerHelper_Test
 * - - - - - - - - - - - - - - - - - - - - - - 
 * Author: Michaela Tarhanicova
 * - - - - - - - - - - - - - - - - - - - - - -
 * Purpose: Purpose of this class is test behaviour 
 * and cover AttachmentTriggerHelper.cls and 
 * AttachmentTrigger.trigger.
 * - - - - - - - - - - - - - - - - - - - - - -
 * Revision History:
 * Date          Version      Author                 Changes
 * 2020-12-08       1.0       Michaela Tarhanicova   initial dev
 * 2021-01-08       1.1       Michaela Tarhanicva    add new asserts to test creating record of SF2SF_Sharing_Queue__c object.
 *                                                   add FOR UPDATE to select. (It should lock an record for this test class)
 */
@isTest(seeAllData=true)
public class AttachmentTriggerHelper_Test {
    /**
     * Because the Case and Intergroup_Communication__c are shared by Salesforce 2 Salesforce,
     * we need in test class used anotation seeAllData=true. We need case records to be 
     * already accepted in second salesforce enviroment. 
     * For this reason we cannot created test case in the test class but we need to get case from real world. :)
     * Good article:
     * http://cropredysfdc.com/2014/11/17/s2s-salesforce-to-salesforce-adventures/
     * 
     * Tester note: 
     * This is a pice of code that simulate "sending to next enviriment". But status of this connection is Invatid.
     * PartnerNetworkConnection parentNetworkCon = [SELECT Id, ConnectionStatus, ConnectionName, ContactId 
     * FROM PartnerNetworkConnection WHERE ConnectionStatus = 'Accepted' Limit 1];
     * 
     * PartnerNetworkRecordConnection newrecord = new PartnerNetworkRecordConnection();
     * newrecord.ConnectionId = parentNetworkCon.Id;
     * newrecord.LocalRecordId   = objIntergroupComm.id;
     * newrecord.RelatedRecords = 'Attachment';
     * newrecord.SendClosedTasks = true;
     * newrecord.SendOpenTasks = true;
     * newrecord.SendEmails = true;   
     * insert newrecord;
     * 
     * Note (2021-01-08)
     * Nevertheless, we have a new logic that can catch record on Integration communication and Attachment 
     * which parents are not synchronizes via Salesforce 2 Salesforce, we cannot delete change seeAllData to false.
     * If we do that we got a CUSTOM_VALIDATIN error. 
     * Text of error: Case has not been shared externally so Intergroup Communications cannot be created on this Case. 
     * First share the Case externally and then try again.
     */

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
    static void testPosInsert1AttWithoutInterComm(){
		String unitTestName = 'testPosInsert1AttWithoutInterComm';

        //Create test data
        Account objAcc = new Account(Name = 'Acc_'+unitTestName);
        insert objAcc;

        // We are using seeAllData=true anotation in the test class. We don;t know the rela number of this real data.
        // We are considering this value as our 0. 
        Integer noOfPriorSF2SFRecords = [SELECT count() FROM SF2SF_Sharing_Queue__c];

        Attachment objAttachment = new Attachment();
        objAttachment.Description = 'Test' + unitTestName;
        objAttachment.Body = blob.valueof(unitTestName);
        objAttachment.Name = 'Test_' + unitTestName;
        objAttachment.ParentId = objAcc.Id;

        //RUN TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before start test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before start test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StartTest();

            AttachmentTriggerHelper.alreadyExecutedBefore.clear();
            AttachmentTriggerHelper.alreadyExecutedAfter.clear();
            insert objAttachment;
            
        // STOP TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StopTest();
    
        Attachment objAttAfterInsert = [SELECT IsPartnerShared FROM Attachment WHERE Id = :objAttachment.Id LIMIT 1][0];
        System.assertEquals(false, objAttAfterInsert.IsPartnerShared, 
        'The attachment is related to account, but the isParenShared flag is checked.');

        //noOfPriorSF2SFRecords is our test 0 :)
        System.assertEquals(noOfPriorSF2SFRecords, [SELECT count() FROM SF2SF_Sharing_Queue__c], 
        'No new record of SF2SF_Sharing_Queue__c should be created.');
        
       //GOVERNOR_LIMITS
	    system.debug(LoggingLevel.ERROR, 'SOQL query usage at the end of ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage at the end of ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
    }//end  testPosInsert1AttWithoutInterComm()

    /**
	 * This test method testPosInsert1AttWithInterComm contains unit tests for cover AttachmentTriggerHelper class.
	 * Scenario: Create attachment on Intergroup Communication object. The IsPartnerShared flag is updated.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
     * 1. Test: Create 1 case.
     *          Create 1 Intergroup_Communication__c.
     *          Create 1 attachment. ParentId = Intergroup_Communication__c mention above.
     *          Insert attachment.
 	 * Expectations: The IsPartnerShared = true.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
	 */
    @isTest
    static void testPosInsert1AttWithInterComm(){
		String unitTestName = 'testPosInsert1AttWithInterComm';

        //Create test data
        Contact objContact = new Contact(
            LastName = 'Test'
        );
        insert objContact;

        Case[] lstCases = [SELECT Id FROM Case WHERE IsShared__c = true LIMIT 1 FOR UPDATE];      
        System.assertEquals(1, lstCases.size(), 'At least one case should existi in the salesforce. Thank you.');

        Intergroup_Communication__c objIntergroupComm = new Intergroup_Communication__c(
            Case__c = lstCases[0].Id
        );
        insert objIntergroupComm;

        // We are using seeAllData=true anotation in the test class. We don;t know the rela number of this real data.
        // We are considering this value as our 0. 
        Integer noOfPriorSF2SFRecords = [SELECT count() FROM SF2SF_Sharing_Queue__c];

        Attachment objAttachment = new Attachment();
        objAttachment.Description = 'Test' + unitTestName;
        objAttachment.Body = blob.valueof(unitTestName);
        objAttachment.Name = 'Test_' + unitTestName +'.jpg';
        objAttachment.ParentId = objIntergroupComm.Id;
        //objAttachment.IsPartnerShared  = true;

        //RUN TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before start test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before start test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StartTest();

            AttachmentTriggerHelper.alreadyExecutedBefore.clear();
            AttachmentTriggerHelper.alreadyExecutedAfter.clear();
            insert objAttachment;
                    
        // STOP TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StopTest();
    
        // We cannot assert the IsPartnerShared = true flag in the test class, because the parent record of Intergroup_Communication__c
        // cannot be sync with second enviroment. (This comunication is not possible simulate in the test class.)
        // Attachment objAttAfterInsert = [SELECT IsPartnerShared FROM Attachment WHERE Id = :objAttachment.Id LIMIT 1][0];
        // System.assertEquals(true, objAttAfterInsert.IsPartnerShared, 
        // 'The attachment is related to Intergroup Communication, but the isParenShared flag is not checked.');

        
        SF2SF_Sharing_Queue__c[] lstSF2SF2s = [SELECT LocalRecordId__c, RelationId__c FROM SF2SF_Sharing_Queue__c];
        //the result of 'lstSF2SF2s.size() - noOfPriorSF2SFRecord' is our increment to SF2SF_Sharing_Queue__c object
        System.assertEquals(1, lstSF2SF2s.size() - noOfPriorSF2SFRecords, '1 record of SF2SF_Sharing_Queue__c should be created.');

        //GOVERNOR_LIMITS
	    system.debug(LoggingLevel.ERROR, 'SOQL query usage at the end of ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage at the end of ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
    }//end  testPosInsert1AttWithInterComm()

    /**
	 * This test method testPosInsertBULKAttWithInterComm contains unit tests for cover AttachmentTriggerHelper class.
	 * Scenario: Create attachment on Intergroup Communication object. The IsPartnerShared flag is updated.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
     * 1. Test: Create 1 case.
     *          Create 1 Intergroup_Communication__c.
     *          Create 201 attachment. ParentId = Intergroup_Communication__c mention above.
     *          Insert attachment.
 	 * Expectations: All IsPartnerShared == true.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
	 */
    @isTest
    static void testPosInsertBULKAttWithInterComm(){
		String unitTestName = 'testPosInsertBULKAttWithInterComm';

        //Create test data
        Integer BULK_SIZE = 201;
        Contact objContact = new Contact(
            LastName = 'Test'
        );
        insert objContact;

        Case[] lstCases = [SELECT Id FROM Case WHERE IsShared__c = true LIMIT 1 FOR UPDATE];      
        System.assertEquals(1, lstCases.size(), 'At least one case should existi in the salesforce. Thank you.');

        Intergroup_Communication__c objIntergroupComm = new Intergroup_Communication__c(
            Case__c = lstCases[0].Id
        );
        insert objIntergroupComm;

        // We are using seeAllData=true anotation in the test class. We don;t know the rela number of this real data.
        // We are considering this value as our 0. 
        Integer noOfPriorSF2SFRecords = [SELECT count() FROM SF2SF_Sharing_Queue__c];

        Attachment[] lstAttachments = new Attachment[]{};

        for(Integer i = 0; i < BULK_SIZE; i++){
            Attachment tmpAtt = new Attachment();
            tmpAtt.Description = String.valueOf(i);
            tmpAtt.Body = blob.valueof(unitTestName);
            tmpAtt.Name = 'Test_' + unitTestName + String.valueOf(i);
            tmpAtt.ParentId = objIntergroupComm.Id;
            lstAttachments.add(tmpAtt);
        }
        
        //RUN TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before start test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before start test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StartTest();

            AttachmentTriggerHelper.alreadyExecutedBefore.clear();
            AttachmentTriggerHelper.alreadyExecutedAfter.clear();
            insert lstAttachments;
            
        // STOP TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StopTest();
    
        // We cannot assert the IsPartnerShared = true flag in the test class, because the parent record of Intergroup_Communication__c
        // cannot be sync with second enviroment. (This comunication is not possible simulate in the test class.)
        // System.assertEquals(BULK_SIZE, [SELECT count() FROM Attachment WHERE IsPartnerShared = true], 
        // 'Incorrect # of Attachment were updated.');

        SF2SF_Sharing_Queue__c[] lstSF2SF2s = [SELECT RelationId__c FROM SF2SF_Sharing_Queue__c Order By RelationId__c];
        //the result of 'lstSF2SF2s.size() - noOfPriorSF2SFRecord' is our increment to SF2SF_Sharing_Queue__c object
        System.assertEquals(BULK_SIZE, lstSF2SF2s.size() - noOfPriorSF2SFRecords, '' + BULK_SIZE +' record of SF2SF_Sharing_Queue__c should be created.');

       //GOVERNOR_LIMITS
	    system.debug(LoggingLevel.ERROR, 'SOQL query usage at the end of ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage at the end of ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
    }//end testPosInsertBULKAttWithInterComm()

    /**
	 * This test method coverAttachmentTrigger contains unit tests for cover AttachmentTrigger trigger.
	 * Scenario: Create 201 attachments on Intergroup Communication object. The IsPartnerShared flag is updated.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
     * 1. Test: Create 1 case.
     *          Create 1 Intergroup_Communication__c.
     *          Create 201 attachment. ParentId = Intergroup_Communication__c mention above.
     *          Insert attachment.
 	 * Expectations: All IsPartnerShared == true.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
	 */
    @isTest
    static void coverAttachmentTrigger(){
        String unitTestName = 'coverAttachmentTrigger';

        //Create test data
        Contact objContact = new Contact(
            LastName = 'Test'
        );
        insert objContact;

        Case[] lstCases = [SELECT Id FROM Case WHERE IsShared__c = true LIMIT 1 FOR UPDATE];      
        System.assertEquals(1, lstCases.size(), 'At least one case should existi in the salesforce. Thank you.');

        Intergroup_Communication__c objIntergroupComm = new Intergroup_Communication__c(
            Case__c = lstCases[0].Id
        );
        insert objIntergroupComm;

        Attachment objAttachment = new Attachment();
        objAttachment.Description = 'Test' + unitTestName;
        objAttachment.Body = blob.valueof(unitTestName);
        objAttachment.Name = 'Test_' + unitTestName;
        objAttachment.ParentId = objIntergroupComm.Id;
       // objAttachment.IsPartnerShared  = false;

        //RUN TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before start test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before start test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StartTest();

            AttachmentTriggerHelper.alreadyExecutedBefore.clear();
            AttachmentTriggerHelper.alreadyExecutedAfter.clear();
            insert objAttachment;

            AttachmentTriggerHelper.alreadyExecutedBefore.clear();
            AttachmentTriggerHelper.alreadyExecutedAfter.clear();
            update objAttachment;

            AttachmentTriggerHelper.alreadyExecutedBefore.clear();
            AttachmentTriggerHelper.alreadyExecutedAfter.clear();
            delete objAttachment;
            
        // STOP TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StopTest();
    }//end coverAttachmentTrigger
}