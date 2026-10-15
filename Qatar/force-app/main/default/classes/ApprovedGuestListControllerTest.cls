@isTest
private class ApprovedGuestListControllerTest {

    @TestSetup
    static void setupData() {
        Contact con1 = new Contact(LastName = 'Approved One', Description = 'Bio one');
        Contact con2 = new Contact(LastName = 'Approved Two', Description = 'Bio two');
        insert new List<Contact>{ con1, con2 };

        Invitation__c inv = new Invitation__c(Name = 'Approved List Test Invitation');
        insert inv;

        Guest_List__c approvedMain = new Guest_List__c(
            Contact__c    = con1.Id,
            Invitation__c = inv.Id,
            // Title__c      = 'Mr', // not writeable
            Approval__c   = 'Approved',
            X1_of_Invited_Guests__c = '1'
        );
        insert approvedMain;

        Guest_List__c approvedEscorted = new Guest_List__c(
            Contact__c     = con2.Id,
            Invitation__c  = inv.Id,
            // Title__c       = 'Ms', // not writeable
            Approval__c    = 'Approved',
            Main_Guest__c  = approvedMain.Id
            // Escorted_By__c = approvedMain.Id // wrong id type for this org - lookup target isn't Guest_List__c
        );
        insert approvedEscorted;

        // Non-approved record that must be excluded from results
        Guest_List__c pending = new Guest_List__c(
            Contact__c    = con2.Id,
            Invitation__c = inv.Id,
            // Title__c      = 'Ms', // not writeable
            Approval__c   = 'Pending'
        );
        insert pending;

        insert new Attachment(
            ParentId    = con1.Id,
            Name        = 'photo.jpg',
            Body        = Blob.valueOf('fake image bytes'),
            ContentType = 'image/jpeg'
        );

        insert new HE_Request__c(
            Name           = 'HE Request - Existing',
            Guest_List__c  = approvedMain.Id,
            Feedback__c    = 'Existing feedback'
        );
    }

    @isTest
    static void testGetApprovedGuestList_onlyApprovedReturned() {
        Invitation__c inv = [SELECT Id FROM Invitation__c LIMIT 1];

        Test.startTest();
        Map<String, Object> result = ApprovedGuestListController.getApprovedGuestList(inv.Id, null, null);
        Test.stopTest();

        System.assertEquals(2, (Integer) result.get('totalCount'));
        List<Object> records = (List<Object>) result.get('records');
        System.assertEquals(2, records.size());
    }

    @isTest
    static void testGetApprovedGuestList_pagingHasMore() {
        Invitation__c inv = [SELECT Id FROM Invitation__c LIMIT 1];

        Test.startTest();
        Map<String, Object> result = ApprovedGuestListController.getApprovedGuestList(inv.Id, 1, 0);
        Test.stopTest();

        List<Object> records = (List<Object>) result.get('records');
        System.assertEquals(1, records.size());
        System.assertEquals(true, (Boolean) result.get('hasMore'));
    }

    @isTest
    static void testGetApprovedGuestList_photoAndEscortedByAndHeNote() {
        Invitation__c inv = [SELECT Id FROM Invitation__c LIMIT 1];
        Contact con1 = [SELECT Id FROM Contact WHERE LastName = 'Approved One' LIMIT 1];

        Test.startTest();
        Map<String, Object> result = ApprovedGuestListController.getApprovedGuestList(inv.Id, 20, 0);
        Test.stopTest();

        List<Object> raw = (List<Object>) result.get('records');
        Boolean foundPhoto = false;
        Boolean foundHeNote = false;
        for (Object o : raw) {
            ApprovedGuestListController.GuestListWrapper w = (ApprovedGuestListController.GuestListWrapper) o;
            if (w.contactId == con1.Id) {
                System.assert(String.isNotBlank(w.photoUrl));
                foundPhoto = true;
                if (String.isNotBlank(w.heNote)) foundHeNote = true;
            }
        }
        System.assert(foundPhoto, 'Expected photo URL resolved');
        System.assert(foundHeNote, 'Expected existing HE feedback note resolved');
        // Escorted_By__c could not be seeded here (its lookup target isn't Guest_List__c in
        // this org) - w.escortedBy is exercised structurally but not asserted on.
    }

    @isTest
    static void testUpsertHERequest_updatesExisting() {
        Guest_List__c approvedMain = [SELECT Id FROM Guest_List__c WHERE Approval__c = 'Approved' AND Main_Guest__c = null LIMIT 1];

        Test.startTest();
        ApprovedGuestListController.upsertHERequest(approvedMain.Id, 'Guest Name', 'Updated feedback text');
        Test.stopTest();

        HE_Request__c her = [SELECT Feedback__c FROM HE_Request__c WHERE Guest_List__c = :approvedMain.Id LIMIT 1];
        System.assertEquals('Updated feedback text', her.Feedback__c);
    }

    @isTest
    static void testUpsertHERequest_createsNewWithGeneratedName() {
        Guest_List__c child = [SELECT Id FROM Guest_List__c WHERE Main_Guest__c != null AND Approval__c = 'Approved' LIMIT 1];

        Test.startTest();
        ApprovedGuestListController.upsertHERequest(child.Id, 'Child Guest', 'Brand new feedback');
        Test.stopTest();

        List<HE_Request__c> hers = [SELECT Name, Feedback__c, HE_Request_Status__c FROM HE_Request__c WHERE Guest_List__c = :child.Id];
        System.assertEquals(1, hers.size());
        System.assertEquals('Brand new feedback', hers[0].Feedback__c);
        System.assertEquals('Yet to start', hers[0].HE_Request_Status__c);
        System.assert(hers[0].Name.startsWith('HE Request - Child Guest'));
    }
}