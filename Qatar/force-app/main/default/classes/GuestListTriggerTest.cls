@isTest
private class GuestListTriggerTest {

    // Generic mock so GuestListRegistrantQueueable callouts don't fail
    private class SwoogoMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"access_token":"test","items":[],"id":1,"_meta":{"totalCount":0}}');
            return res;
        }
    }

    @testSetup
    static void setup() {
        // Enable the trigger via custom setting
        insert new Swoogo_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Enable_Guest_List_Trigger__c = true
        );

        Contact mainContact = new Contact(FirstName = 'Main', LastName = 'Guest', Email = 'main.guest@test.com');
        Contact childContact = new Contact(FirstName = 'Plus', LastName = 'One', Email = 'plus.one@test.com');
        insert new List<Contact>{ mainContact, childContact };

        // Inserted WITHOUT Approval = 'Approved' so the update is a real change
        Guest_List__c mainGuest = new Guest_List__c(Contact__c = mainContact.Id);
        insert mainGuest;

        Guest_List__c child = new Guest_List__c(
            Contact__c = childContact.Id,
            Main_Guest__c = mainGuest.Id
        );
        insert child;
    }

    private static Guest_List__c getMain() {
        return [SELECT Id, Import_from_Swoogo__c FROM Guest_List__c WHERE Main_Guest__c = null LIMIT 1];
    }

    private static Guest_List__c getChild() {
        return [SELECT Id FROM Guest_List__c WHERE Main_Guest__c != null LIMIT 1];
    }

    @isTest
    static void mainGuestApproved_enqueuesJob() {
        Test.setMock(HttpCalloutMock.class, new SwoogoMock());
        Guest_List__c g = getMain();

        Test.startTest();
        g.Approval__c = 'Approved';
        update g;
        System.assertEquals(1, Limits.getQueueableJobs(), 'Main guest should be pushed');
        Test.stopTest();
    }

    @isTest
    static void mainGuestImportedFromSwoogo_notPushed() {
        Test.setMock(HttpCalloutMock.class, new SwoogoMock());
        Guest_List__c g = getMain();
        g.Import_from_Swoogo__c = true;
        update g;

        Test.startTest();
        g.Approval__c = 'Approved';
        update g;
        System.assertEquals(0, Limits.getQueueableJobs(), 'Imported main guest should not be pushed');
        Test.stopTest();
    }

    @isTest
    static void childApproved_parentNotAccepted_setsPending() {
        Test.setMock(HttpCalloutMock.class, new SwoogoMock());
        Guest_List__c child = getChild();

        Test.startTest();
        child.Approval__c = 'Approved';
        update child;
        System.assertEquals(0, Limits.getQueueableJobs(), 'Child should not be pushed yet');
        Test.stopTest();

        child = [SELECT Swoogo_Push_Status__c FROM Guest_List__c WHERE Id = :child.Id];
        System.assertEquals('Pending - waiting for main guest invitation acceptance',
            child.Swoogo_Push_Status__c);
    }

    @isTest
    static void childApproved_parentAccepted_enqueuesJob() {
        Test.setMock(HttpCalloutMock.class, new SwoogoMock());

        Guest_List__c mainGuest = getMain();
        mainGuest.Invitation_Status__c = 'Accepted';
        update mainGuest;

        Guest_List__c child = getChild();

        Test.startTest();
        child.Approval__c = 'Approved';
        update child;
        System.assertEquals(1, Limits.getQueueableJobs(), 'Child should be pushed immediately');
        Test.stopTest();
    }

    @isTest
    static void mainGuestAccepts_enqueuesWaitingChildren() {
        Test.setMock(HttpCalloutMock.class, new SwoogoMock());

        // Child approved first -> goes to Pending
        Guest_List__c child = getChild();
        child.Approval__c = 'Approved';
        update child;

        Guest_List__c mainGuest = getMain();

        Test.startTest();
        mainGuest.Invitation_Status__c = 'Accepted';
        update mainGuest;
        System.assertEquals(1, Limits.getQueueableJobs(), 'Waiting child should be pushed');
        Test.stopTest();
    }

    @isTest
    static void triggerDisabled_skipsEverything() {
        Swoogo_Settings__c s = Swoogo_Settings__c.getOrgDefaults();
        s.Enable_Guest_List_Trigger__c = false;
        update s;

        Guest_List__c g = getMain();

        Test.startTest();
        g.Approval__c = 'Approved';
        update g;
        System.assertEquals(0, Limits.getQueueableJobs(), 'Trigger should be skipped');
        Test.stopTest();
    }
}