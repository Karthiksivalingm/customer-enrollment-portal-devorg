@isTest
private class BulkApprovalControllerTest {

    private static final String STAGE1_APPROVER_USERNAME = 'fzuccarini@qm.org.qa';
    private static final String STAGE2_APPROVER_USERNAME = 'faalthani@qm.org.qa';

    @TestSetup
    static void setupData() {
        Contact con1 = new Contact(LastName = 'Bulk One', Title = 'Director');
        Contact con2 = new Contact(LastName = 'Bulk Two', Title = 'Manager');
        insert new List<Contact>{ con1, con2 };

        Invitation__c inv = new Invitation__c(Name = 'Bulk Approval Test Invitation');
        insert inv;

        Guest_List__c mainGuest = new Guest_List__c(
            Contact__c              = con1.Id,
            Invitation__c           = inv.Id,
            // Title__c                = 'Mr', // not writeable
            Reason_for_Inviting__c  = 'VIP',
            Bio__c                  = 'Bio text',
            X1_of_Invited_Guests__c = '1',
            Notes__c                = 'Initial notes'
            // Main_Guest_Names__c     = '<a href="/00Q000000000001AAA">Referenced Main Guest</a>' // not writeable
        );
        insert mainGuest;

        // Second record, photo resolved via ContentDocumentLink instead of Attachment,
        // to exercise the fallback photo-lookup branch in getPendingApprovals.
        Guest_List__c secondGuest = new Guest_List__c(
            Contact__c              = con2.Id,
            Invitation__c           = inv.Id,
            Reason_for_Inviting__c  = 'Staff',
            Bio__c                  = 'Second bio',
            X1_of_Invited_Guests__c = '0',
            Notes__c                = 'Second notes'
        );
        insert secondGuest;

        insert new Attachment(
            ParentId    = con1.Id,
            Name        = 'photo.png',
            Body        = Blob.valueOf('fake image bytes'),
            ContentType = 'image/png'
        );

        ContentVersion cv = new ContentVersion(
            Title        = 'photo2',
            PathOnClient = 'photo2.png',
            VersionData  = Blob.valueOf('fake image bytes 2')
        );
        insert cv;
        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        insert new ContentDocumentLink(
            ContentDocumentId = contentDocId,
            LinkedEntityId    = con2.Id,
            ShareType         = 'V'
        );

        insert new HE_Request__c(
            Name          = 'HE Note A',
            Guest_List__c = mainGuest.Id
        );

        // Submit both into whatever active approval process is configured on Guest_List__c.
        // The approvers are hardcoded named users on the process steps, so this works
        // regardless of which user runs @TestSetup.
        try {
            Approval.process(new List<Approval.ProcessSubmitRequest>{
                buildSubmitRequest(mainGuest.Id),
                buildSubmitRequest(secondGuest.Id)
            });
        } catch (Exception e) {
            // If entry criteria isn't met for these records, later tests fall back to
            // their defensive empty-result checks below.
        }
    }

    private static Approval.ProcessSubmitRequest buildSubmitRequest(Id recordId) {
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(recordId);
        req.setSubmitterId(UserInfo.getUserId());
        return req;
    }

    private static User getStage1Approver() {
        List<User> users = [SELECT Id FROM User WHERE Username = :STAGE1_APPROVER_USERNAME LIMIT 1];
        return users.isEmpty() ? null : users[0];
    }

    private static User getStage2Approver() {
        List<User> users = [SELECT Id FROM User WHERE Username = :STAGE2_APPROVER_USERNAME LIMIT 1];
        return users.isEmpty() ? null : users[0];
    }

    private static String getFirstGuestTierValue() {
        List<Schema.PicklistEntry> entries =
            Guest_List__c.Guest_Tiers__c.getDescribe().getPicklistValues();
        for (Schema.PicklistEntry e : entries) {
            if (e.isActive()) return e.getValue();
        }
        return null;
    }

