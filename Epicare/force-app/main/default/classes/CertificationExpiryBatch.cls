public class CertificationExpiryBatch
    implements Database.Batchable<SObject> {

    // ─────────────────────────────────────────────
    // START
    // ─────────────────────────────────────────────
    public Database.QueryLocator start(
        Database.BatchableContext bc
    ) {

        return Database.getQueryLocator([

            SELECT Id,
                   Name,
                   Days_Until_Expiry__c,
                   Status__c,
                   Certification_Type__c,
                   Agent__c,
                   Agent__r.Email,
                   OwnerId

            FROM Certification__c

            WHERE Days_Until_Expiry__c < 30
            AND Status__c = 'Active'
            AND Certification_Type__c NOT IN ('AHIP', 'FFM')
        ]);
    }

    // ─────────────────────────────────────────────
    // EXECUTE
    // ─────────────────────────────────────────────
    public void execute(
        Database.BatchableContext bc,
        List<Certification__c> scope
    ) {

        List<Messaging.SingleEmailMessage> emails =
            new List<Messaging.SingleEmailMessage>();

        // ─────────────────────────────────────────
        // EMAIL TEMPLATE
        // ─────────────────────────────────────────
        EmailTemplate temp = [

            SELECT Id

            FROM EmailTemplate

            WHERE DeveloperName =
                'Certification_Expiry_Alert_Template'

            LIMIT 1
        ];

        // ─────────────────────────────────────────
        // CUSTOM NOTIFICATION TYPE
        // ─────────────────────────────────────────
        CustomNotificationType notifType = [

            SELECT Id

            FROM CustomNotificationType

            WHERE DeveloperName =
                'Certification_Expiry_Alert'

            LIMIT 1
        ];

        // ─────────────────────────────────────────
        // ORG-WIDE EMAIL ADDRESS (EPICARE)
        // ─────────────────────────────────────────
        OrgWideEmailAddress epicareEmail = [

            SELECT Id

            FROM OrgWideEmailAddress

            WHERE DisplayName = 'Epicare'

            LIMIT 1
        ];

        // ─────────────────────────────────────────
        // LOOP CERTIFICATIONS
        // ─────────────────────────────────────────
        for (Certification__c cert : scope) {

            System.debug(
                'PROCESSING CERTIFICATION → ' +
                cert.Name
            );

            // ─────────────────────────────────────
            // EMAIL TO AGENT (CONTACT)
            // ─────────────────────────────────────
            if (cert.Agent__c != null) {

                Messaging.SingleEmailMessage mail =
                    new Messaging.SingleEmailMessage();

                // Email Template
                mail.setTemplateId(temp.Id);

                // Contact Recipient
                mail.setTargetObjectId(cert.Agent__c);

                // Related Certification Record
                mail.setWhatId(cert.Id);

                // Prevent activity creation
                mail.setSaveAsActivity(false);

                // SET EPICARE AS SENDER
                mail.setOrgWideEmailAddressId(epicareEmail.Id);

                emails.add(mail);

                System.debug(
                    'EMAIL ADDED FOR AGENT'
                );
            }

            // ─────────────────────────────────────
            // SALESFORCE NOTIFICATION TO OWNER
            // ─────────────────────────────────────
            if (cert.OwnerId != null) {

                Messaging.CustomNotification notification =
                    new Messaging.CustomNotification();

                notification.setTitle(
                    'Certification Expiry Alert'
                );

                notification.setBody(
                    cert.Name +
                    ' is expiring in ' +
                    cert.Days_Until_Expiry__c +
                    ' days.'
                );

                notification.setNotificationTypeId(
                    notifType.Id
                );

                // Opens Certification record
                notification.setTargetId(cert.Id);

                // IMPORTANT FIX
                notification.send(
                    new Set<String>{
                        String.valueOf(cert.OwnerId)
                    }
                );

                System.debug(
                    'NOTIFICATION SENT TO OWNER → ' +
                    cert.OwnerId
                );
            }
        }

        // ─────────────────────────────────────────
        // SEND EMAILS
        // ─────────────────────────────────────────
        if (!emails.isEmpty()) {

            Messaging.SendEmailResult[] results =
                Messaging.sendEmail(emails);

            System.debug(
                'EMAIL RESULTS → ' +
                results
            );

            System.debug(
                'TOTAL EMAILS SENT → ' +
                emails.size()
            );
        }
        else {

            System.debug(
                'NO EMAILS TO SEND'
            );
        }
    }

    // ─────────────────────────────────────────────
    // FINISH
    // ─────────────────────────────────────────────
    public void finish(
        Database.BatchableContext bc
    ) {

        System.debug(
            'Certification Expiry Batch Completed'
        );
    }
}