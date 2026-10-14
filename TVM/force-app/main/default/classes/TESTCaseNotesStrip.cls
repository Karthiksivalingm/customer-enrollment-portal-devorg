@isTest
public class TESTCaseNotesStrip {
	//https://salesforce.stackexchange.com/questions/329335/how-do-i-write-a-test-class-invoked-from-a-flow
    // Recommended practice is to use a @testSetup annotated method to create
    // the common data required for each test.
    // It can help test execution speed.
    // The 'testMethod' keyword has been deprecated for a while
    // The preferred approach is to use the @isTest annotation
    @isTest
    private static void validateCaseNotesStrip() {
        Case testcase = new Case();
        testcase.OEM__c='KIA';
        testcase.Case_Category__c='Production Support';
		testcase.External_Notes_Rich__c = '<span>test</span>';
		testcase.Internal_Notes_Rich__c = '<span>test</span>';
		upsert testcase;
        List<Case> caselist = new List<Case>();
        caselist.add(testcase);
        
        Test.startTest();
        CaseNotesStrip.stripText(caselist);
        Test.stopTest();
    }
}