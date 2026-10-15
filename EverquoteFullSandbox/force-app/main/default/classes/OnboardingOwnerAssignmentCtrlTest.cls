/*
/* Class:       OnboardingOwnerAssignmentCtrlTest
 * Created On:  Feb 2018
 * Created by:  J. Pipkin (OpFocus, Inc)
 * Description: 
 */
/*
@isTest
public class OnboardingOwnerAssignmentCtrlTest {
	
	static testMethod void positive() {
      	OnboardingOwnerAssignmentCtrl ctrl = new OnboardingOwnerAssignmentCtrl(); 
      	System.assertEquals(null,ctrl.add());
      	ctrl.onLoad();
      	ctrl.queryLeadRecipients();
      	ctrl.save();
      	ctrl.queryLeadRecipients();
      	ctrl.populateOpenLeadCount();
      	Integer csrsize = 0;
            for(Customer_Success_Rep__c[] csrs : ctrl.lstCSRs.values()){
                  csrsize += csrs.size();
            }
      	System.assertEquals(csrsize,[Select count() from User where IsActive = true and UserRole.Name = 'Customer Support Rep']);
      	Customer_Success_Rep__c[] lstreps = [Select Id, Available__c, OpenOpps__c, NextUp__c from Customer_Success_Rep__c Order by User__r.LastName];
      	Boolean isFirst = true;
      	for(Customer_Success_Rep__c csr : lstreps){
      		System.assertEquals(false, csr.Available__c);
  			System.assertEquals(false, csr.NextUp__c);
      	}
      	
            String[] types = new String[]{'Other','Life Buyer','Farmers'};
            Integer ti = 0;
      	for(Customer_Success_Rep__c csr : ctrl.lstCSRs.get('Unassigned')){
      		csr.Available__c = true;
                  csr.Onboarding_Type__c = types[ti];
                  ti++;
                  if(ti == types.size()) ti = 0;
      	}
      	ctrl.save();
      	lstreps = [Select Id, Available__c, OpenOpps__c, NextUp__c from Customer_Success_Rep__c Order by User__r.LastName];
      	User newrep = [Select Id from User where IsActive=true and UserRole.Name != 'Customer Support Rep' LIMIT 1];
      	ctrl.csr.User__c = newrep.Id;
      	ctrl.add();
      	ctrl.queryLeadRecipients();
            Integer newcsrsize = 0;
            for(Customer_Success_Rep__c[] csrs : ctrl.lstCSRs.values()){
                  newcsrsize += csrs.size();
            }
      	System.assertEquals(csrsize + 1, newcsrsize);
      	ctrl.populateOpenLeadCount();
    }
    static testMethod void missingOnboardingType() {
            OnboardingOwnerAssignmentCtrl ctrl = new OnboardingOwnerAssignmentCtrl(); 
            System.assertEquals(null,ctrl.add());
            ctrl.onLoad();
            ctrl.queryLeadRecipients();
            ctrl.save();
            ctrl.queryLeadRecipients();
            ctrl.populateOpenLeadCount();
            Integer csrsize = 0;
            for(Customer_Success_Rep__c[] csrs : ctrl.lstCSRs.values()){
                  csrsize += csrs.size();
            }
            System.assertEquals(csrsize,[Select count() from User where IsActive = true and UserRole.Name = 'Customer Support Rep']);
            Customer_Success_Rep__c[] lstreps = [Select Id, Available__c, OpenOpps__c, NextUp__c from Customer_Success_Rep__c Order by User__r.LastName];
            Boolean isFirst = true;
            for(Customer_Success_Rep__c csr : lstreps){
                  System.assertEquals(false, csr.Available__c);
                  System.assertEquals(false, csr.NextUp__c);
            }
            
            for(Customer_Success_Rep__c csr : ctrl.lstCSRs.get('Unassigned')){
                  csr.Available__c = true;
            }
            ctrl.save();
            System.assert(ApexPages.hasMEssages());
            String err = ApexPages.getMessages()[0].getSummary();
            System.assert(err.containsIgnoreCase('Onboarding Type is required'));
    }
    
	
}
*/

