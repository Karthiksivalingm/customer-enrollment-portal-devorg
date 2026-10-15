@isTest
private class SwoogoInvitationTierSyncServiceTest {

    @isTest
    static void testFetchInvitationTierMapViaMock() {
        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        Map<String, SwoogoInvitationTierSyncService.InvitationMembership> tierMap =
            SwoogoInvitationTierSyncService.fetchInvitationTierMap('1001');
        Test.stopTest();

        System.assert(tierMap.containsKey('9001'));
        System.assertEquals('VIP', tierMap.get('9001').listName);
        System.assertEquals('accepted', tierMap.get('9001').rawStatus);
    }

    @isTest
    static void testApplyInvitationTiersUpdatesGuestList() {
        Contact c = new Contact(
            FirstName = 'Jane', LastName = 'Doe', contact_external_id__c = '9001'
        );
        insert c;
        Invitation__c inv = new Invitation__c(External_Event_Id__c = '1001', Name = 'Test Event');
        insert inv;
        Guest_List__c g = new Guest_List__c(Contact__c = c.Id, Invitation__c = inv.Id);
        insert g;

        SwoogoInvitationTierSyncService.InvitationMembership mem =
            new SwoogoInvitationTierSyncService.InvitationMembership();
        mem.listName = 'VIP';
        mem.rawStatus = 'accepted';

        Map<String, SwoogoInvitationTierSyncService.InvitationMembership> tierMap =
            new Map<String, SwoogoInvitationTierSyncService.InvitationMembership>{ '9001' => mem };

        Test.startTest();
        SwoogoInvitationTierSyncService.applyInvitationTiers(inv.Id, tierMap);
        // No-op branches
        SwoogoInvitationTierSyncService.applyInvitationTiers(inv.Id, null);
        SwoogoInvitationTierSyncService.applyInvitationTiers(
            inv.Id, new Map<String, SwoogoInvitationTierSyncService.InvitationMembership>());
        Test.stopTest();

        Guest_List__c updated = [
            SELECT Invitation_Tier__c, Invitation_Status__c FROM Guest_List__c WHERE Id = :g.Id
        ];
        System.assertEquals('VIP', updated.Invitation_Tier__c);
        System.assertEquals('Accepted', updated.Invitation_Status__c);
    }

    @isTest
    static void testMapInvitationStatusAllBranches() {
        System.assertEquals(null, SwoogoInvitationTierSyncService.mapInvitationStatus(null));
        System.assertEquals('Bounced Email', SwoogoInvitationTierSyncService.mapInvitationStatus('not_sent'));
        System.assertEquals('Bounced Email', SwoogoInvitationTierSyncService.mapInvitationStatus('Pending'));
        System.assertEquals('No Response', SwoogoInvitationTierSyncService.mapInvitationStatus('sent'));
        System.assertEquals('No Response', SwoogoInvitationTierSyncService.mapInvitationStatus('Invited'));
        System.assertEquals('Visited', SwoogoInvitationTierSyncService.mapInvitationStatus('visited'));
        System.assertEquals('Visited', SwoogoInvitationTierSyncService.mapInvitationStatus('Opened'));
        System.assertEquals('Accepted', SwoogoInvitationTierSyncService.mapInvitationStatus('accepted'));
        System.assertEquals('Accepted', SwoogoInvitationTierSyncService.mapInvitationStatus('Confirmed'));
        System.assertEquals('Declined', SwoogoInvitationTierSyncService.mapInvitationStatus('declined'));
        System.assertEquals('Declined', SwoogoInvitationTierSyncService.mapInvitationStatus('Rejected'));
        System.assertEquals(null, SwoogoInvitationTierSyncService.mapInvitationStatus('totally-unknown-value'));
    }
}