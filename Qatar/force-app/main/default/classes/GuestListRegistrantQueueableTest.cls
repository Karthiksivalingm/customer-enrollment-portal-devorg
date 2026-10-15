@isTest
private class GuestListRegistrantQueueableTest {

    // Always returns 429 for anything under /contacts (search or create),
    // 200 for the OAuth token call. findContactIdByEmail() swallows its own
    // exception internally and returns null, so the 429 actually surfaces
    // to the queueable when createContact() is called next — this reliably
    // exercises the retry path regardless of call ordering.
    private class AlwaysRateLimitedContactMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            if (req.getEndpoint().contains('/oauth2/token')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"test-token-123"}');
                return res;
            }
            if (req.getEndpoint().contains('/contacts')) {
                res.setStatusCode(429);
                res.setHeader('X-Rate-Limit-Reset', '5');
                res.setBody('{"error":"rate limited"}');
                return res;
            }
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }

    private static Invitation__c makeInvitation(String extId) {
        Invitation__c inv = new Invitation__c(External_Event_Id__c = extId, Name = 'Test Event');
        insert inv;
        return inv;
    }

    private static Contact makeContact(String extId, String email) {
        Contact c = new Contact(
            FirstName = 'Jane', LastName = 'Doe',
            Email = email, contact_external_id__c = extId
        );
        insert c;
        return c;
    }

    @isTest
    static void testSuccessfulInvitationListPush() {
        Invitation__c inv = makeInvitation('1001');
        Contact c = makeContact(null, 'jane.doe@example.com');
        Guest_List__c g = new Guest_List__c(
            Contact__c = c.Id, Invitation__c = inv.Id,
            Approval__c = 'Approved', Guest_Tiers__c = 'VIP'
        );
        insert g;

        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        System.enqueueJob(new GuestListRegistrantQueueable(new Set<Id>{ g.Id }));
        Test.stopTest();

        Guest_List__c updated = [SELECT Swoogo_Push_Status__c FROM Guest_List__c WHERE Id = :g.Id];
        System.assert(updated.Swoogo_Push_Status__c.startsWith('Success - Added to invitation list'));
    }

    @isTest
    static void testChildGuestDirectRegistrationSuccess() {
        Invitation__c inv = makeInvitation('1001');
        Contact mainContact = makeContact('9001', 'main.guest@example.com');
        Guest_List__c mainGuest = new Guest_List__c(
            Contact__c = mainContact.Id, Invitation__c = inv.Id,
            Approval__c = 'Approved', Guest_Tiers__c = 'VIP',
            Swoogo_Registrant_Id__c = '2999'
        );
        insert mainGuest;

        Contact childContact = makeContact(null, 'child.guest@example.com');
        Guest_List__c childGuest = new Guest_List__c(
            Contact__c = childContact.Id, Invitation__c = inv.Id,
            Approval__c = 'Approved', Guest_Tiers__c = 'VIP',
            Main_Guest__c = mainGuest.Id
        );
        insert childGuest;

        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        System.enqueueJob(new GuestListRegistrantQueueable(new Set<Id>{ childGuest.Id }));
        Test.stopTest();

        Guest_List__c updated = [
            SELECT Swoogo_Push_Status__c, Swoogo_Registrant_Id__c
            FROM Guest_List__c WHERE Id = :childGuest.Id
        ];
        System.assert(updated.Swoogo_Push_Status__c.startsWith('Success - Registered and added to group'));
        System.assertNotEquals(null, updated.Swoogo_Registrant_Id__c);
    }

    @isTest
    static void testChildGuestFailsWhenMainGuestNotYetRegistered() {
        Invitation__c inv = makeInvitation('1001');
        Contact mainContact = makeContact('9001', 'main.guest@example.com');
        Guest_List__c mainGuest = new Guest_List__c(
            Contact__c = mainContact.Id, Invitation__c = inv.Id,
            Approval__c = 'Approved', Guest_Tiers__c = 'VIP'
            // no Swoogo_Registrant_Id__c yet
        );
        insert mainGuest;

        Contact childContact = makeContact(null, 'child.guest@example.com');
        Guest_List__c childGuest = new Guest_List__c(
            Contact__c = childContact.Id, Invitation__c = inv.Id,
            Approval__c = 'Approved', Guest_Tiers__c = 'VIP',
            Main_Guest__c = mainGuest.Id
        );
        insert childGuest;

        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        System.enqueueJob(new GuestListRegistrantQueueable(new Set<Id>{ childGuest.Id }));
        Test.stopTest();

        Guest_List__c updated = [SELECT Swoogo_Push_Status__c FROM Guest_List__c WHERE Id = :childGuest.Id];
        System.assert(updated.Swoogo_Push_Status__c.startsWith('Failed - Main guest has no Swoogo_Registrant_Id__c'));
    }

    @isTest
    static void testFailureBranchesNoEventIdNoContactNoTier() {
        Invitation__c invNoEventId = new Invitation__c(Name = 'No Event Id');
        insert invNoEventId;
        Invitation__c inv = makeInvitation('1001');

        Contact okContact = makeContact(null, 'ok@example.com');
        // Contact__c is a required field on Guest_List__c in this org, so
        // this can't be left null. Use a real Contact with a blank Email
        // instead to exercise the "no contact/email" branch.
        Contact noEmailContact = new Contact(FirstName = 'No', LastName = 'Email');
        insert noEmailContact;

        Guest_List__c gNoEventId = new Guest_List__c(
            Contact__c = okContact.Id, Invitation__c = invNoEventId.Id,
            Approval__c = 'Approved', Guest_Tiers__c = 'VIP'
        );
        Guest_List__c gNoEmail = new Guest_List__c(
            Contact__c = noEmailContact.Id, Invitation__c = inv.Id,
            Approval__c = 'Approved', Guest_Tiers__c = 'VIP'
        );
        Guest_List__c gNoTier = new Guest_List__c(
            Contact__c = okContact.Id, Invitation__c = inv.Id,
            Approval__c = 'Approved'
        );
        insert new List<Guest_List__c>{ gNoEventId, gNoEmail, gNoTier };

        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        System.enqueueJob(new GuestListRegistrantQueueable(
            new Set<Id>{ gNoEventId.Id, gNoEmail.Id, gNoTier.Id }));
        Test.stopTest();

        Map<Id, Guest_List__c> updated = new Map<Id, Guest_List__c>([
            SELECT Swoogo_Push_Status__c FROM Guest_List__c
            WHERE Id IN (:gNoEventId.Id, :gNoEmail.Id, :gNoTier.Id)
        ]);
        System.assert(updated.get(gNoEventId.Id).Swoogo_Push_Status__c.startsWith('Failed - No event ID found'));
        System.assert(updated.get(gNoEmail.Id).Swoogo_Push_Status__c.startsWith('Failed - No contact/email found'));
        System.assert(updated.get(gNoTier.Id).Swoogo_Push_Status__c.startsWith('Failed - No Guest Tier set'));
    }

    @isTest
    static void testNoMatchingInvitationList() {
        Invitation__c inv = makeInvitation('1001');
        Contact c = makeContact(null, 'unmatched@example.com');
        Guest_List__c g = new Guest_List__c(
            Contact__c = c.Id, Invitation__c = inv.Id,
            Approval__c = 'Approved', Guest_Tiers__c = 'Not A Real Tier'
        );
        insert g;

        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        System.enqueueJob(new GuestListRegistrantQueueable(new Set<Id>{ g.Id }));
        Test.stopTest();

        Guest_List__c updated = [SELECT Swoogo_Push_Status__c FROM Guest_List__c WHERE Id = :g.Id];
        System.assert(updated.Swoogo_Push_Status__c.startsWith('Failed - WARNING: no invitation list'));
    }

    @isTest
    static void testIdempotencySkipsAlreadySucceededGuest() {
        Invitation__c inv = makeInvitation('1001');
        Contact c = makeContact(null, 'already@example.com');
        Guest_List__c g = new Guest_List__c(
            Contact__c = c.Id, Invitation__c = inv.Id,
            Approval__c = 'Approved', Guest_Tiers__c = 'VIP',
            Swoogo_Push_Status__c = 'Success - Added to invitation list "VIP"'
        );
        insert g;

        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        System.enqueueJob(new GuestListRegistrantQueueable(new Set<Id>{ g.Id }));
        Test.stopTest();

        Guest_List__c updated = [SELECT Swoogo_Push_Status__c FROM Guest_List__c WHERE Id = :g.Id];
        System.assertEquals('Success - Added to invitation list "VIP"', updated.Swoogo_Push_Status__c);
    }

    @isTest
    static void testNonApprovedGuestIsIgnored() {
        Invitation__c inv = makeInvitation('1001');
        Contact c = makeContact(null, 'pending@example.com');
        Guest_List__c g = new Guest_List__c(
            Contact__c = c.Id, Invitation__c = inv.Id,
            Approval__c = 'Pending', Guest_Tiers__c = 'VIP'
        );
        insert g;

        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        System.enqueueJob(new GuestListRegistrantQueueable(new Set<Id>{ g.Id }));
        Test.stopTest();

        Guest_List__c updated = [SELECT Swoogo_Push_Status__c FROM Guest_List__c WHERE Id = :g.Id];
        System.assertEquals(null, updated.Swoogo_Push_Status__c);
    }

    @isTest
    static void testRateLimitTriggersRetryScheduling() {
        Invitation__c inv = makeInvitation('1001');
        Contact c = makeContact(null, 'ratelimited@example.com');
        Guest_List__c g = new Guest_List__c(
            Contact__c = c.Id, Invitation__c = inv.Id,
            Approval__c = 'Approved', Guest_Tiers__c = 'VIP'
        );
        insert g;

        Test.setMock(HttpCalloutMock.class, new AlwaysRateLimitedContactMock());
        Test.startTest();
        System.enqueueJob(new GuestListRegistrantQueueable(new Set<Id>{ g.Id }));
        Test.stopTest();

        Guest_List__c updated = [SELECT Swoogo_Push_Status__c FROM Guest_List__c WHERE Id = :g.Id];
        System.assert(updated.Swoogo_Push_Status__c.startsWith('Retry Pending'));

        List<CronTrigger> retryJobs = [
            SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE 'GuestListRetry%'
        ];
        System.assert(!retryJobs.isEmpty());
    }
}