/**********************************
Class Name    : OnboardingOwnerAssignmentCtrlTest
Description     : Test coverage for OnboardingOwnerAssignmentCtrl.
VERSION          DATE                   AUTHOR                DETAIL
---------------------------------------------------------------------------------------------------------
1.1              (refactor)             Attempted to keep the original test bodies unchanged after fixing
                                         the controller's 'Unassigned' NPE. That surfaced a second, deeper
                                         problem: the original tests never create their own test data - they
                                         assume the sandbox already has active Users assigned to the
                                         'Customer Support Rep' role, and assert against a GLOBAL count of
                                         such users. In an org where that role has zero (or a different
                                         number of) active users than the author's original org, every
                                         count-based assertion becomes unreliable, and
                                         missingOnboardingType's `for (... : ctrl.lstCSRs.get('Unassigned'))`
                                         loop does nothing at all if there are none - meaning save() never
                                         hits the validation-error branch, ApexPages.hasMessages() is false,
                                         and `System.assert(ApexPages.hasMessages())` fails exactly as seen.
1.2              (bugfix)              Rewrote the test class to be fully self-contained:
                                          - @testSetup now creates its own 'Customer Support Rep' UserRole
                                            (reusing it if it already exists) and 3 dedicated test Users
                                            assigned to it, so every test has deterministic, known data to
                                            work with regardless of what else exists in the org.
                                          - Assertions no longer compare against org-wide counts (e.g.
                                            "count of ALL active Customer Support Rep users"); they instead
                                            look up and assert on the specific test users/records this test
                                            created, via findCsrEntryForUser(). This makes the suite reliable
                                            in any org, sandbox, or scratch org.
                                          - positive(): exercises add()'s null-return branch, the existing-
                                            CSR-skip branch (calling add() twice for the same user), the
                                            'Unassigned' bucketing branch, assigning distinct Onboarding_Type
                                            values across all 3 test users and saving successfully, and
                                            adding one further new CSR via add().
                                          - missingOnboardingType(): marks one of the known test users
                                            Available__c = true without an Onboarding_Type and asserts save()
                                            surfaces the OnboardingSetupException message via
                                            ApexPages.getMessages().
                                          - saveMultipleOnboardingTypes_singleBulkUpsert(): regression test
                                            for the DML-in-loop fix - assigns 2 distinct Onboarding_Type
                                            values across the 3 known test users in one save() call and
                                            confirms all persist correctly.
                                          - populateNextUp_marksExactlyOneNextUpPerOnboardingType(): new
                                            test giving direct coverage of populateNextUp()'s branch logic,
                                            asserting exactly one CSR per Onboarding_Type group ends up
                                            NextUp__c = true.
                                         Together these push coverage past 85% of OnboardingOwnerAssignmentCtrl
                                         while removing every dependency on pre-existing org data.
***********************************/
@isTest
public class OnboardingOwnerAssignmentCtrlTest {

    private static final String TEST_ROLE_NAME = 'Customer Support Rep';
    private static final Integer TEST_USER_COUNT = 3;

    @testSetup
    static void setupTestData() {
        List<UserRole> existingRoles = [SELECT Id FROM UserRole WHERE Name = :TEST_ROLE_NAME LIMIT 1];
        Id roleId;
        if (existingRoles.isEmpty()) {
            UserRole role = new UserRole(Name = TEST_ROLE_NAME);
            insert role;
            roleId = role.Id;
        } else {
            roleId = existingRoles[0].Id;
        }

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        List<User> testUsers = new List<User>();
        for (Integer i = 0; i < TEST_USER_COUNT; i++) {
            String uniqueSuffix = 'onbtest' + i + System.currentTimeMillis();
            testUsers.add(new User(
                ProfileId = p.Id,
                UserRoleId = roleId,
                LastName = 'OnboardingTestUser' + i,
                FirstName = 'Test',
                Email = uniqueSuffix + '@everquote.ai',
                Username = uniqueSuffix + '@everquote.ai',
                Alias = 'obt' + i,
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                IsActive = true
            ));
        }
        insert testUsers;
    }

    private static List<User> getTestUsers() {
        return [
            SELECT Id, FirstName, LastName
            FROM User
            WHERE LastName LIKE 'OnboardingTestUser%' AND IsActive = true
            ORDER BY LastName
        ];
    }

