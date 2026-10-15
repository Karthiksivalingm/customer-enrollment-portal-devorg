public class NIPRStaleCheckBatch
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
                   OwnerId,
                   NIPR_Update_Before__c

            FROM Contact

            WHERE NIPR_Update_Before__c > 30
        ]);
    }

    // ─────────────────────────────────────────────
    // EXECUTE
    // ─────────────────────────────────────────────
    public void execute(
        Database.BatchableContext bc,
        List<Contact> scope
    ) {

        // Notification Type
        CustomNotificationType notifType = [

            SELECT Id

            FROM CustomNotificationType

            WHERE DeveloperName =
                'NIPR_Stale_Check_Alert'

            LIMIT 1
        ];

        for (Contact con : scope) {

            // ─────────────────────────────────────
            // ADMIN NOTIFICATION
            // ─────────────────────────────────────
            if (con.OwnerId != null) {

                Messaging.CustomNotification notification =
                    new Messaging.CustomNotification();

                notification.setTitle(
                    'NIPR Stale Record Alert'
                );

                notification.setBody(
                    con.Name +
                    ' has not been updated in NIPR for ' +
                    con.NIPR_Update_Before__c +
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
                    'NOTIFICATION SENT → ' +
                    con.Name
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
            'NIPR Stale Check Batch Completed'
        );
    }
}