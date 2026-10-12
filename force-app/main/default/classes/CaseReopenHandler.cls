/**
 * Reopens Resolved/Closed Cases when a customer replies by email and
 * notifies the case owner (User or Queue) with a link to the Case.
 *
 * "without sharing" is deliberate: Email-to-Case runs as the Automated
 * Process user, which may not have sharing access to every Case.
 */
public without sharing class CaseReopenHandler {

    // ---------------- Configuration ----------------

    private static final Set<String> REOPENABLE_STATUSES = new Set<String>{
        'Closed',
        'Resolved'
    };

    private static final String REOPENED_STATUS = 'Reopened';

    // Used when a Queue owner has no Email set in Setup. Leave blank to skip.
    private static final String FALLBACK_ADDRESS = 'retailsupportuat@goodr.com';

    // How much of the customer's reply to quote in the notification
    private static final Integer SNIPPET_LENGTH = 400;


    // ---------------- Entry point ----------------

    public static void reopenClosedCases(List<EmailMessage> newEmails) {

        if (newEmails == null || newEmails.isEmpty()) return;

        // Case Id -> the incoming email that touched it (last one wins)
        Map<Id, EmailMessage> incomingByCaseId = new Map<Id, EmailMessage>();

        for (EmailMessage em : newEmails) {

            if (em.ParentId != null
                && em.ParentId.getSObjectType() == Case.SObjectType
                && em.Incoming == true) {

                incomingByCaseId.put(em.ParentId, em);
            }
        }

        if (incomingByCaseId.isEmpty()) return;

        List<Case> casesToUpdate = new List<Case>();

        for (Case c : [
            SELECT Id, CaseNumber, Subject, Status, Priority,
                   OwnerId, Owner.Name,
                   Contact.Name, Account.Name
            FROM Case
            WHERE Id IN :incomingByCaseId.keySet()
            AND Status IN :REOPENABLE_STATUSES
        ]) {
            c.Status = REOPENED_STATUS;
            casesToUpdate.add(c);
        }

        if (casesToUpdate.isEmpty()) return;

        update casesToUpdate;

        notifyOwners(casesToUpdate, incomingByCaseId);
    }


    // ---------------- Notification ----------------

    private static void notifyOwners(List<Case> reopenedCases,
                                     Map<Id, EmailMessage> incomingByCaseId) {

        String baseUrl = URL.getOrgDomainUrl().toExternalForm();

        // Resolve mailbox addresses for any queue owners
        Set<Id> queueIds = new Set<Id>();
        for (Case c : reopenedCases) {
            if (String.valueOf(c.OwnerId).startsWith('00G')) {
                queueIds.add(c.OwnerId);
            }
        }

        Map<Id, Group> queuesById = queueIds.isEmpty()
            ? new Map<Id, Group>()
            : new Map<Id, Group>([
                SELECT Id, Name, Email
                FROM Group
                WHERE Id IN :queueIds AND Type = 'Queue'
              ]);

        List<Messaging.SingleEmailMessage> emails =
            new List<Messaging.SingleEmailMessage>();

        for (Case c : reopenedCases) {

            EmailMessage reply = incomingByCaseId.get(c.Id);

            // ----- Owner is a User -----
            if (String.valueOf(c.OwnerId).startsWith('005')) {

                String ownerName = String.isBlank(c.Owner.Name) ? 'Team' : c.Owner.Name;

                emails.add(buildMessage(
                    c, reply, baseUrl, c.OwnerId, null, ownerName
                ));
                continue;
            }

            // ----- Owner is a Queue -----
            Group q = queuesById.get(c.OwnerId);

            String queueName = (q != null && String.isNotBlank(q.Name))
                             ? q.Name
                             : (String.isBlank(c.Owner.Name) ? 'Support Team' : c.Owner.Name);

            String addr = (q != null && String.isNotBlank(q.Email))
                        ? q.Email
                        : FALLBACK_ADDRESS;

            if (String.isBlank(addr)) {
                System.debug(LoggingLevel.WARN,
                    'Case reopen: no mailbox resolved for queue owner on case '
                    + c.CaseNumber + '. No notification sent.');
                continue;
            }

            emails.add(buildMessage(
                c, reply, baseUrl, null, new List<String>{ addr }, queueName
            ));
        }

        if (emails.isEmpty()) return;

        try {
            // allOrNone = false so one bad address cannot roll back the status update
            Messaging.sendEmail(emails, false);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Case reopen notification failed: ' + e.getMessage());
        }
    }


    // ---------------- Email construction ----------------

    private static Messaging.SingleEmailMessage buildMessage(
            Case c,
            EmailMessage reply,
            String baseUrl,
            Id targetUserId,
            List<String> toAddresses,
            String greetingName) {

        String caseUrl  = baseUrl + '/lightning/r/Case/' + c.Id + '/view';
        String subject  = String.isBlank(c.Subject)  ? 'No subject' : c.Subject;
        String priority = String.isBlank(c.Priority) ? 'Not set'    : c.Priority;

        String contactName = (c.Contact != null && String.isNotBlank(c.Contact.Name))
                           ? c.Contact.Name : 'the customer';
        String accountName = (c.Account != null && String.isNotBlank(c.Account.Name))
                           ? c.Account.Name : 'Not specified';
        String fromAddress = (reply != null && String.isNotBlank(reply.FromAddress))
                           ? reply.FromAddress : 'Not available';
        String receivedOn  = (reply != null && reply.MessageDate != null)
                           ? reply.MessageDate.format('dd MMM yyyy, HH:mm')
                           : System.now().format('dd MMM yyyy, HH:mm');

        String snippet = '';
        if (reply != null && String.isNotBlank(reply.TextBody)) {
            snippet = reply.TextBody.length() > SNIPPET_LENGTH
                    ? reply.TextBody.substring(0, SNIPPET_LENGTH) + '...'
                    : reply.TextBody;
        }

        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();

        if (targetUserId != null) {
            // Targeting a User does not consume the daily single-email allocation
            msg.setTargetObjectId(targetUserId);
            msg.setSaveAsActivity(false);
        } else {
            msg.setToAddresses(toAddresses);
        }

        msg.setSubject('Case ' + c.CaseNumber + ' reopened - customer reply received');

        // ---------------- Plain text ----------------
        msg.setPlainTextBody(
            'Dear ' + greetingName + ',\n\n' +
            'Case ' + c.CaseNumber + ' has been reopened because ' + contactName +
            ' replied to it. The case previously held a Resolved or Closed status ' +
            'and now requires your review.\n\n' +
            'CASE DETAILS\n' +
            'Case Number : ' + c.CaseNumber + '\n' +
            'Subject     : ' + subject + '\n' +
            'Account     : ' + accountName + '\n' +
            'Contact     : ' + contactName + '\n' +
            'Priority    : ' + priority + '\n' +
            'Status      : ' + REOPENED_STATUS + '\n\n' +
            'CUSTOMER REPLY\n' +
            'From     : ' + fromAddress + '\n' +
            'Received : ' + receivedOn + '\n\n' +
            (String.isBlank(snippet) ? '' : snippet + '\n\n') +
            'Review and respond to the case here:\n' + caseUrl + '\n\n' +
            'Please do not forward this notification, as the association with the ' +
            'original case may be lost.\n\n' +
            'Kind regards,\n' +
            'Customer Support Automation'
        );

        // ---------------- HTML ----------------
        msg.setHtmlBody(
            '<div style="font-family:Arial,Helvetica,sans-serif;font-size:14px;' +
                 'line-height:1.6;color:#2b2b2b;max-width:620px;">' +

              '<p style="margin:0 0 16px;">Dear ' + esc(greetingName) + ',</p>' +

              '<p style="margin:0 0 20px;">Case <strong>' + esc(c.CaseNumber) +
                '</strong> has been reopened because ' + esc(contactName) +
                ' replied to it. The case previously held a Resolved or Closed ' +
                'status and now requires your review.</p>' +

              '<table cellpadding="0" cellspacing="0" border="0" ' +
                     'style="border-collapse:collapse;margin:0 0 24px;width:100%;">' +
                sectionHeader('Case details') +
                row('Case Number', c.CaseNumber) +
                row('Subject',     subject) +
                row('Account',     accountName) +
                row('Contact',     contactName) +
                row('Priority',    priority) +
                row('Status',      REOPENED_STATUS) +
              '</table>' +

              '<table cellpadding="0" cellspacing="0" border="0" ' +
                     'style="border-collapse:collapse;margin:0 0 24px;width:100%;">' +
                sectionHeader('Customer reply') +
                row('From',     fromAddress) +
                row('Received', receivedOn) +
              '</table>' +

              (String.isBlank(snippet) ? '' :
                '<div style="border-left:3px solid #d0d0d0;padding:2px 0 2px 14px;' +
                     'margin:0 0 24px;color:#4a4a4a;white-space:pre-wrap;">' +
                  esc(snippet) +
                '</div>') +

              '<p style="margin:0 0 28px;">' +
                '<a href="' + caseUrl + '" ' +
                   'style="background:#0176d3;color:#ffffff;text-decoration:none;' +
                          'padding:11px 22px;border-radius:4px;display:inline-block;' +
                          'font-weight:bold;">View Case ' + esc(c.CaseNumber) + '</a>' +
              '</p>' +

              '<p style="margin:0 0 20px;font-size:13px;color:#6b6b6b;">' +
                'If the button does not open, copy this link into your browser:<br/>' +
                '<span style="word-break:break-all;">' + caseUrl + '</span>' +
              '</p>' +

              '<p style="margin:0 0 20px;font-size:13px;color:#8a6d3b;' +
                        'background:#fcf8e3;border:1px solid #faebcc;' +
                        'padding:10px 14px;border-radius:4px;">' +
                'Please do not forward this notification, as the association with ' +
                'the original case may be lost.' +
              '</p>' +

              '<p style="margin:0 0 4px;">Kind regards,</p>' +
              '<p style="margin:0;color:#6b6b6b;">Customer Support Automation</p>' +

            '</div>'
        );

        return msg;
    }


    private static String sectionHeader(String label) {
        return '<tr><td colspan="2" style="padding:0 0 8px;font-size:12px;' +
               'letter-spacing:.06em;text-transform:uppercase;color:#6b6b6b;' +
               'border-bottom:1px solid #e0e0e0;">' + esc(label) + '</td></tr>';
    }


    private static String row(String label, String value) {
        return '<tr>' +
                 '<td style="padding:7px 18px 7px 0;color:#6b6b6b;white-space:nowrap;' +
                     'vertical-align:top;width:120px;">' + esc(label) + '</td>' +
                 '<td style="padding:7px 0;vertical-align:top;">' +
                   (String.isBlank(value) ? '&mdash;' : esc(value)) + '</td>' +
               '</tr>';
    }


    private static String esc(String input) {
        return String.isBlank(input) ? '' : input.escapeHtml4();
    }
}