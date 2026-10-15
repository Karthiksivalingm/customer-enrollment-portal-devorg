// ─────────────────────────────────────────────
// BATCH CLASS
// ─────────────────────────────────────────────
public class EOInsuranceExpiryBatch
    implements Database.Batchable<SObject> {

    // ─────────────────────────────────────────
    // START
    // ─────────────────────────────────────────
    public Database.QueryLocator start(
        Database.BatchableContext bc
    ) {

        Date today = Date.today();
        Date day90 = today.addDays(90);

        return Database.getQueryLocator([

            SELECT Id,
                   Name,
                   Email,
                   OwnerId,
                   Agent_Status__c,
                   E_O_Termination_Date__c

            FROM Contact

            WHERE Agent_Status__c = 'Active'
            AND Email != null
            AND E_O_Termination_Date__c != null
            AND E_O_Termination_Date__c <= :day90
        ]);
    }

    // ─────────────────────────────────────────
    // EXECUTE
    // ─────────────────────────────────────────
    public void execute(
        Database.BatchableContext bc,
        List<Contact> scope
    ) {

        List<Messaging.SingleEmailMessage> emails =
            new List<Messaging.SingleEmailMessage>();

        // Email Template
        EmailTemplate temp = [

            SELECT Id

            FROM EmailTemplate

            WHERE DeveloperName =
                'E_O_Insurance_Expiry_Alert'

            LIMIT 1
        ];

        // Custom Notification Type
        CustomNotificationType notifType = [

            SELECT Id

            FROM CustomNotificationType

            WHERE DeveloperName =
                'Certification_Expiry_Alert'

            LIMIT 1
        ];

        // ─────────────────────────────────────
        // ORG-WIDE EMAIL ADDRESS (EPICARE)
        // ─────────────────────────────────────
        OrgWideEmailAddress epicareEmail = [

            SELECT Id

            FROM OrgWideEmailAddress

            WHERE DisplayName = 'Epicare'

            LIMIT 1
        ];

        Date today = Date.today();

        for (Contact con : scope) {

            Integer daysRemaining =
                today.daysBetween(
                    con.E_O_Termination_Date__c
                );

            System.debug(
                'Contact: ' + con.Name +
                ' | Days Remaining: ' +
                daysRemaining
            );

            // Only for EXACT 30 / 60 / 90
            if (
                daysRemaining == 30 ||
                daysRemaining == 60 ||
                daysRemaining == 90
            ) {

                System.debug(
                    'Condition Passed For: ' +
                    con.Name
                );

                // ─────────────────────────────
                // EMAIL ALERT
                // ─────────────────────────────
                if (String.isNotBlank(con.Email)) {

                    Messaging.SingleEmailMessage mail =
                        new Messaging.SingleEmailMessage();

                    // Email Template
                    mail.setTemplateId(temp.Id);

                    // Send to Contact
                    mail.setTargetObjectId(con.Id);

                    // Prevent Task creation
                    mail.setSaveAsActivity(false);

                    // SET EPICARE AS SENDER
                    mail.setOrgWideEmailAddressId(epicareEmail.Id);

                    emails.add(mail);

                    System.debug(
                        'Email Added For: ' +
                        con.Email
                    );
                }

                // ─────────────────────────────
                // CUSTOM NOTIFICATION
                // ─────────────────────────────
                if (con.OwnerId != null) {

                    Messaging.CustomNotification notification =
                        new Messaging.CustomNotification();

                    notification.setTitle(
                        'E&O Insurance Expiration Alert'
                    );

                    notification.setBody(
                        con.Name +
                        '\'s E&O Insurance expires in ' +
                        daysRemaining +
                        ' days.'
                    );

                    notification.setNotificationTypeId(
                        notifType.Id
                    );

                    notification.setTargetId(con.Id);

                    notification.send(
                        new Set<String>{
                            String.valueOf(con.OwnerId)
                        }
                    );

                    System.debug(
                        'Notification Sent For: ' +
                        con.Name
                    );
                }
            }
        }

        // ─────────────────────────────────────
        // SEND EMAILS
        // ─────────────────────────────────────
        if (!emails.isEmpty()) {

            Messaging.SendEmailResult[] results =
                Messaging.sendEmail(emails);

            System.debug(
                'Email Results: ' + results
            );
        }
        else {

            System.debug(
                'No Emails To Send'
            );
        }
    }

    // ─────────────────────────────────────────
    // FINISH
    // ─────────────────────────────────────────
    public void finish(
        Database.BatchableContext bc
    ) {

        System.debug(
            'E&O Insurance Expiry Batch Completed'
        );
    }
}