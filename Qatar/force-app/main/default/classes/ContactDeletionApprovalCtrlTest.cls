@isTest
private class ContactDeletionApprovalCtrlTest {

    // ---------------------------------------------------------------
    // APPROACH:
    // Rather than forcing a specific approver via setNextApproverIds()
    // (which only works if the step is configured as "let submitter pick"),
    // this test submits the record and then QUERIES who the approval
    // process actually assigned as the approver, then runs the controller
    // calls as that user via System.runAs(). This works regardless of
    // whether your steps use a named user, manager hierarchy, or role.
    //
    // NOTE: if the approver resolves to a Queue/Public Group rather than
    // an individual User, getAssignedApprover() below will throw
    // "List has no rows for assignment to SObject" - if you hit that,
    // let me know and I'll adjust to handle queue-based assignment.
    // ---------------------------------------------------------------

    @TestSetup
    static void setup() {
        Contact con = new Contact(
            LastName              = 'Test Contact',
            Title                 = 'Manager',
            Email                 = 'test.contact@example.com',
            Deletion_Reason__c    = 'No longer with company',
            Deletion_Requested__c = true
        );
        insert con;

        Attachment att = new Attachment(
            ParentId    = con.Id,
            Name        = 'photo.jpg',
            Body        = Blob.valueOf('Fake Image Body Content'),
            ContentType = 'image/jpeg'
        );
        insert att;
    }

    private static Contact getTestContact() {
        return [SELECT Id FROM Contact WHERE LastName = 'Test Contact' LIMIT 1];
    }

    // Submits the contact into the "Contact_Deletion_Approval_2" approval process.
    // setSkipEntryCriteria(true) bypasses entry-criteria evaluation so the test
    // doesn't depend on exactly replicating whatever criteria the process checks -
    // this is what avoids the NO_APPLICABLE_PROCESS error.
    private static void submitForApproval(Id contactId) {
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(contactId);
        req.setProcessDefinitionNameOrId('Contact_Deletion_Approval_2');
        req.setSkipEntryCriteria(true);
        req.setSubmitterId(UserInfo.getUserId());
        Approval.process(req);
    }

