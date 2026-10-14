@IsTest
public class CaseReopenHandlerTest {

    // ---------------- Helpers ----------------

    private static Case newCase(String subject, String status, Id ownerId) {
        Case c = new Case(Subject = subject, Status = status, Origin = 'Email');
        if (ownerId != null) c.OwnerId = ownerId;
        return c;
    }

    private static EmailMessage newEmail(Id caseId, Boolean incoming) {
        return new EmailMessage(
            ParentId    = caseId,
            Incoming    = incoming,
            FromAddress = incoming ? 'testcustomer@example.com' : 'support@example.com',
            ToAddress   = incoming ? 'support@example.com' : 'testcustomer@example.com',
            Subject     = incoming ? 'Customer Reply' : 'Support Response',
            TextBody    = 'Message body for the reopen test.',
            Status      = '3',
            MessageDate = System.now()
        );
    }

    private static Group createCaseQueue(String name, String devName, String email) {
        Group q = new Group(Name = name, DeveloperName = devName, Type = 'Queue');
        if (String.isNotBlank(email)) q.Email = email;

        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert q;
            insert new QueueSobject(QueueId = q.Id, SObjectType = 'Case');
        }
        return q;
    }

    private static String statusOf(Id caseId) {
        return [SELECT Status FROM Case WHERE Id = :caseId].Status;
    }


    // ---------------- Status handling ----------------

    @IsTest
    static void testClosedCaseReopenedOnIncomingEmail() {

        Case c = newCase('Test Closed Case', 'Closed', UserInfo.getUserId());
        insert c;

        Test.startTest();
        insert newEmail(c.Id, true);
        Test.stopTest();

        System.assertEquals('Reopened', statusOf(c.Id),
            'Closed Case should be reopened when an incoming email is received.');
    }


    @IsTest
    static void testResolvedCaseReopenedOnIncomingEmail() {

        Case c = newCase('Test Resolved Case', 'Resolved', UserInfo.getUserId());
        insert c;

        Test.startTest();
        insert newEmail(c.Id, true);
        Test.stopTest();

        System.assertEquals('Reopened', statusOf(c.Id),
            'Resolved Case should be reopened when an incoming email is received.');
    }


    @IsTest
    static void testOutgoingEmailDoesNotReopenClosedCase() {

        Case c = newCase('Closed Case - Outgoing', 'Closed', UserInfo.getUserId());
        insert c;

        Test.startTest();
        insert newEmail(c.Id, false);
        Test.stopTest();

        System.assertEquals('Closed', statusOf(c.Id),
            'Case should remain Closed for an outgoing email.');
    }


    @IsTest
    static void testOutgoingEmailDoesNotReopenResolvedCase() {

        Case c = newCase('Resolved Case - Outgoing', 'Resolved', UserInfo.getUserId());
        insert c;

        Test.startTest();
        insert newEmail(c.Id, false);
        Test.stopTest();

        System.assertEquals('Resolved', statusOf(c.Id),
            'Resolved Case should remain Resolved for an outgoing email.');
    }


    @IsTest
    static void testIncomingEmailOnOpenCaseDoesNotChangeStatus() {

        Case c = newCase('Test Open Case', 'New', UserInfo.getUserId());
        insert c;

        Test.startTest();
        insert newEmail(c.Id, true);
        Test.stopTest();

        System.assertEquals('New', statusOf(c.Id),
            'Open Case should not be changed by an incoming email.');
    }


    // ---------------- Guard clauses ----------------

    @IsTest
    static void testHandlerWithEmptyAndNullInput() {

        Test.startTest();
        CaseReopenHandler.reopenClosedCases(new List<EmailMessage>());
        CaseReopenHandler.reopenClosedCases(null);
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(0, invocations,
            'Handler should do nothing when given no EmailMessages.');
    }


    @IsTest
    static void testEmailNotLinkedToCaseIsIgnored() {

        // EmailMessage with no ParentId must not blow up the handler
        EmailMessage orphan = new EmailMessage(
            Incoming    = true,
            FromAddress = 'testcustomer@example.com',
            ToAddress   = 'support@example.com',
            Subject     = 'No parent',
            TextBody    = 'Not related to a case.',
            Status      = '3',
            MessageDate = System.now()
        );

        Test.startTest();
        insert orphan;
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(0, invocations,
            'No notification should be sent for an email with no parent Case.');
    }


    // ---------------- Notification: User owner ----------------

    @IsTest
    static void testUserOwnerIsNotified() {

        Case c = newCase('User Owned Case', 'Resolved', UserInfo.getUserId());
        insert c;

        Test.startTest();
        insert newEmail(c.Id, true);
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals('Reopened', statusOf(c.Id),
            'User owned case should be reopened.');
        System.assertEquals(1, invocations,
            'One sendEmail invocation should occur for a user owned case.');
    }


    @IsTest
    static void testNoEmailWhenNothingReopened() {

        Case c = newCase('Open Case - No Notification', 'New', UserInfo.getUserId());
        insert c;

        Test.startTest();
        insert newEmail(c.Id, true);
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(0, invocations,
            'No email should be sent when no case was reopened.');
    }


    // ---------------- Notification: Queue owner ----------------

    @IsTest
    static void testQueueOwnerWithMailboxIsNotified() {

        Group q = createCaseQueue('Reopen Q Mailbox', 'Reopen_Q_Mailbox',
                                  'queuebox@example.com');

        Case c = newCase('Queue Owned Case', 'Resolved', q.Id);
        insert c;

        Test.startTest();
        insert newEmail(c.Id, true);
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals('Reopened', statusOf(c.Id),
            'Queue owned case should be reopened.');
        System.assertEquals(1, invocations,
            'Queue mailbox should receive the notification.');
    }


    @IsTest
    static void testQueueOwnerWithoutMailboxUsesFallback() {

        // No Email on the queue - the handler falls back to FALLBACK_ADDRESS
        Group q = createCaseQueue('Reopen Q NoMail', 'Reopen_Q_NoMail', null);

        Case c = newCase('Queue No Mailbox Case', 'Closed', q.Id);
        insert c;

        Test.startTest();
        insert newEmail(c.Id, true);
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals('Reopened', statusOf(c.Id),
            'Queue owned case should still be reopened.');
        System.assertEquals(1, invocations,
            'Fallback address should receive the notification when the queue has no mailbox.');
    }


    // ---------------- Bulk ----------------

    @IsTest
    static void testBulkMixedOwnersAndStatuses() {

        Group q = createCaseQueue('Reopen Q Bulk', 'Reopen_Q_Bulk', 'bulkq@example.com');

        List<Case> cases = new List<Case>{
            newCase('Bulk Closed User',   'Closed',   UserInfo.getUserId()),
            newCase('Bulk Resolved Queue','Resolved', q.Id),
            newCase('Bulk New User',      'New',      UserInfo.getUserId())
        };
        insert cases;

        List<EmailMessage> emails = new List<EmailMessage>();
        for (Case c : cases) emails.add(newEmail(c.Id, true));

        Test.startTest();
        insert emails;
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();

        Map<Id, Case> updated = new Map<Id, Case>([
            SELECT Id, Status FROM Case WHERE Id IN :cases
        ]);

        System.assertEquals('Reopened', updated.get(cases[0].Id).Status,
            'Closed user owned case should reopen.');
        System.assertEquals('Reopened', updated.get(cases[1].Id).Status,
            'Resolved queue owned case should reopen.');
        System.assertEquals('New', updated.get(cases[2].Id).Status,
            'New case should be untouched.');
        System.assertEquals(1, invocations,
            'All notifications should go out in a single sendEmail invocation.');
    }
}