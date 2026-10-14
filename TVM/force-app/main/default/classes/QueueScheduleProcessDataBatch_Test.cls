/** - - - - - - - - - - - - - - - - - - - - - -
 * Purpose: Purpose of this class is test behaviour
 * and cover QueueScheduleProcessDataBatch.cls
 * - - - - - - - - - - - - - - - - - - - - - -
 * Revision History:
 * Date          Version      Author                 Changes
 * 2021-01-08     1.0         Michaela Tarhanicova   initial dev
 * 2021-01-08     1.1         Michaela Tarhanicova   add FOR UPDATE to select. (It should lock an record for this test class)
 */
@isTest(seeAllData=true)
public class QueueScheduleProcessDataBatch_Test {
     /**
     * Because the Case and Intergroup_Communication__c are shared by Salesforce 2 Salesforce,
     * we need in test class used anotation seeAllData=true. We need case records to be 
     * already accepted in second salesforce enviroment. 
     * For this reason we cannot created test case in the test class but we need to get case from real world. :)
     * Good article:
     * http://cropredysfdc.com/2014/11/17/s2s-salesforce-to-salesforce-adventures/
     *  
     * Tester note: 
     * Nevertheless, we have a new logic that can catch record on Integration communication and Attachment 
     * which parents are not synchronizes via Salesforce 2 Salesforce, we cannot delete change seeAllData to false.
     * If we do that we got a CUSTOM_VALIDATIN error. 
     * Text of error: Case has not been shared externally so Intergroup Communications cannot be created on this Case. 
     * First share the Case externally and then try again.
     * 
     */

    /**
	 * This test method testPosWithouData contains unit tests for cover AttachmentTriggerHelper class.
	 * Scenario: Call QueueScheduleProcessDataBatch batch without aditional test data.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
     * 1. Test: Call QueueScheduleProcessDataBatch.
 	 * Expectations: Nothing bad happend. :)
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
	 */
    @isTest
    static void testPosWithouData(){
        String unitTestName = 'testPosWithoutData';

        // This pice of code is here to ensure that the object SF2SF_Sharing_Queue__c is epmty.
        SF2SF_Sharing_Queue__c[] lstQueue = [SELECT Id FROM SF2SF_Sharing_Queue__c FOR UPDATE];
        if(lstQueue != null && !lstQueue.isEmpty()){
            delete lstQueue;
        }

        System.Test.StartTest();
        QueueScheduleProcessDataBatch batch = new QueueScheduleProcessDataBatch(1440);
        Database.executeBatch(batch);

        // STOP TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        System.Test.StopTest();
    
       //GOVERNOR_LIMITS
	    system.debug(LoggingLevel.ERROR, 'SOQL query usage at the end of ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage at the end of ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
    }//end testPosWithouData

    /**
	 * This test method testPosWithRealCase contains unit tests for cover AttachmentTriggerHelper class.
	 * Scenario: Call QueueScheduleProcessDataBatch batch with new Intergroup_Communication__c and Attachment.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
     * 1. Test: Get real case.
     *          Get real PartnerNetworkConnection. (Available in the test class event with seeAllData=false).
     *          Create 1 record of Intergroup_Communication__c. (This return us better results as we got the real intergroup).
     *          Create 2 records of Attachment.
     *          Create 3 records of SF2SF_Sharing_Queue__c. (Case, Intergroup_Communication__c, and the first attachment.)
     *          Call QueueScheduleProcessDataBatch.
 	 * Expectations:
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
	 */
    @isTest
    static void testPosWithRealCase(){
        String unitTestName = 'testPosWithRealCase';

        //Create test data
        // We need to get the REAL case because of Salesforce 2 Salesforce.
        Case[] lstCases = [SELECT Id FROM Case WHERE IsShared__c = true LIMIT 1 FOR UPDATE];      
        System.assertEquals(1, lstCases.size(), 'At least one case should existi in the salesforce. Thank you.');
       
        // We are using seeAllData=true anotation in the test class. We don;t know the rela number of this real data.
        // We are considering this value as our 0. 
        Integer noOfPriorSF2SFRecords = [SELECT count() FROM SF2SF_Sharing_Queue__c];

        PartnerNetworkConnection parentNetworkCon = [SELECT Id, ConnectionStatus, ConnectionName, ContactId 
                                                    FROM PartnerNetworkConnection 
                                                    WHERE ConnectionStatus = 'Accepted' Limit 1];
     
        Intergroup_Communication__c objIC = new Intergroup_Communication__c( 
            Case__c = lstCases[0].Id
        );     
        insert objIC;                        

        Attachment objAttachmentInQueue = new Attachment();
            objAttachmentInQueue.Description = 'This attachment is alrwedy in queue' + unitTestName;
            objAttachmentInQueue.Body = blob.valueof(unitTestName);
            objAttachmentInQueue.Name = 'Test_' + unitTestName;
            objAttachmentInQueue.ParentId = objIC.Id;

            insert objAttachmentInQueue;

        Attachment objAttachmentNotInQueue = new Attachment();
            objAttachmentNotInQueue.Description = 'This attachment is NOT in queue.' + unitTestName;
            objAttachmentNotInQueue.Body = blob.valueof(unitTestName);
            objAttachmentNotInQueue.Name = 'Test_' + unitTestName;
            objAttachmentNotInQueue.ParentId = objIC.Id;
        
            // This insert call doesn't fire AttchmentTrigger. What is a behaviour that we need.
            insert objAttachmentNotInQueue;

        // We are expecting 2 types of Name
        // Create_History_Connection OR Attachment_set_IsPartnerShared       
        SF2SF_Sharing_Queue__c[] lstSF2SF2s = new SF2SF_Sharing_Queue__c[]{
            // This record of SF2SF_Sharing_Queue__c is simulated the not-shared case in the queue
            new SF2SF_Sharing_Queue__c(
                ConnectionId__c = parentNetworkCon.Id,
                LocalRecordId__c = lstCases[0].Id,
                RelationId__c = lstCases[0].Id,
                Name = 'Create_History_Connection'
            ),
            // This record of SF2SF_Sharing_Queue__c is simulated the not-shared Intergroup_Communication__c record in the queue
            new SF2SF_Sharing_Queue__c(
                ConnectionId__c = parentNetworkCon.Id,
                LocalRecordId__c = objIC.Id,
                RelationId__c = lstCases[0].Id,
                Name = 'Create_History_Connection'
            ),
            // This record of SF2SF_Sharing_Queue__c is simulated the not-shared Attachment record in the queue
            new SF2SF_Sharing_Queue__c(
                ConnectionId__c = parentNetworkCon.Id,
                LocalRecordId__c = objAttachmentInQueue.Id,
                RelationId__c = objIC.Id,
                Name = 'Attachment_set_IsPartnerShared'
            )
        };

       insert lstSF2SF2s;

        //RUN TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before start test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before start test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        System.Test.StartTest();

        QueueScheduleProcessDataBatch batch = new QueueScheduleProcessDataBatch(1440);
        Database.executeBatch(batch);

        // STOP TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        System.Test.StopTest();
    
       //GOVERNOR_LIMITS
	    system.debug(LoggingLevel.ERROR, 'SOQL query usage at the end of ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage at the end of ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
    }//end testPosWithRealCase
}