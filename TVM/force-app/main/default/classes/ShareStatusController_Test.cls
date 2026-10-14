/** - - - - - - - - - - - - - - - - - - - - - -
 * AttachmentTriggerHelper_Test
 * - - - - - - - - - - - - - - - - - - - - - - 
 * Author: Michaela Tarhanicova
 * - - - - - - - - - - - - - - - - - - - - - -
 * Purpose: Purpose of this class is test behaviour 
 * and cover ShareStatusController.cls
 * - - - - - - - - - - - - - - - - - - - - - -
 * Revision History:
 * Date          Version      Author                 Changes
 * 2020-12-22     1.0         Michaela Tarhanicova   initial dev
 * 2021-01-08     1.1         Michaela Tarhanicova   add FOR UPDATE to select. (It should lock an record for this test class)
 */
@isTest(seeAllData=true)
public class ShareStatusController_Test {
    /**
     * Because the Case and Intergroup_Communication__c are shared by Salesforce 2 Salesforce,
     * we need in test class used anotation seeAllData=true. We need case records to be 
     * already accepted in second salesforce enviroment. 
     * For this reason we cannot created test case in the test class but we need to get case from real world. :)
     * Good article:
     * http://cropredysfdc.com/2014/11/17/s2s-salesforce-to-salesforce-adventures/
     */

    /**
	 * This test method testPosStatusActive contains unit tests for cover ShareStatusController class.
	 * Scenario: Get Case fro real world and find it connection status.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
     * 1. Test: Get 1 case IsShared__c = true
     *          Call ShareStatusController.getData() method.
 	 * Expectations: The connection status is Active
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
	 */
    @isTest
    static void testPosStatusActive(){
		String unitTestName = 'testPosStatusActive';

        //Create test data
        Case[] lstCases = [SELECT Id FROM Case WHERE IsShared__c = true LIMIT 1 FOR UPDATE];      
        System.assertEquals(1, lstCases.size(), 'At least one case should existi in the salesforce. Thank you.');

        //RUN TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before start test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before start test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StartTest();

            String jsonIn = '{ "recordId" : "'+lstCases[0].Id+'"}';
            String results = ShareStatusController.getData(jsonIn);
            
        // STOP TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StopTest();

        Map<String,String> mapResults = (Map<String,String> )JSON.deserialize(results, Map<String,String> .class);
    
        System.AssertEquals(true,mapResults.get('status').contains('Active'), 
        'We got incorrect status. We expected Active but get ' + mapResults.get('status'));

       //GOVERNOR_LIMITS
	    system.debug(LoggingLevel.ERROR, 'SOQL query usage at the end of ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage at the end of ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
    }//end testPosStatusActive

    /**
	 * This test method testPosStatusNotShared contains unit tests for cover ShareStatusController class.
	 * Scenario: Craete Account and get it connection status.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
     * 1. Test: Create 1 Account.
     *          Call ShareStatusController.getData() method.
 	 * Expectations: The connection status is Not Shared
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
	 */
    @isTest
    static void testPosStatusNotShared(){
		String unitTestName = 'testPosStatusNotShared';

        //Create test data
        Account objAcc = new Account(Name = 'Acc_'+unitTestName);
        insert objAcc;

        //RUN TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before start test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before start test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StartTest();

            String jsonIn = '{ "recordId" : "'+objAcc.Id+'"}';
            String results = ShareStatusController.getData(jsonIn);
            
        // STOP TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        system.Test.StopTest();

        Map<String,String> mapResults = (Map<String,String> )JSON.deserialize(results, Map<String,String> .class);
    
        System.AssertEquals(true,mapResults.get('status').contains('Not Shared'), 
        'We got incorrect status. We expected Not Shared but get ' + mapResults.get('status'));

       //GOVERNOR_LIMITS
	    system.debug(LoggingLevel.ERROR, 'SOQL query usage at the end of ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage at the end of ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
    }//end testPosStatusNotShared
}