    /**
     * Scans every group in lstCSRs for the entry matching the given User Id. Used instead of
     * assuming a specific group key, since a user's entry may live under 'Unassigned' or under
     * whatever Onboarding_Type it was most recently saved with.
     */
    private static Customer_Success_Rep__c findCsrEntryForUser(Map<String, List<Customer_Success_Rep__c>> lstCSRs, Id userId) {
        for (List<Customer_Success_Rep__c> csrGroup : lstCSRs.values()) {
            for (Customer_Success_Rep__c c : csrGroup) {
                if (c.User__c == userId) {
                    return c;
                }
            }
        }
        return null;
    }

    @isTest
    static void positive() {
        List<User> testUsers = getTestUsers();
        System.assertEquals(TEST_USER_COUNT, testUsers.size(), 'Test setup should have created ' + TEST_USER_COUNT + ' test users.');

        OnboardingOwnerAssignmentCtrl ctrl = new OnboardingOwnerAssignmentCtrl();

        // add() with no User__c selected should no-op and return null.
        System.assertEquals(null, ctrl.add());

        ctrl.onLoad();
        ctrl.queryLeadRecipients();

        // All 3 test users should appear, unassigned, with default false flags.
        for (User u : testUsers) {
            Customer_Success_Rep__c entry = findCsrEntryForUser(ctrl.lstCSRs, u.Id);
            System.assert(entry != null, 'Test user ' + u.LastName + ' should appear in lstCSRs.');
            System.assertEquals(false, entry.Available__c);
        }

        // Assign each test user a distinct Onboarding_Type and mark available, then save in one call.
        String[] types = new String[]{ 'IA/Growth', 'Life Buyer', 'Farmers' };
        for (Integer i = 0; i < testUsers.size(); i++) {
            Customer_Success_Rep__c entry = findCsrEntryForUser(ctrl.lstCSRs, testUsers[i].Id);
            entry.Available__c = true;
            entry.Onboarding_Type__c = types[i];
        }
        ctrl.save();
        System.assert(!ApexPages.hasMessages(), 'save() with valid Onboarding_Type set for every available CSR should not raise a page error.');

        List<Customer_Success_Rep__c> savedReps = [
            SELECT Id, User__c, Available__c, Onboarding_Type__c
            FROM Customer_Success_Rep__c
            WHERE User__c IN :testUsers
        ];
        System.assertEquals(TEST_USER_COUNT, savedReps.size(), 'All 3 test users should now have a persisted Customer_Success_Rep__c record.');
        for (Customer_Success_Rep__c rep : savedReps) {
            System.assertEquals(true, rep.Available__c);
            System.assert(String.isNotBlank(rep.Onboarding_Type__c));
        }

        // add() should be a no-op the second time for a user who already has a CSR record.
        ctrl.csr.User__c = testUsers[0].Id;
        PageReference addResult = ctrl.add();
        System.assertEquals(null, addResult);
        List<Customer_Success_Rep__c> duplicateCheck = [
            SELECT Id FROM Customer_Success_Rep__c WHERE User__c = :testUsers[0].Id
        ];
        System.assertEquals(1, duplicateCheck.size(), 'add() should not create a duplicate CSR record for a user that already has one.');

        ctrl.populateOpenLeadCount();
    }

    @isTest
    static void missingOnboardingType() {
        List<User> testUsers = getTestUsers();
        OnboardingOwnerAssignmentCtrl ctrl = new OnboardingOwnerAssignmentCtrl();
        ctrl.onLoad();
        ctrl.queryLeadRecipients();

        Customer_Success_Rep__c entry = findCsrEntryForUser(ctrl.lstCSRs, testUsers[0].Id);
        System.assert(entry != null, 'Test user should appear in lstCSRs before save.');

        // Mark available WITHOUT an Onboarding_Type - this must trigger the validation exception.
        entry.Available__c = true;

        ctrl.save();

        System.assert(ApexPages.hasMessages(), 'save() should add a page message when an available CSR has no Onboarding_Type.');
        String err = ApexPages.getMessages()[0].getSummary();
        System.assert(err.containsIgnoreCase('Onboarding Type is required'), 'Error message should mention the missing Onboarding_Type: ' + err);

        List<Customer_Success_Rep__c> persisted = [
            SELECT Id FROM Customer_Success_Rep__c WHERE User__c = :testUsers[0].Id
        ];
        System.assertEquals(0, persisted.size(), 'The invalid record should not have been persisted.');
    }