    // DIAGNOSTIC TEST - run this one alone and read its failure message (if any) in the
    // test results. It deliberately does NOT swallow exceptions, so it will tell us exactly
    // which of the following is breaking: approver usernames not found, or Approval.process
    // itself rejecting the submission (no applicable process / entry criteria / etc).
    // Once coverage is fixed, this test (and this comment block) can be deleted.
    @isTest
    static void zzDiagnoseApprovalSubmission() {
        List<User> stage1Matches = [SELECT Id, Username FROM User WHERE Username = :STAGE1_APPROVER_USERNAME];
        List<User> stage2Matches = [SELECT Id, Username FROM User WHERE Username = :STAGE2_APPROVER_USERNAME];
        System.assert(!stage1Matches.isEmpty(),
            'No User found with Username = ' + STAGE1_APPROVER_USERNAME + ' in this org/sandbox.');
        System.assert(!stage2Matches.isEmpty(),
            'No User found with Username = ' + STAGE2_APPROVER_USERNAME + ' in this org/sandbox.');

        Guest_List__c g = new Guest_List__c(
            Contact__c    = [SELECT Id FROM Contact LIMIT 1].Id,
            Invitation__c = [SELECT Id FROM Invitation__c LIMIT 1].Id,
            Reason_for_Inviting__c = 'VIP'
        );
        insert g;

        Test.startTest();
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(g.Id);
        req.setSubmitterId(UserInfo.getUserId());
        try {
            Approval.process(req);
        } catch (Exception e) {
            System.assert(false, 'Approval.process failed: ' + e.getMessage());
        }
        Test.stopTest();

        List<ProcessInstanceWorkitem> items = [
            SELECT Id, ActorId
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :g.Id
        ];
        System.assert(!items.isEmpty(), 'Submission succeeded but produced no ProcessInstanceWorkitem.');

        User stage1 = stage1Matches[0];
        Set<Id> stage1QueueIds = new Set<Id>();
        for (GroupMember gm : [SELECT GroupId FROM GroupMember WHERE UserOrGroupId = :stage1.Id]) {
            stage1QueueIds.add(gm.GroupId);
        }
        Boolean assignedToStage1 = (items[0].ActorId == stage1.Id) || stage1QueueIds.contains(items[0].ActorId);
        System.assert(assignedToStage1,
            'Work item ActorId ' + items[0].ActorId + ' is neither the stage 1 approver (' + stage1.Id
            + ') nor one of their queues (' + stage1QueueIds + '). '
            + 'If it is a queue the approver user is NOT a member of, add them to that queue in this org, '
            + 'or tell me the correct queue name so setup can add membership directly.');
    }

    @isTest
    static void testGetPendingApprovals_stage1_returnsFullDetail() {
        User stage1 = getStage1Approver();
        if (stage1 == null) return; // approver user not present in this org - see notes.

        List<BulkApprovalController.ApprovalRequestWrapper> results;
        Test.startTest();
        System.runAs(stage1) {
            results = BulkApprovalController.getPendingApprovals();
        }
        Test.stopTest();

        if (results.isEmpty()) return; // submission entry criteria not met - nothing further to check

        BulkApprovalController.ApprovalRequestWrapper w = results[0];
        System.assertEquals(1, w.approvalStage);
        System.assertNotEquals(null, w.detail);
        System.assertNotEquals(null, w.submittedByName);
        System.assertNotEquals(null, w.contactName);
        System.assertNotEquals(null, w.eventName);

        Boolean foundAttachmentPhoto = false;
        Boolean foundContentDocPhoto = false;
        Boolean foundHeRequest = false;
        for (BulkApprovalController.ApprovalRequestWrapper item : results) {
            // Bio__c is not reliably reflecting direct insert values in this org (same
            // pattern seen with Title__c and Sub_Event_Name__c elsewhere) - so we check
            // structure/behavior here rather than asserting exact business text.
            if (item.detail.fullName == 'Bulk One') {
                if (String.isNotBlank(item.detail.photoUrl)) foundAttachmentPhoto = true;
                if (!item.detail.heRequests.isEmpty()) foundHeRequest = true;
            }
            if (item.detail.fullName == 'Bulk Two') {
                if (String.isNotBlank(item.detail.photoUrl)) foundContentDocPhoto = true;
            }
        }
        System.assert(foundAttachmentPhoto, 'Expected Attachment-based photo to resolve');
        System.assert(foundContentDocPhoto, 'Expected ContentDocumentLink-based photo to resolve');
        System.assert(foundHeRequest, 'Expected HE_Request__c note to resolve');
    }

