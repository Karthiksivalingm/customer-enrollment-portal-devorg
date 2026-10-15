public class AppointmentRenewalAlertBatch
    implements Database.Batchable<SObject> {

    // ─────────────────────────────────────────────
    // START
    // ─────────────────────────────────────────────
    public Database.QueryLocator start(
        Database.BatchableContext bc
    ) {

        Date today = Date.today();
        Date day90 = today.addDays(90);

        return Database.getQueryLocator([

            SELECT Id,
                   Name,
                   Status__c,
                   Renewal_Date__c,
                   OwnerId,
                   Agent__r.Name,
                   Carrier__r.Name

            FROM Appointment__c

            WHERE Status__c = 'Active'
            AND Renewal_Date__c != null
            AND Renewal_Date__c <= :day90
        ]);
    }

    // ─────────────────────────────────────────────
    // EXECUTE
    // ─────────────────────────────────────────────
    public void execute(
        Database.BatchableContext bc,
        List<Appointment__c> scope
    ) {

        // ─────────────────────────────────────────
        // CUSTOM NOTIFICATION TYPE
        // ─────────────────────────────────────────
        CustomNotificationType notifType = [

            SELECT Id

            FROM CustomNotificationType

            WHERE DeveloperName =
                'Appointment_Renewal_Alert'

            LIMIT 1
        ];

        Date today = Date.today();

        // ─────────────────────────────────────────
        // LOOP APPOINTMENTS
        // ─────────────────────────────────────────
        for (Appointment__c appt : scope) {

            Integer daysRemaining =
                today.daysBetween(
                    appt.Renewal_Date__c
                );

            // ─────────────────────────────────────
            // DAILY NOTIFICATION
            // ─────────────────────────────────────
            if (appt.OwnerId != null) {

                Messaging.CustomNotification notification =
                    new Messaging.CustomNotification();

                notification.setTitle(
                    'Appointment Renewal Alert'
                );

                notification.setBody(
                    'Appointment for agent "' +
                    appt.Agent__r.Name +
                    '" with carrier "' +
                    appt.Carrier__r.Name +
                    '" expires in ' +
                    daysRemaining +
                    ' days.'
                );

                notification.setNotificationTypeId(
                    notifType.Id
                );

                // Opens Appointment record
                notification.setTargetId(
                    appt.Id
                );

                notification.send(
                    new Set<String>{
                        String.valueOf(appt.OwnerId)
                    }
                );

                System.debug(
                    'DAILY NOTIFICATION SENT → ' +
                    appt.Name
                );
            }
        }
    }

    // ─────────────────────────────────────────────
    // FINISH
    // ─────────────────────────────────────────────
    public void finish(
        Database.BatchableContext bc
    ) {

        System.debug(
            'Appointment Renewal Alert Batch Completed'
        );
    }
}