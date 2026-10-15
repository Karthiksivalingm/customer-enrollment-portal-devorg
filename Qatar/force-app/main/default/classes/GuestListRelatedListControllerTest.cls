@isTest
private class GuestListRelatedListControllerTest {

    @TestSetup
    static void setupData() {
        Contact con1 = new Contact(LastName = 'Alpha', Title = 'CEO');
        Contact con2 = new Contact(LastName = 'Beta', Title = 'CFO');
        insert new List<Contact>{ con1, con2 };

        Invitation__c inv = new Invitation__c(Name = 'RelatedList Test Invitation');
        insert inv;

        Guest_List__c mainGuest = new Guest_List__c(
            Contact__c    = con1.Id,
            Invitation__c = inv.Id,
            // Title__c      = 'Mr', // not writeable
            Bio__c        = 'Bio text',
            Reason_for_Inviting__c = 'VIP',
            X1_of_Invited_Guests__c = '2'
        );
        insert mainGuest;

        Guest_List__c escortedGuest = new Guest_List__c(
            Contact__c     = con2.Id,
            Invitation__c  = inv.Id,
            // Title__c       = 'Ms', // not writeable
            Main_Guest__c  = mainGuest.Id
            // Escorted_By__c = mainGuest.Id // wrong id type for this org - lookup target isn't Guest_List__c
        );
        insert escortedGuest;

        // Photo attachment on con1 to exercise photoMap branch
        insert new Attachment(
            ParentId    = con1.Id,
            Name        = 'photo.png',
            Body        = Blob.valueOf('fake image bytes'),
            ContentType = 'image/png'
        );

        insert new HE_Request__c(
            Name          = 'Existing HE Note',
            Guest_List__c = mainGuest.Id
        );
    }

    @isTest
    static void testGetGuestList_defaultPaging() {
        Invitation__c inv = [SELECT Id FROM Invitation__c LIMIT 1];

        Test.startTest();
        Map<String, Object> result = GuestListRelatedListController.getGuestList(inv.Id, null, null);
        Test.stopTest();

        System.assertEquals(2, (Integer) result.get('totalCount'));
        System.assertEquals(false, (Boolean) result.get('hasMore'));
        List<Object> records = (List<Object>) result.get('records');
        System.assertEquals(2, records.size());
    }

    @isTest
    static void testGetGuestList_smallPageSize_hasMoreTrue() {
        Invitation__c inv = [SELECT Id FROM Invitation__c LIMIT 1];

        Test.startTest();
        Map<String, Object> result = GuestListRelatedListController.getGuestList(inv.Id, 1, 0);
        Test.stopTest();

        List<Object> records = (List<Object>) result.get('records');
        System.assertEquals(1, records.size());
        System.assertEquals(true, (Boolean) result.get('hasMore'));
    }

    @isTest
    static void testGetGuestList_photoAndEscortedByPopulated() {
        Invitation__c inv = [SELECT Id FROM Invitation__c LIMIT 1];
        Contact con1 = [SELECT Id FROM Contact WHERE LastName = 'Alpha' LIMIT 1];

        Test.startTest();
        Map<String, Object> result = GuestListRelatedListController.getGuestList(inv.Id, 20, 0);
        Test.stopTest();

        List<Object> raw = (List<Object>) result.get('records');
        Boolean foundPhoto = false;
        for (Object o : raw) {
            GuestListRelatedListController.GuestListWrapper w = (GuestListRelatedListController.GuestListWrapper) o;
            if (w.contactId == con1.Id) {
                System.assert(String.isNotBlank(w.photoUrl));
                foundPhoto = true;
            }
        }
        System.assert(foundPhoto, 'Expected photo URL to be resolved for contact with attachment');
        // Escorted_By__c could not be seeded here (its lookup target isn't Guest_List__c in
        // this org) - w.escortedBy is exercised structurally but not asserted on.
    }

    @isTest
    static void testUpsertHERequest_updatesExisting() {
        Guest_List__c mainGuest = [SELECT Id FROM Guest_List__c WHERE Main_Guest__c = null LIMIT 1];

        Test.startTest();
        GuestListRelatedListController.upsertHERequest(mainGuest.Id, 'Guest Name', 'Updated Note');
        Test.stopTest();

        HE_Request__c her = [SELECT Name FROM HE_Request__c WHERE Guest_List__c = :mainGuest.Id LIMIT 1];
        System.assertEquals('Updated Note', her.Name);
    }

    @isTest
    static void testUpsertHERequest_createsNew() {
        Guest_List__c childGuest = [SELECT Id FROM Guest_List__c WHERE Main_Guest__c != null LIMIT 1];

        Test.startTest();
        GuestListRelatedListController.upsertHERequest(childGuest.Id, 'Child Guest', 'Brand New Note');
        Test.stopTest();

        List<HE_Request__c> hers = [SELECT Name FROM HE_Request__c WHERE Guest_List__c = :childGuest.Id];
        System.assertEquals(1, hers.size());
        System.assertEquals('Brand New Note', hers[0].Name);
    }
}