public class AHIPFFMCertificationBatch
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

            WHERE Days_Until_Expiry__c < 90
            AND Status__c = 'Active'
            AND Certification_Type__c IN ('AHIP', 'FFM')
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

        // Email Template
        EmailTemplate temp = [

            SELECT Id

            FROM EmailTemplate

            WHERE DeveloperName =
                'AHIP_FFM_Certification_Expiry_Alert'

            LIMIT 1
        ];

        // Notification Type
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

        for (Certification__c cert : scope) {

            // ─────────────────────────────────────
            // EMAIL TO AGENT
            // ─────────────────────────────────────
            if (cert.Agent__c != null) {

                Messaging.SingleEmailMessage mail =
                    new Messaging.SingleEmailMessage();

                mail.setTemplateId(temp.Id);

                mail.setTargetObjectId(cert.Agent__c);

                mail.setWhatId(cert.Id);

                mail.setSaveAsActivity(false);

                // SET EPICARE AS SENDER
                mail.setOrgWideEmailAddressId(epicareEmail.Id);

                emails.add(mail);
            }

            // ─────────────────────────────────────
            // NOTIFICATION TO OWNER
            // ─────────────────────────────────────
            if (cert.OwnerId != null) {

                Messaging.CustomNotification notification =
                    new Messaging.CustomNotification();

                notification.setTitle(
                    'AHIP / FFM Certification Expiry'
                );

                notification.setBody(
                    cert.Name +
                    ' expires in ' +
                    cert.Days_Until_Expiry__c +
                    ' days.'
                );

                notification.setNotificationTypeId(
                    notifType.Id
                );

                notification.setTargetId(cert.Id);

                notification.send(
                    new Set<String>{
                        String.valueOf(cert.OwnerId)
                    }
                );
            }
        }

        // Send Emails
        if (!emails.isEmpty()) {

            Messaging.sendEmail(emails);
        }
    }

    // ─────────────────────────────────────────────
    // FINISH
    // ─────────────────────────────────────────────
    public void finish(
        Database.BatchableContext bc
    ) {

        System.debug(
            'AHIP/FFM Expiry Batch Completed'
        );
    }
}