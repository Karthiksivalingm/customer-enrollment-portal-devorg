public class AppointmentLicenseAlertBatch
    implements Database.Batchable<SObject> {

    // ─────────────────────────────────────────────
    // START
    // Query: Status = 'Active'
    //        Sub_Status__c = 'Ready to sell'
    //        Renewal_Date within next 90 days
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
                   Sub_Status__c,
                   State_s__c,
                   Renewal_Date__c,
                   OwnerId,
                   Agent__r.Name,
                   Carrier__r.Name

            FROM Appointment__c

            WHERE Status__c = 'Active'
            AND Sub_Status__c = 'Ready to sell'
            AND Renewal_Date__c != null
            AND Renewal_Date__c >= :today
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
        List<CustomNotificationType> notifTypes = [

            SELECT Id

            FROM CustomNotificationType

            WHERE DeveloperName =
                'Appointment_Renewal_Alert'

            LIMIT 1
        ];

        if (notifTypes.isEmpty()) {

            insert new Error_Log__c(
                Event_Type__c    = 'AppointmentLicenseAlertBatch',
                Error_Message__c = 'CustomNotificationType "Appointment_Renewal_Alert" not found.',
                Source__c        = 'AppointmentLicenseAlertBatch.execute',
                Severity__c      = 'High',
                Status__c        = 'New'
            );

            return;
        }

        CustomNotificationType notifType =
            notifTypes[0];

        // ─────────────────────────────────────────
        // RESOLVE CONTRACTING GROUP
        // ─────────────────────────────────────────
        List<Group> contractingGroups = [

            SELECT Id

            FROM Group

            WHERE DeveloperName = 'Contracting'
            AND Type = 'Regular'

            LIMIT 1
        ];

        if (contractingGroups.isEmpty()) {

            insert new Error_Log__c(
                Event_Type__c    = 'AppointmentLicenseAlertBatch',
                Error_Message__c = 'Public Group "Contracting" not found. License alerts not sent.',
                Source__c        = 'AppointmentLicenseAlertBatch.execute',
                Severity__c      = 'High',
                Status__c        = 'New'
            );

            return;
        }

        Set<String> contractingRecipient =
            new Set<String>{
                String.valueOf(
                    contractingGroups[0].Id
                )
            };

        // ─────────────────────────────────────────
        // COLLECT APPOINTMENT IDs + STATES
        // TO CHECK DOI / LOA COVERAGE
        // ─────────────────────────────────────────
        Set<Id>     appointmentIds = new Set<Id>();
        Set<String> allStates      = new Set<String>();

        for (Appointment__c appt : scope) {

            appointmentIds.add(appt.Id);

            if (String.isNotBlank(appt.State_s__c)) {

                for (String st : appt.State_s__c.split(';')) {

                    allStates.add(st.trim());
                }
            }
        }

        // ─────────────────────────────────────────
        // QUERY ACTIVE STATE LICENSES (DOI / LOA)
        // Builds a map: AppointmentId → Set<State>
        // that have at least one Active license
        // ─────────────────────────────────────────
        Map<Id, Set<String>> activeLicenseMap =
            new Map<Id, Set<String>>();

        if (
            !appointmentIds.isEmpty()
            &&
            !allStates.isEmpty()
        ) {

            for (State_Appointment__c lic : [

                SELECT Appointment__c,
                       State__c

                FROM State_Appointment__c

                WHERE Appointment__c IN :appointmentIds
                AND State__c IN :allStates
                AND State_Status__c = 'Active'
            ]) {

                if (
                    !activeLicenseMap.containsKey(
                        lic.Appointment__c
                    )
                ) {

                    activeLicenseMap.put(
                        lic.Appointment__c,
                        new Set<String>()
                    );
                }

                activeLicenseMap
                    .get(lic.Appointment__c)
                    .add(lic.State__c != null
                        ? lic.State__c.trim()
                        : '');
            }
        }

        Date today = Date.today();

        // ─────────────────────────────────────────
        // LOOP APPOINTMENTS
        // Only alert where at least one state
        // has NO active DOI / LOA
        // ─────────────────────────────────────────
        for (Appointment__c appt : scope) {

            List<String> uncoveredStates =
                new List<String>();

            if (String.isNotBlank(appt.State_s__c)) {

                Set<String> activeLicensedStates =
                    activeLicenseMap.containsKey(appt.Id)
                    ? activeLicenseMap.get(appt.Id)
                    : new Set<String>();

                for (
                    String st :
                    appt.State_s__c.split(';')
                ) {

                    String trimmed = st.trim();

                    if (
                        !activeLicensedStates.contains(
                            trimmed
                        )
                    ) {

                        uncoveredStates.add(trimmed);
                    }
                }
            }

            if (uncoveredStates.isEmpty()) {
                continue;
            }

            Integer daysRemaining =
                today.daysBetween(
                    appt.Renewal_Date__c
                );

            try {

                Messaging.CustomNotification notification =
                    new Messaging.CustomNotification();

                notification.setTitle(
                    'Appointment License Alert — Missing DOI/LOA'
                );

                notification.setBody(
                    'Appointment for agent "' +
                    appt.Agent__r.Name +
                    '" with carrier "' +
                    appt.Carrier__r.Name +
                    '" expires in ' +
                    daysRemaining +
                    ' day(s). No active DOI/LOA for state(s): ' +
                    String.join(uncoveredStates, ', ') +
                    '. Please take action.'
                );

                notification.setNotificationTypeId(
                    notifType.Id
                );

                notification.setTargetId(appt.Id);

                notification.send(contractingRecipient);

                System.debug(
                    'LICENSE ALERT SENT → ' +
                    appt.Name +
                    ' | Uncovered states: ' +
                    String.join(uncoveredStates, ', ')
                );

            } catch (Exception e) {

                insert new Error_Log__c(
                    Event_Type__c    = 'AppointmentLicenseAlertBatch',
                    Error_Message__c = e.getMessage(),
                    Stack_Trace__c   = e.getStackTraceString(),
                    Source__c        = 'AppointmentLicenseAlertBatch.execute → ' + appt.Id,
                    Severity__c      = 'High',
                    Status__c        = 'New'
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
            'AppointmentLicenseAlertBatch completed.'
        );
    }
}