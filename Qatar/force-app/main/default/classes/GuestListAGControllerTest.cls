@isTest
private class GuestListAGControllerTest {

    @TestSetup
    static void setup() {
        Contact mainContact = new Contact(LastName = 'MainGuestContact');
        insert mainContact;

        Contact childContact1 = new Contact(LastName = 'ChildOne', Email = 'child1@example.com');
        Contact childContact2 = new Contact(LastName = 'ChildTwo', Email = 'child2@example.com');
        insert new List<Contact>{ childContact1, childContact2 };

        Guest_List__c mainGuest = new Guest_List__c(Contact__c = mainContact.Id);
        insert mainGuest;

        Guest_List__c child1 = new Guest_List__c(
            Contact__c   = childContact1.Id,
            Main_Guest__c = mainGuest.Id,
            Guest_Tier_Recommendations__c = 'Local'
        );
        Guest_List__c child2 = new Guest_List__c(
            Contact__c   = childContact2.Id,
            Main_Guest__c = mainGuest.Id
        );
        insert new List<Guest_List__c>{ child1, child2 };
    }

    @isTest
    static void testGetAccompanyingGuests_returnsAllChildren() {
        Guest_List__c mainGuest = [SELECT Id FROM Guest_List__c WHERE Main_Guest__c = null LIMIT 1];

        Test.startTest();
        List<GuestListAccompanyingGuestsController.ChildGuestWrapper> results =
            GuestListAccompanyingGuestsController.getAccompanyingGuests(mainGuest.Id);
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Expected both child guests to be returned.');

        Set<String> returnedNames = new Set<String>();
        for (GuestListAccompanyingGuestsController.ChildGuestWrapper w : results) {
            System.assertNotEquals(null, w.id, 'Wrapper id should be populated.');
            System.assertNotEquals(null, w.contactId, 'Wrapper contactId should be populated.');
            returnedNames.add(w.contactName);
        }
        System.assert(returnedNames.contains('ChildOne'), 'Expected ChildOne in results.');
        System.assert(returnedNames.contains('ChildTwo'), 'Expected ChildTwo in results.');
    }

    @isTest
    static void testGetAccompanyingGuests_guestTierAndEmailMapped() {
        Guest_List__c mainGuest = [SELECT Id FROM Guest_List__c WHERE Main_Guest__c = null LIMIT 1];

        Test.startTest();
        List<GuestListAccompanyingGuestsController.ChildGuestWrapper> results =
            GuestListAccompanyingGuestsController.getAccompanyingGuests(mainGuest.Id);
        Test.stopTest();

        GuestListAccompanyingGuestsController.ChildGuestWrapper vipChild;
        for (GuestListAccompanyingGuestsController.ChildGuestWrapper w : results) {
            if (w.contactName == 'ChildOne') {
                vipChild = w;
            }
        }

        System.assertNotEquals(null, vipChild, 'Expected to find the ChildOne wrapper.');
        System.assertEquals('Local', vipChild.guestTier, 'Guest tier should be mapped from Guest_Tier_Recommendations__c.');
        System.assertEquals('child1@example.com', vipChild.contactEmail, 'Contact email should be mapped from Contact__r.Email.');
        System.assertNotEquals(null, vipChild.createdDate, 'CreatedDate should be populated.');
    }

    @isTest
    static void testGetAccompanyingGuests_noChildren_returnsEmptyList() {
        Contact lonelyContact = new Contact(LastName = 'NoChildrenContact');
        insert lonelyContact;

        Guest_List__c lonelyGuest = new Guest_List__c(Contact__c = lonelyContact.Id);
        insert lonelyGuest;

        Test.startTest();
        List<GuestListAccompanyingGuestsController.ChildGuestWrapper> results =
            GuestListAccompanyingGuestsController.getAccompanyingGuests(lonelyGuest.Id);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Expected no children for a guest with none.');
    }

    @isTest
    static void testGetAccompanyingGuests_nullParentId_returnsEmptyList() {
        Test.startTest();
        List<GuestListAccompanyingGuestsController.ChildGuestWrapper> results =
            GuestListAccompanyingGuestsController.getAccompanyingGuests(null);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Expected an empty list when parentGuestId is null.');
    }
}