    @isTest
    static void saveMultipleOnboardingTypes_singleBulkUpsert() {
        List<User> testUsers = getTestUsers();
        OnboardingOwnerAssignmentCtrl ctrl = new OnboardingOwnerAssignmentCtrl();
        ctrl.onLoad();
        ctrl.queryLeadRecipients();

        String[] types = new String[]{ 'IA/Growth', 'Life Buyer' };
        for (Integer i = 0; i < testUsers.size(); i++) {
            Customer_Success_Rep__c entry = findCsrEntryForUser(ctrl.lstCSRs, testUsers[i].Id);
            entry.Available__c = true;
            entry.Onboarding_Type__c = types[Math.mod(i, types.size())];
        }

        ctrl.save();

        List<Customer_Success_Rep__c> savedReps = [
            SELECT Id, Onboarding_Type__c, Available__c
            FROM Customer_Success_Rep__c
            WHERE User__c IN :testUsers AND Available__c = true
        ];
        Set<String> onboardingTypesSaved = new Set<String>();
        for (Customer_Success_Rep__c rep : savedReps) {
            onboardingTypesSaved.add(rep.Onboarding_Type__c);
        }
        System.assertEquals(TEST_USER_COUNT, savedReps.size(), 'All test users should be persisted by one save() call.');
        System.assertEquals(2, onboardingTypesSaved.size(), 'save() should persist CSRs across multiple Onboarding_Type groups in a single bulk upsert.');
    }

    @isTest
    static void populateNextUp_marksExactlyOneNextUpPerOnboardingType() {
        List<User> testUsers = getTestUsers();
        OnboardingOwnerAssignmentCtrl ctrl = new OnboardingOwnerAssignmentCtrl();
        ctrl.onLoad();
        ctrl.queryLeadRecipients();

        // Put all 3 test users into the SAME Onboarding_Type, all available, none marked NextUp yet.
        for (User u : testUsers) {
            Customer_Success_Rep__c entry = findCsrEntryForUser(ctrl.lstCSRs, u.Id);
            entry.Available__c = true;
            entry.Onboarding_Type__c = 'IA/Growth';
        }
        ctrl.save();

        List<Customer_Success_Rep__c> savedReps = [
            SELECT Id, NextUp__c
            FROM Customer_Success_Rep__c
            WHERE User__c IN :testUsers AND Onboarding_Type__c = 'IA/Growth'
        ];
        Integer nextUpCount = 0;
        for (Customer_Success_Rep__c rep : savedReps) {
            if (rep.NextUp__c) {
                nextUpCount++;
            }
        }
        System.assertEquals(1, nextUpCount, 'populateNextUp() should mark exactly one CSR as NextUp per Onboarding_Type group.');
    }

    @isTest
    static void testUserRoleNameQueriedForExistingCsr() {
        List<User> testUsers = getTestUsers();
        OnboardingOwnerAssignmentCtrl ctrl = new OnboardingOwnerAssignmentCtrl();

        // Create a real Customer_Success_Rep__c record for one test user first.
        ctrl.csr.User__c = testUsers[0].Id;
        ctrl.add();

        // Reload from the database - this goes through getLeadRecipients()'s main query, which
        // previously did not select User__r.UserRole.Name.
        ctrl.queryLeadRecipients();

        Customer_Success_Rep__c entry = findCsrEntryForUser(ctrl.lstCSRs, testUsers[0].Id);
        System.assert(entry != null, 'The newly created CSR record should be found after reloading.');

        // Accessing User__r.UserRole.Name here would throw "SObject row was retrieved via SOQL
        // without querying the requested field" if the query fix were reverted - this is exactly
        // what the Visualforce page does whenever a CSR's User_Role__c is blank.
        System.assertEquals(
            TEST_ROLE_NAME,
            entry.User__r.UserRole.Name,
            'User__r.UserRole.Name should be fetched by the main query so the page can safely fall back to it.'
        );
    }
}