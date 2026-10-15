@isTest
private class GuestListInvitationControllerTest {

    @TestSetup
    static void setupData() {
        Contact con1 = new Contact(LastName = 'Guest One');
        Contact con2 = new Contact(LastName = 'Guest Two');
        Contact con3 = new Contact(LastName = 'Guest Three');
        insert new List<Contact>{ con1, con2, con3 };

        Invitation__c invReq = new Invitation__c(
            Name = 'Test Invitation Required',
            Accompanying_Guest_Approval_Required__c = true
        );
        Invitation__c invNotReq = new Invitation__c(
            Name = 'Test Invitation Not Required',
            Accompanying_Guest_Approval_Required__c = false
        );
        insert new List<Invitation__c>{ invReq, invNotReq };

        // Main guest, actionable (Approval__c not Approved/Pending), no Main_Guest__c
        Guest_List__c mainGuest = new Guest_List__c(
            Contact__c    = con1.Id,
            Invitation__c = invReq.Id,
            // Title__c      = 'Mr', // not writeable
            Reason_for_Inviting__c = 'VIP',
            Approval__c   = 'Draft'
        );
        insert mainGuest;

        // Accompanying guest linked to mainGuest, actionable
        Guest_List__c accompanyingActionable = new Guest_List__c(
            Contact__c    = con2.Id,
            Invitation__c = invReq.Id,
            // Title__c      = 'Ms', // not writeable
            Reason_for_Inviting__c = 'VIP',
            Approval__c   = 'Draft',
            Main_Guest__c = mainGuest.Id
        );
        insert accompanyingActionable;

        // Accompanying guest already approved -> should be backfilled read-only under main
        Guest_List__c accompanyingApproved = new Guest_List__c(
            Contact__c    = con3.Id,
            Invitation__c = invReq.Id,
            // Title__c      = 'Dr', // not writeable
            Reason_for_Inviting__c = 'VIP',
            Approval__c   = 'Approved',
            Main_Guest__c = mainGuest.Id
        );
        insert accompanyingApproved;

        // Invitation where accompanying approval is NOT required
        Guest_List__c mainGuestNotReq = new Guest_List__c(
            Contact__c    = con1.Id,
            Invitation__c = invNotReq.Id,
            // Title__c      = 'Mr', // not writeable
            Reason_for_Inviting__c = 'VIP',
            Approval__c   = 'Draft'
        );
        insert mainGuestNotReq;

        Guest_List__c accompanyingNotReq = new Guest_List__c(
            Contact__c    = con2.Id,
            Invitation__c = invNotReq.Id,
            // Title__c      = 'Ms', // not writeable
            Reason_for_Inviting__c = 'VIP',
            Approval__c   = 'Draft',
            Main_Guest__c = mainGuestNotReq.Id
        );
        insert accompanyingNotReq;
    }

    @isTest
    static void testGetGuestLists_accompanyingApprovalRequired() {
        Invitation__c inv = [SELECT Id FROM Invitation__c WHERE Name = 'Test Invitation Required' LIMIT 1];

        Test.startTest();
        List<GuestListInvitationController.GuestRow> rows = GuestListInvitationController.getGuestLists(inv.Id);
        Test.stopTest();

        // main (actionable) + accompanying draft (actionable) + accompanying approved (backfilled read-only)
        System.assertEquals(3, rows.size(), 'Expected main + actionable accompanying + backfilled approved accompanying');

        Map<Id, GuestListInvitationController.GuestRow> rowsById = new Map<Id, GuestListInvitationController.GuestRow>();
        for (GuestListInvitationController.GuestRow r : rows) {
            rowsById.put(r.id, r);
        }

        Guest_List__c mainGuest = [SELECT Id FROM Guest_List__c WHERE Main_Guest__c = null AND Invitation__c = :inv.Id LIMIT 1];
        System.assert(rowsById.containsKey(mainGuest.Id));
        System.assert(rowsById.get(mainGuest.Id).isActionable);

        Boolean foundApprovedReadOnly = false;
        for (GuestListInvitationController.GuestRow r : rows) {
            if (r.mainGuestId != null && r.approvalC == 'Approved') {
                foundApprovedReadOnly = true;
                System.assertEquals(false, r.isActionable, 'Approved accompanying guest should be read-only backfill');
                System.assertEquals('Approved', r.statusLabel);
            }
        }
        System.assert(foundApprovedReadOnly);
    }

