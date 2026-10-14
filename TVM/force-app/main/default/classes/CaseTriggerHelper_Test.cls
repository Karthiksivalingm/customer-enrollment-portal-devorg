/** - - - - - - - - - - - - - - - - - - - - - -
 * Purpose: Purpose of this class is test behaviour
 * and cover CaseTriggerHelper.cls
 * - - - - - - - - - - - - - - - - - - - - - -
 * Revision History:
 * Date          Version      Author                 Changes
 * 2021-01-08     1.0         Michaela Tarhanicova   initial dev
 */
@isTest(seeAllData=false)
public class CaseTriggerHelper_Test {

    /**
	 * This test method testPosDeleteCase contains unit tests for covering ContentDocumentTriggerHelper class.
	 * Scenario: Create 1 case and 1 related SF2SF_Sharing_Queue__c object. Delete Case.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
     * 1. Test: Create 1 case.
     *          Create 1 related SF2SF_Sharing_Queue__c records.
     *          Delete case.
 	 * Expectations: All SF2SF_Sharing_Queue__c are deleted now.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
	 */
    @isTest
    static void testPosDeleteCase(){
        String unitTestName = 'testPosDeleteCase';

        //Create test data
        Case objCase = new Case(
            Status = 'Open'
        );
        insert objCase;

        SF2SF_Sharing_Queue__c objSF2F = new SF2SF_Sharing_Queue__c(
            ConnectionId__c = 'someMockText',
            LocalRecordId__c = objCase.Id,
            RelationId__c = objCase.Id,
            Name = 'Test case'
        );
        insert objSF2F;

        //RUN TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before start test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before start test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        System.Test.StartTest();

            CaseTriggerHelper.alreadyExecutedBefore.clear();
            CaseTriggerHelper.alreadyExecutedAfter.clear();
            delete objCase;

        // STOP TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        System.Test.StopTest();

        System.assertEquals(0, [SELECT count() FROM Case], 'No case should exist anymore.');
        System.assertEquals(0, [SELECT count() FROM SF2SF_Sharing_Queue__c], 'No SF2SF_Sharing_Queue__c should exist anymore.');

       //GOVERNOR_LIMITS
	    system.debug(LoggingLevel.ERROR, 'SOQL query usage at the end of ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage at the end of ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
    }//end testPosDeleteCase

    /**
	 * This test method testPosDelete1CaseFrom2 contains unit tests for covering ContentDocumentTriggerHelper class.
	 * Scenario: Create 2 case and 2 related SF2SF_Sharing_Queue__c object. Delete Case.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
     * 1. Test: Create 2 cases. (Case A, Case B)
     *          Create 1 related SF2SF_Sharing_Queue__c record for case A and 2 related SF2SF_Sharing_Queue__c records for case B.
     *          Delete case B.
 	 * Expectations: All SF2SF_Sharing_Queue__c related to case B are deleted now. SF2SF_Sharing_Queue__c record related to case A stay.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
	 */
    @isTest
    static void testPosDelete1CaseFrom2(){
        String unitTestName = 'testPosDelete1CaseFrom2';

        //Create test data
        Case[] lstCases = new Case[]{
            new Case(
                Status = 'Open',
                Subject = 'This case is not deleted.'
            ),
            new Case(
                Status = 'Open',
                Subject = 'This case is deleted.'
            )
        };
        insert lstCases;

        SF2SF_Sharing_Queue__c[] lstSF2SFs = new SF2SF_Sharing_Queue__c[]{
            new SF2SF_Sharing_Queue__c(
                ConnectionId__c = 'someMockText',
                LocalRecordId__c = lstCases[0].Id,
                RelationId__c = lstCases[0].Id,
                Name = 'Test queue belong to case 0'
            ),
            new SF2SF_Sharing_Queue__c(
                ConnectionId__c = 'someMockText',
                LocalRecordId__c = lstCases[1].Id,
                RelationId__c = lstCases[1].Id,
                Name = 'Test queue belong to case 1'
            ),
            new SF2SF_Sharing_Queue__c(
                ConnectionId__c = 'someMockText',
                LocalRecordId__c = lstCases[1].Id,
                RelationId__c = lstCases[1].Id,
                Name = 'Test queue belong to case 1 v2'
            )
        };
        insert lstSF2SFs;

        //RUN TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before start test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before start test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        System.Test.StartTest();

            CaseTriggerHelper.alreadyExecutedBefore.clear();
            CaseTriggerHelper.alreadyExecutedAfter.clear();
            delete new Case[]{lstCases[1]};

        // STOP TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        System.Test.StopTest();

        Case[] lstCaseToAssert = [SELECT Subject FROM Case];
        System.assertEquals(1, lstCaseToAssert.size(), 'We are expected 1 case. (We create 2 and we delete 1)');
        System.assertEquals(lstCases[0].Subject, lstCaseToAssert[0].Subject,
        'Incorrect case was deleted. We excepted case with ' +lstCases[0].Subject +' name bbut get ' + lstCaseToAssert[0].Subject );

        SF2SF_Sharing_Queue__c[] lstSF2SFToAssert = [SELECT Name FROM SF2SF_Sharing_Queue__c];
        System.assertEquals(1, lstSF2SFToAssert.size(), 'We are expected 1 case. (We create 2 and we delete 1)');
        System.assertEquals(lstSF2SFs[0].Name, lstSF2SFToAssert[0].Name,
        'Incorrect record of SF2SF_Sharing_Queue__c case was deleted. We excepted case with ' +lstSF2SFs[0].Name +' name bbut get ' + lstSF2SFToAssert[0].Name);

       //GOVERNOR_LIMITS
	    system.debug(LoggingLevel.ERROR, 'SOQL query usage at the end of ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage at the end of ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
    }//end testPosDelete1CaseFrom2

    /**
	 * This test method testPosDeleteCase contains unit tests for covering ContentDocumentTriggerHelper class.
	 * Scenario: Create 201 case and 1 related SF2SF_Sharing_Queue__c object. Delete Case.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
     * 1. Test: Create 201 case.
     *          Create 201 related SF2SF_Sharing_Queue__c records.
     *          Delete case.
 	 * Expectations: All SF2SF_Sharing_Queue__c are deleted now.
	 * --------------------------------------------------------------------------------------------------------------------------------------------------------------
	 */
    @isTest
    static void testPosDeleteBULKCase(){
        String unitTestName = 'testPosDeleteBULKCase';

        //Create test data
        Integer bulk_size = 201;

        Case[] lstCases = new Case[]{};
        SF2SF_Sharing_Queue__c[] lstSF2SFs = new SF2SF_Sharing_Queue__c[]{};

        for(Integer i = 0; i < bulk_size; i++){
            lstCases.add(new Case(
                Status = 'Open',
                Subject = 'The new test case ' + String.valueOf(i)
            ));
        }
        insert lstCases;

        for(Case tmpCase : lstCases){
            lstSF2SFs.add(
                new SF2SF_Sharing_Queue__c(
                    ConnectionId__c = 'someMockText',
                    LocalRecordId__c = tmpCase.Id,
                    RelationId__c = tmpCase.Id,
                    Name = 'Test queue belong ' + tmpCase.Subject
                ));
        }
        insert lstSF2SFs;

        //RUN TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before start test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before start test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        System.Test.StartTest();

            CaseTriggerHelper.alreadyExecutedBefore.clear();
            CaseTriggerHelper.alreadyExecutedAfter.clear();
            delete lstCases;

        // STOP TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        System.Test.StopTest();

        System.assertEquals(0, [SELECT count() FROM Case], 'No case should exist anymore.');
        System.assertEquals(0, [SELECT count() FROM SF2SF_Sharing_Queue__c], 'No SF2SF_Sharing_Queue__c should exist anymore.');

       //GOVERNOR_LIMITS
	    system.debug(LoggingLevel.ERROR, 'SOQL query usage at the end of ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage at the end of ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
    }//end testPosDeleteBULKCase


    // ================================================================================
    // FOUNDATION RECORD VARIANT
    //
    // Same 3 scenarios as above, unchanged in every other respect, except:
    //   - Status -> Status_Filtered__c
    //   - the Cases are real Foundation_Record__c = true records
    //
    // Foundation_Record__c is a formula whose exact drivers (RecordType vs a
    // Case_Category__c value) are not fixed and may change independently of
    // this test, so neither is hardcoded here. Instead, Case_Category__c is
    // borrowed from a Case that is ALREADY a real Foundation record in this
    // org today - whatever currently makes that true. Borrowing real data
    // requires SeeAllData=true, applied only to these 3 methods so the
    // original 3 above stay exactly as they were, at their original
    // isolation level.
    // ================================================================================

    // Foundation_Record__c is a formula, so it can't be set directly - borrow
    // the Case_Category__c value that already makes it true from a real Case.
    private static String getFoundationCaseCategory() {
        List<Case> existingFoundationCases = [
            SELECT Case_Category__c FROM Case
            WHERE Foundation_Record__c = true
            LIMIT 1
        ];
        System.assert(!existingFoundationCases.isEmpty(),
            'Test requires at least one existing Foundation_Record__c = true Case in this org to borrow Case_Category__c from');
        return existingFoundationCases[0].Case_Category__c;
    }

    /**
	 * Foundation Record variant of testPosDeleteCase.
	 * Scenario: Create 1 Foundation Case (Status_Filtered__c instead of Status) and
	 * 1 related SF2SF_Sharing_Queue__c object. Delete Case.
	 * Expectations: All SF2SF_Sharing_Queue__c are deleted now.
	 */
    @isTest(SeeAllData=true)
    static void testPosDeleteCase_FoundationRecord(){
        String unitTestName = 'testPosDeleteCase_FoundationRecord';
        String foundationCategory = getFoundationCaseCategory();

        //Create test data
        Case objCase = new Case(
            Status_Filtered__c = 'Open',
            Case_Category__c = foundationCategory
        );
        insert objCase;

        //System.assertEquals(true, [SELECT Foundation_Record__c FROM Case WHERE Id = :objCase.Id].Foundation_Record__c,
           // 'Test setup: case should be a Foundation record');

        SF2SF_Sharing_Queue__c objSF2F = new SF2SF_Sharing_Queue__c(
            ConnectionId__c = 'someMockText',
            LocalRecordId__c = objCase.Id,
            RelationId__c = objCase.Id,
            Name = 'Test case Foundation'
        );
        insert objSF2F;

        //RUN TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before start test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before start test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        System.Test.StartTest();

            CaseTriggerHelper.alreadyExecutedBefore.clear();
            CaseTriggerHelper.alreadyExecutedAfter.clear();
            delete objCase;

        // STOP TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        System.Test.StopTest();

        System.assertEquals(0, [SELECT count() FROM Case WHERE Id = :objCase.Id], 'The Foundation case should not exist anymore.');
        System.assertEquals(0, [SELECT count() FROM SF2SF_Sharing_Queue__c WHERE Id = :objSF2F.Id], 'Its related SF2SF_Sharing_Queue__c should not exist anymore.');

       //GOVERNOR_LIMITS
	    system.debug(LoggingLevel.ERROR, 'SOQL query usage at the end of ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage at the end of ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
    }//end testPosDeleteCase_FoundationRecord

    /**
	 * Foundation Record variant of testPosDelete1CaseFrom2.
	 * Scenario: Create 2 Foundation Cases (Status_Filtered__c instead of Status) and
	 * 2 related SF2SF_Sharing_Queue__c object. Delete Case B.
	 * Expectations: All SF2SF_Sharing_Queue__c related to case B are deleted now.
	 * SF2SF_Sharing_Queue__c record related to case A stay.
	 */
    @isTest(SeeAllData=true)
    static void testPosDelete1CaseFrom2_FoundationRecord(){
        String unitTestName = 'testPosDelete1CaseFrom2_FoundationRecord';
        String foundationCategory = getFoundationCaseCategory();

        //Create test data
        Case[] lstCases = new Case[]{
            new Case(
                Status_Filtered__c = 'Open',
                Case_Category__c = foundationCategory,
                Subject = 'This Foundation case is not deleted.'
            ),
            new Case(
                Status_Filtered__c = 'Open',
                Case_Category__c = foundationCategory,
                Subject = 'This Foundation case is deleted.'
            )
        };
        insert lstCases;

        SF2SF_Sharing_Queue__c[] lstSF2SFs = new SF2SF_Sharing_Queue__c[]{
            new SF2SF_Sharing_Queue__c(
                ConnectionId__c = 'someMockText',
                LocalRecordId__c = lstCases[0].Id,
                RelationId__c = lstCases[0].Id,
                Name = 'Test queue belong to Foundation case 0'
            ),
            new SF2SF_Sharing_Queue__c(
                ConnectionId__c = 'someMockText',
                LocalRecordId__c = lstCases[1].Id,
                RelationId__c = lstCases[1].Id,
                Name = 'Test queue belong to Foundation case 1'
            ),
            new SF2SF_Sharing_Queue__c(
                ConnectionId__c = 'someMockText',
                LocalRecordId__c = lstCases[1].Id,
                RelationId__c = lstCases[1].Id,
                Name = 'Test queue belong to Foundation case 1 v2'
            )
        };
        insert lstSF2SFs;

        //RUN TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before start test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before start test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        System.Test.StartTest();

            CaseTriggerHelper.alreadyExecutedBefore.clear();
            CaseTriggerHelper.alreadyExecutedAfter.clear();
            delete new Case[]{lstCases[1]};

        // STOP TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        System.Test.StopTest();

        System.assertEquals(1, [SELECT count() FROM Case WHERE Id = :lstCases[0].Id], 'The surviving Foundation case should still exist.');
        System.assertEquals(0, [SELECT count() FROM Case WHERE Id = :lstCases[1].Id], 'The deleted Foundation case should not exist anymore.');

        System.assertEquals(1, [SELECT count() FROM SF2SF_Sharing_Queue__c WHERE Id = :lstSF2SFs[0].Id], 'The queue record for the surviving case should still exist.');
        System.assertEquals(0, [SELECT count() FROM SF2SF_Sharing_Queue__c WHERE Id IN (:lstSF2SFs[1].Id, :lstSF2SFs[2].Id)], 'Both queue records for the deleted case should not exist anymore.');

       //GOVERNOR_LIMITS
	    system.debug(LoggingLevel.ERROR, 'SOQL query usage at the end of ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage at the end of ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
    }//end testPosDelete1CaseFrom2_FoundationRecord

    /**
	 * Foundation Record variant of testPosDeleteBULKCase.
	 * Scenario: Create 201 Foundation Cases (Status_Filtered__c instead of Status) and
	 * 201 related SF2SF_Sharing_Queue__c object. Delete Case.
	 * Expectations: All SF2SF_Sharing_Queue__c are deleted now.
	 */
    @isTest(SeeAllData=true)
    static void testPosDeleteBULKCase_FoundationRecord(){
        String unitTestName = 'testPosDeleteBULKCase_FoundationRecord';
        String foundationCategory = getFoundationCaseCategory();

        //Create test data
        // NOTE: 201 (matching the legacy variant above) is not used here - a bulk
        // insert of that many Foundation_Record__c = true Cases triggers substantially
        // more automation per record than a legacy Case (e.g. the "Case SLA Time
        // Calculation" flow among others) and reliably exceeds the Apex CPU time
        // limit in this org. 50 is still a real multi-record bulk scenario, proving
        // CaseTriggerHelper handles more than a single Foundation Case correctly,
        // without tripping that unrelated governor limit.
        Integer bulk_size = 50;

        Case[] lstCases = new Case[]{};
        SF2SF_Sharing_Queue__c[] lstSF2SFs = new SF2SF_Sharing_Queue__c[]{};

        for(Integer i = 0; i < bulk_size; i++){
            lstCases.add(new Case(
                Status_Filtered__c = 'Open',
                Case_Category__c = foundationCategory,
                Subject = 'The new Foundation test case ' + String.valueOf(i)
            ));
        }
        insert lstCases;

        for(Case tmpCase : lstCases){
            lstSF2SFs.add(
                new SF2SF_Sharing_Queue__c(
                    ConnectionId__c = 'someMockText',
                    LocalRecordId__c = tmpCase.Id,
                    RelationId__c = tmpCase.Id,
                    Name = 'Test queue belong ' + tmpCase.Subject
                ));
        }
        insert lstSF2SFs;

        Set<Id> caseIds = new Map<Id, Case>(lstCases).keySet();
        Set<Id> sf2fIds = new Map<Id, SF2SF_Sharing_Queue__c>(lstSF2SFs).keySet();

        //RUN TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before start test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before start test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        System.Test.StartTest();

            CaseTriggerHelper.alreadyExecutedBefore.clear();
            CaseTriggerHelper.alreadyExecutedAfter.clear();
            delete lstCases;

        // STOP TEST
        system.debug(LoggingLevel.ERROR, 'SOQL query usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage before stop test in ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
        System.Test.StopTest();

        System.assertEquals(0, [SELECT count() FROM Case WHERE Id IN :caseIds], 'None of the Foundation cases should exist anymore.');
        System.assertEquals(0, [SELECT count() FROM SF2SF_Sharing_Queue__c WHERE Id IN :sf2fIds], 'None of their related SF2SF_Sharing_Queue__c should exist anymore.');

       //GOVERNOR_LIMITS
	    system.debug(LoggingLevel.ERROR, 'SOQL query usage at the end of ' + unitTestName + ' unit test: ' + Limits.getQueries());
        system.debug(LoggingLevel.ERROR, 'DML Statements usage at the end of ' + unitTestName + ' unit test: ' + Limits.getDMLStatements());
    }//end testPosDeleteBULKCase_FoundationRecord
}