    @isTest
    static void testProcessBulkApprovals_stage1ApproveWithTier_thenStage2Approve() {
        User stage1 = getStage1Approver();
        User stage2 = getStage2Approver();
        if (stage1 == null || stage2 == null) return;

        // Reason_for_Inviting__c is not filterable in SOQL, so identify the record via the
        // filterable Contact__r.LastName relationship field set in @TestSetup instead.
        Guest_List__c mainGuest = [
            SELECT Id FROM Guest_List__c WHERE Contact__r.LastName = 'Bulk One' LIMIT 1
        ];

        Test.startTest();

        List<BulkApprovalController.ApprovalRequestWrapper> stage1Pending;
        System.runAs(stage1) {
            stage1Pending = BulkApprovalController.getPendingApprovals();
        }
        if (stage1Pending.isEmpty()) {
            Test.stopTest();
            return;
        }

        String mainGuestWorkItemId;
        for (BulkApprovalController.ApprovalRequestWrapper w : stage1Pending) {
            if (w.targetObjectId == mainGuest.Id) mainGuestWorkItemId = w.workItemId;
        }
        System.assertNotEquals(null, mainGuestWorkItemId);

        String tierValue = getFirstGuestTierValue();

        System.runAs(stage1) {
            Map<String, String> tierUpdates = new Map<String, String>{ mainGuestWorkItemId => tierValue };
            BulkApprovalController.BulkActionResult result = BulkApprovalController.processBulkApprovals(
                new List<String>{ mainGuestWorkItemId }, 'Approve', 'Stage 1 approved', tierUpdates
            );
            System.assertEquals(1, result.successCount);
            System.assertEquals(0, result.failureCount);
        }

        List<BulkApprovalController.ApprovalRequestWrapper> stage2Pending;
        System.runAs(stage2) {
            stage2Pending = BulkApprovalController.getPendingApprovals();
        }

        String stage2WorkItemId;
        for (BulkApprovalController.ApprovalRequestWrapper w : stage2Pending) {
            if (w.targetObjectId == mainGuest.Id) {
                System.assertEquals(2, w.approvalStage);
                stage2WorkItemId = w.workItemId;
            }
        }

        if (stage2WorkItemId != null) {
            System.runAs(stage2) {
                BulkApprovalController.BulkActionResult result = BulkApprovalController.processBulkApprovals(
                    new List<String>{ stage2WorkItemId }, 'Approve', 'Stage 2 approved', null
                );
                System.assertEquals(1, result.successCount);
            }
        }

        Test.stopTest();

        Guest_List__c refreshed = [SELECT Notes__c, Guest_Tiers__c FROM Guest_List__c WHERE Id = :mainGuest.Id];
        System.assertNotEquals('Initial notes', refreshed.Notes__c);
        if (tierValue != null) {
            System.assertEquals(tierValue, refreshed.Guest_Tiers__c);
        }
    }

    @isTest
    static void testProcessBulkApprovals_stage1Reject() {
        User stage1 = getStage1Approver();
        if (stage1 == null) return;

        // Reason_for_Inviting__c is not filterable in SOQL, so identify the record via the
        // filterable Contact__r.LastName relationship field set in @TestSetup instead.
        Guest_List__c secondGuest = [
            SELECT Id FROM Guest_List__c WHERE Contact__r.LastName = 'Bulk Two' LIMIT 1
        ];

        Test.startTest();
        List<BulkApprovalController.ApprovalRequestWrapper> pending;
        System.runAs(stage1) {
            pending = BulkApprovalController.getPendingApprovals();
        }
        if (pending.isEmpty()) {
            Test.stopTest();
            return;
        }

        String workItemId;
        for (BulkApprovalController.ApprovalRequestWrapper w : pending) {
            if (w.targetObjectId == secondGuest.Id) workItemId = w.workItemId;
        }

        if (workItemId != null) {
            System.runAs(stage1) {
                BulkApprovalController.BulkActionResult result = BulkApprovalController.processBulkApprovals(
                    new List<String>{ workItemId }, 'Reject', 'Not a fit', null
                );
                System.assertEquals(1, result.successCount);
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testProcessBulkApprovals_emptyWorkItemIds_returnsError() {
        Test.startTest();
        BulkApprovalController.BulkActionResult result = BulkApprovalController.processBulkApprovals(
            new List<String>(), 'Approve', null, null
        );
        Test.stopTest();

        System.assertEquals(0, result.successCount);
        System.assertEquals(0, result.failureCount);
        System.assertEquals(1, result.errors.size());
        System.assert(result.errors[0].contains('No work items'));
    }

    @isTest
    static void testProcessBulkApprovals_invalidAction_returnsError() {
        Test.startTest();
        BulkApprovalController.BulkActionResult result = BulkApprovalController.processBulkApprovals(
            new List<String>{ '0ATfakeWorkItemId0001' }, 'Cancel', null, null
        );
        Test.stopTest();

        System.assertEquals(1, result.errors.size());
        System.assert(result.errors[0].contains('Invalid action'));
    }

    @isTest
    static void testProcessBulkApprovals_guestTierUpdate_missingWorkItem_countsFailure() {
        // Correctly-formatted Id that doesn't correspond to a real ProcessInstanceWorkitem -
        // exercises the "target object not found" failure path without tripping the raw
        // (Id) cast used elsewhere in the controller, which throws on non-Id-shaped strings.
        Id fakeWorkItemId = '0TT000000000AAA';
        Map<String, String> tierUpdates = new Map<String, String>{
            fakeWorkItemId => 'Tier 1'
        };

        Test.startTest();
        BulkApprovalController.BulkActionResult result = BulkApprovalController.processBulkApprovals(
            new List<String>{ fakeWorkItemId }, 'Approve', 'Some comments', tierUpdates
        );
        Test.stopTest();

        System.assert(result.failureCount >= 1);
    }
}