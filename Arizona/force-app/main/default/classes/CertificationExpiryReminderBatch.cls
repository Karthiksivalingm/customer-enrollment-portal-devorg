/**
 * CertificationExpiryReminderBatch
 *
 * Runs daily. Checks each Contact's certification expiration dates.
 * If any expire in exactly 2 days OR exactly 1 month from today,
 * sends a branded reminder email (Arizona Lionhearts template) with
 * the shared Calendly scheduling link.
 *
 * IMPORTANT: update CERT_FIELDS below to match your actual
 * Contact field API names for each certification's expiration date.
 */
public with sharing class CertificationExpiryReminderBatch implements Database.Batchable<SObject>, Schedulable {

    // Certification display name -> Contact expiration date field API name.
    // UPDATE THESE to match your org's real field API names.
    private static final Map<String, String> CERT_FIELDS = new Map<String, String>{
        'Article 9 Certification'      => 'Article_9_Expiration_Date__c',
        'CPR Certification Card'       => 'CPR_Expiration_Date__c',
        'First Aid Certification Card' => 'FA_Expiration_Date__c'
    };

    private static final String CALENDLY_URL =
        'https://calendly.com/d/dtjk-qdh-tns/appointment-calendar?month=2026-07';

    private static final String LOGO_URL =
        'https://storage.pardot.com/1126833/1781259488F0jGv9HY/Arizona_logo.png';

    private static final String BANNER_URL =
        'http://go.pardot.com/l/1126833/2026-06-12/kqk1g6/1126833/17812598421kNacc7m/Arizona_image__2';

    private static final String WEBSITE_URL = 'https://azlionhearts.com/';

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Name, Email, FirstName, ' +
            String.join(new List<String>(CERT_FIELDS.values()), ', ') +
            ' FROM Contact WHERE Email != null';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Contact> contacts) {
        Date today = Date.today();
        Date twoDaysOut  = today.addDays(2);
        Date oneMonthOut = today.addMonths(1);

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Contact con : contacts) {
            List<String> expiringSoon = new List<String>();

            for (String certName : CERT_FIELDS.keySet()) {
                Object rawVal = con.get(CERT_FIELDS.get(certName));
                if (rawVal == null) {
                    continue;
                }
                Date expDate = (Date) rawVal;

                if (expDate == twoDaysOut) {
                    expiringSoon.add(certName + ' — expires in 2 days (' + expDate.format() + ')');
                } else if (expDate == oneMonthOut) {
                    expiringSoon.add(certName + ' — expires in 1 month (' + expDate.format() + ')');
                }
            }

            if (!expiringSoon.isEmpty()) {
                emails.add(buildEmail(con, expiringSoon));
            }
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails, false);
        }
    }

    private Messaging.SingleEmailMessage buildEmail(Contact con, List<String> expiringSoon) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{ con.Email });
        mail.setSubject('Action Required: Certification Renewal Reminder');

        String firstName = String.isNotBlank(con.FirstName) ? con.FirstName : 'there';

        // Build the certification list as HTML <li> items
        String certListHtml = '';
        for (String c : expiringSoon) {
            certListHtml += '<li>' + escapeHtml(c) + '</li>';
        }

        String body =
            '<!DOCTYPE html>' +
            '<html>' +
            '<head>' +
            '<meta charset="UTF-8">' +
            '<title>Certification Renewal Reminder</title>' +
            '</head>' +
            '<body style="margin:0;padding:0;background-color:#f4f6f9;font-family:Arial,sans-serif;">' +
            '<table bgcolor="#f4f6f9" border="0" cellpadding="0" cellspacing="0" width="100%">' +
            '<tbody>' +
            '<tr>' +
            '<td align="center" style="padding:20px;">' +
            '<table border="0" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:8px;" width="600">' +
            '<tbody>' +

            // HEADER
            '<tr>' +
            '<td align="center" style="background-color:#21194f;padding:20px;">' +
            '<img alt="Arizona Lionhearts Logo" src="' + LOGO_URL + '" style="display:block;width:100%;max-width:480px;height:auto;border:0;" width="480">' +
            '</td>' +
            '</tr>' +

            // BODY
            '<tr>' +
            '<td style="padding:25px;color:#333333;font-size:15px;line-height:1.6;">' +
            '<h2 style="margin-top:0;">Hi ' + escapeHtml(firstName) + '</h2>' +
            '<p>This is a friendly reminder from <strong>Arizona Lionhearts</strong> about your certification status.</p>' +
            '<p>The following certification(s) on file for you are expiring soon:</p>' +
            '<table border="0" cellpadding="15" cellspacing="0" style="background:#f9fafc;" width="100%">' +
            '<tbody>' +
            '<tr>' +
            '<td>' +
            '<strong>Certifications expiring soon:</strong>' +
            '<ul style="padding-left:20px;margin:10px 0;">' +
            certListHtml +
            '</ul>' +
            '</td>' +
            '</tr>' +
            '</tbody>' +
            '</table>' +
            '<p style="font-weight:bold;color:#222;">Please schedule your renewal appointment as soon as possible to avoid a lapse.</p>' +
            '<table align="center" border="0" cellpadding="0" cellspacing="0">' +
            '<tbody>' +
            '<tr>' +
            '<td bgcolor="#ff6b00" style="padding:12px 24px;border-radius:5px;">' +
            '<a href="' + CALENDLY_URL + '" style="color:#ffffff;text-decoration:none;font-weight:bold;">Schedule Your Appointment</a>' +
            '</td>' +
            '</tr>' +
            '</tbody>' +
            '</table>' +
            '<p>If you have any questions, feel free to reach out — we\'re always happy to help!</p>' +
            '<p>Warm regards,<br><strong>Arizona Lionhearts Team</strong></p>' +
            '</td>' +
            '</tr>' +

            // BANNER IMAGE
            '<tr>' +
            '<td align="center" style="padding:0 20px 20px 20px;">' +
            '<img alt="Arizona Lionhearts" src="' + BANNER_URL + '" style="display:block;width:100%;max-width:560px;height:auto;border:0;" width="560">' +
            '</td>' +
            '</tr>' +

            // FOOTER
            '<tr>' +
            '<td align="center" style="background:#f1f1f1;padding:15px;font-size:12px;color:#555;">' +
            '<p style="margin:5px 0;">Contact Us - Call at <strong>480-253-9360</strong> or Text at <strong>480-253-9377</strong></p>' +
            '<p style="margin:5px 0;color:#888;">© 2025 Arizona Lionhearts. All rights reserved.</p>' +
            '<p style="margin:5px 0;color:#888;">This is an automated message. Please do not reply.</p>' +
            '</td>' +
            '</tr>' +

            '</tbody>' +
            '</table>' +
            '</td>' +
            '</tr>' +
            '</tbody>' +
            '</table>' +
            '</body>' +
            '</html>';

        mail.setHtmlBody(body);
        mail.setPlainTextBody(
            'Hi ' + firstName + ',\n\n' +
            'This is a reminder from Arizona Lionhearts. The following certification(s) on file for you are expiring soon:\n' +
            String.join(expiringSoon, '\n') +
            '\n\nSchedule your renewal appointment here: ' + CALENDLY_URL +
            '\n\nContact us: 480-253-9360 (call) or 480-253-9377 (text)\n\n' +
            'Thank you.'
        );

        return mail;
    }

    // Basic HTML escaping to keep dynamically-inserted Contact data safe in the email body
    private String escapeHtml(String input) {
        if (input == null) {
            return '';
        }
        return input
            .replace('&', '&amp;')
            .replace('<', '&lt;')
            .replace('>', '&gt;')
            .replace('"', '&quot;')
            .replace('\'', '&#39;');
    }

    public void finish(Database.BatchableContext bc) {}

    // Schedulable interface — lets this batch be scheduled to run daily
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CertificationExpiryReminderBatch(), 200);
    }
}