    // Finds whichever user the approval process actually assigned as the
    // current pending approver for this contact.
    private static User getAssignedApprover(Id contactId) {
        ProcessInstanceWorkitem wi = [
            SELECT ActorId
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :contactId
            AND ProcessInstance.Status = 'Pending'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return [SELECT Id FROM User WHERE Id = :wi.ActorId LIMIT 1];
    }

    @isTest
    static void testGetPendingApprovals_NoSubmission_ReturnsEmpty() {
        Test.startTest();
        List<ContactDeletionApprovalCtrl.ContactApprovalWrapper> results =
            ContactDeletionApprovalCtrl.getPendingApprovals();
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should be no pending approvals before submission');
    }

    @isTest
    static void testGetPendingApprovals_Stage1_ReturnsCorrectData() {
        Contact con = getTestContact();
        submitForApproval(con.Id);
        User approver = getAssignedApprover(con.Id);

        List<ContactDeletionApprovalCtrl.ContactApprovalWrapper> results;
        System.runAs(approver) {
            Test.startTest();
            results = ContactDeletionApprovalCtrl.getPendingApprovals();
            Test.stopTest();
        }

        System.assertEquals(1, results.size(), 'Expected exactly one pending approval');

        ContactDeletionApprovalCtrl.ContactApprovalWrapper w = results[0];
        System.assertEquals(con.Id, w.contactId, 'Contact Id should match');
        System.assertEquals('Test Contact', w.contactName);
        System.assertEquals('Manager', w.jobTitle);
        System.assertEquals('No longer with company', w.deletionReason);
        System.assertEquals(1, w.stageNumber, 'Should be stage 1 since no steps are approved yet');
        System.assert(w.photoUrl != null && w.photoUrl.startsWith('data:image/jpeg;base64,'),
            'Photo URL should be built from the attachment');
    }

    @isTest
    static void testProcessApproval_Stage1_Approve_UpdatesStatusesAndComment() {
        Contact con = getTestContact();
        submitForApproval(con.Id);
        User approver = getAssignedApprover(con.Id);

        System.runAs(approver) {
            List<ContactDeletionApprovalCtrl.ContactApprovalWrapper> pending =
                ContactDeletionApprovalCtrl.getPendingApprovals();
            Id workItemId = pending[0].workItemId;

            Test.startTest();
            ContactDeletionApprovalCtrl.processApproval(
                workItemId, 'Approve', 'Looks good, approving stage 1', con.Id, 1
            );
            Test.stopTest();
        }

        Contact updated = [
            SELECT Deletion_Status__c, Deletion_Status_1__c, Approver_Comments__c
            FROM Contact WHERE Id = :con.Id
        ];
        System.assertEquals('Approved', updated.Deletion_Status__c, 'Stage 1 status should be Approved');
        System.assertEquals('Pending Approval', updated.Deletion_Status_1__c, 'Stage 2 should now be Pending Approval');
        System.assertEquals('Looks good, approving stage 1', updated.Approver_Comments__c);
    }

    @isTest
    static void testProcessApproval_Stage1_Reject_UpdatesStatuses() {
        Contact con = getTestContact();
        submitForApproval(con.Id);
        User approver = getAssignedApprover(con.Id);

        System.runAs(approver) {
            List<ContactDeletionApprovalCtrl.ContactApprovalWrapper> pending =
                ContactDeletionApprovalCtrl.getPendingApprovals();
            Id workItemId = pending[0].workItemId;

            Test.startTest();
            ContactDeletionApprovalCtrl.processApproval(
                workItemId, 'Reject', 'Not approved at stage 1', con.Id, 1
            );
            Test.stopTest();
        }

        Contact updated = [
            SELECT Deletion_Status__c, Deletion_Status_1__c
            FROM Contact WHERE Id = :con.Id
        ];
        System.assertEquals('Rejected', updated.Deletion_Status__c);
        System.assertEquals('Pending Approval', updated.Deletion_Status_1__c);
    }

    @isTest
    static void testProcessApproval_Stage2_Approve_CompletesFlow() {
        Contact con = getTestContact();
        submitForApproval(con.Id);

        // --- Stage 1: approve so the process advances to stage 2 ---
        User stage1Approver = getAssignedApprover(con.Id);
        System.runAs(stage1Approver) {
            List<ContactDeletionApprovalCtrl.ContactApprovalWrapper> stage1Pending =
                ContactDeletionApprovalCtrl.getPendingApprovals();
            System.assertEquals(1, stage1Pending.size(), 'Expected stage 1 approval to be pending');
            ContactDeletionApprovalCtrl.processApproval(
                stage1Pending[0].workItemId, 'Approve', 'Stage 1 approved', con.Id, 1
            );
        }

        // --- Stage 2: whoever it was assigned to now approves ---
        User stage2Approver = getAssignedApprover(con.Id);
        System.runAs(stage2Approver) {
            List<ContactDeletionApprovalCtrl.ContactApprovalWrapper> stage2Pending =
                ContactDeletionApprovalCtrl.getPendingApprovals();
            System.assertEquals(1, stage2Pending.size(), 'Expected stage 2 approval to be pending');
            System.assertEquals(2, stage2Pending[0].stageNumber);
            System.assertEquals('Stage 1 approved', stage2Pending[0].approverComments,
                'Stage 2 approver should see stage 1 comment');

            Test.startTest();
            ContactDeletionApprovalCtrl.processApproval(
                stage2Pending[0].workItemId, 'Approve', 'Stage 2 approved', con.Id, 2
            );
            Test.stopTest();
        }

        Contact updated = [
            SELECT Deletion_Status_1__c, Approver_Comments_2__c
            FROM Contact WHERE Id = :con.Id
        ];
        System.assertEquals('Approved', updated.Deletion_Status_1__c);
        System.assertEquals('Stage 2 approved', updated.Approver_Comments_2__c);
    }

    @isTest
    static void testProcessApproval_Stage2_Reject_UpdatesStatus() {
        Contact con = getTestContact();
        submitForApproval(con.Id);

        User stage1Approver = getAssignedApprover(con.Id);
        System.runAs(stage1Approver) {
            List<ContactDeletionApprovalCtrl.ContactApprovalWrapper> stage1Pending =
                ContactDeletionApprovalCtrl.getPendingApprovals();
            ContactDeletionApprovalCtrl.processApproval(
                stage1Pending[0].workItemId, 'Approve', 'Stage 1 ok', con.Id, 1
            );
        }

        User stage2Approver = getAssignedApprover(con.Id);
        System.runAs(stage2Approver) {
            List<ContactDeletionApprovalCtrl.ContactApprovalWrapper> stage2Pending =
                ContactDeletionApprovalCtrl.getPendingApprovals();

            Test.startTest();
            ContactDeletionApprovalCtrl.processApproval(
                stage2Pending[0].workItemId, 'Reject', 'Denied at stage 2', con.Id, 2
            );
            Test.stopTest();
        }

        Contact updated = [
            SELECT Deletion_Status_1__c, Approver_Comments_2__c
            FROM Contact WHERE Id = :con.Id
        ];
        System.assertEquals('Rejected', updated.Deletion_Status_1__c);
        System.assertEquals('Denied at stage 2', updated.Approver_Comments_2__c);
    }

    @isTest
    static void testProcessApproval_InvalidAction_ThrowsException() {
        Contact con = getTestContact();
        submitForApproval(con.Id);
        User approver = getAssignedApprover(con.Id);

        Boolean exceptionThrown = false;

        System.runAs(approver) {
            List<ContactDeletionApprovalCtrl.ContactApprovalWrapper> pending =
                ContactDeletionApprovalCtrl.getPendingApprovals();
            Id workItemId = pending[0].workItemId;

            Test.startTest();
            try {
                ContactDeletionApprovalCtrl.processApproval(workItemId, 'Cancel', 'bad action', con.Id, 1);
            } catch (AuraHandledException e) {
                exceptionThrown = true;
            }
            Test.stopTest();
        }

        System.assert(exceptionThrown, 'Expected AuraHandledException for an invalid action value');
    }

    @isTest
    static void testProcessApproval_NoContactId_StillProcessesWorkitem() {
        // Covers the branch where contactId is null: Contact update is skipped
        // but the approval work item is still processed.
        Contact con = getTestContact();
        submitForApproval(con.Id);
        User approver = getAssignedApprover(con.Id);

        System.runAs(approver) {
            List<ContactDeletionApprovalCtrl.ContactApprovalWrapper> pending =
                ContactDeletionApprovalCtrl.getPendingApprovals();
            Id workItemId = pending[0].workItemId;

            Test.startTest();
            ContactDeletionApprovalCtrl.processApproval(workItemId, 'Approve', 'no contact id passed', null, 1);
            Test.stopTest();
        }

        // Deletion_Status__c should remain unchanged since contactId was null
        Contact updated = [SELECT Deletion_Status__c FROM Contact WHERE Id = :con.Id];
        System.assertEquals(null, updated.Deletion_Status__c);
    }
}