    @isTest
    static void testGetGuestLists_accompanyingApprovalNotRequired() {
        Invitation__c inv = [SELECT Id FROM Invitation__c WHERE Name = 'Test Invitation Not Required' LIMIT 1];

        Test.startTest();
        List<GuestListInvitationController.GuestRow> rows = GuestListInvitationController.getGuestLists(inv.Id);
        Test.stopTest();

        // Only the main-guest branch is actionable; accompanying is backfilled read-only.
        System.assertEquals(2, rows.size());

        Boolean foundActionableMain = false;
        Boolean foundReadOnlyChild  = false;
        for (GuestListInvitationController.GuestRow r : rows) {
            if (r.mainGuestId == null && r.isActionable) foundActionableMain = true;
            if (r.mainGuestId != null && !r.isActionable) foundReadOnlyChild = true;
        }
        System.assert(foundActionableMain);
        System.assert(foundReadOnlyChild);
    }

    @isTest
    static void testGetGuestLists_noRecords() {
        Invitation__c emptyInv = new Invitation__c(
            Name = 'Empty Invitation',
            Accompanying_Guest_Approval_Required__c = true
        );
        insert emptyInv;

        Test.startTest();
        List<GuestListInvitationController.GuestRow> rows = GuestListInvitationController.getGuestLists(emptyInv.Id);
        Test.stopTest();

        System.assertEquals(0, rows.size());
    }

    @isTest
    static void testSubmitForApproval_emptyAfterFilter_throws() {
        // Passing an empty list means toSubmit ends up empty -> guard exception.
        Test.startTest();
        Boolean caught = false;
        try {
            GuestListInvitationController.submitForApproval(new List<Id>());
        } catch (AuraHandledException e) {
            caught = true;
        }
        Test.stopTest();
        System.assert(caught, 'Expected AuraHandledException when nothing is submittable');
    }

    @isTest
    static void testSubmitForApproval_success() {
        Guest_List__c g = [SELECT Id FROM Guest_List__c WHERE Approval__c = 'Draft' LIMIT 1];

        Test.startTest();
        GuestListInvitationController.submitForApproval(new List<Id>{ g.Id });
        Test.stopTest();

        Guest_List__c refreshed = [SELECT Approval__c FROM Guest_List__c WHERE Id = :g.Id];
        System.assertEquals('Pending', refreshed.Approval__c);
    }

    @isTest
    static void testSubmitForApproval_alreadyInProcess_throws() {
        Guest_List__c g = [SELECT Id FROM Guest_List__c WHERE Approval__c = 'Draft' LIMIT 1];

        // First submission puts it into a live, non-terminal ProcessInstance.
        GuestListInvitationController.submitForApproval(new List<Id>{ g.Id });

        Test.startTest();
        Boolean caught = false;
        try {
            // Second submission of the same record should be filtered out as
            // already-in-process and hit the guard exception.
            GuestListInvitationController.submitForApproval(new List<Id>{ g.Id });
        } catch (AuraHandledException e) {
            caught = true;
        }
        Test.stopTest();
        System.assert(caught, 'Expected AuraHandledException when record is already in an approval process');
    }

    @isTest
    static void testGetGuestLists_mainGuestAlreadyInProcess_backfillsAsInProcess() {
        Guest_List__c mainGuest = [
            SELECT Id, Invitation__c FROM Guest_List__c
            WHERE Main_Guest__c = null AND Approval__c = 'Draft' AND Invitation__c IN (
                SELECT Id FROM Invitation__c WHERE Name = 'Test Invitation Required'
            )
            LIMIT 1
        ];

        // Submit only the main guest - its actionable accompanying sibling stays
        // untouched, so the main guest gets excluded from actionableRaw but backfilled
        // as a read-only "In Approval Process" row via referencedMainIds.
        GuestListInvitationController.submitForApproval(new List<Id>{ mainGuest.Id });

        Test.startTest();
        List<GuestListInvitationController.GuestRow> rows = GuestListInvitationController.getGuestLists(mainGuest.Invitation__c);
        Test.stopTest();

        Boolean foundInProcessMain = false;
        for (GuestListInvitationController.GuestRow r : rows) {
            if (r.id == mainGuest.Id) {
                System.assertEquals('In Approval Process', r.statusLabel);
                System.assertEquals(false, r.isActionable);
                foundInProcessMain = true;
            }
        }
        System.assert(foundInProcessMain, 'Expected main guest to be backfilled with In Approval Process status');
    }
}