trigger AppointmentStatusChangedTrigger on Appointment__c (after update) {

    List<Appointment_Status_Changed__e> events      = new List<Appointment_Status_Changed__e>();
    List<Appointment__c>                appointments = new List<Appointment__c>();

    for (Appointment__c a : Trigger.new) {

        Appointment__c oldA = Trigger.oldMap.get(a.Id);

        if (a.Status__c != oldA.Status__c) {

            // ─────────────────────────────────────
            // Fire on any Status__c change
            // Now includes Sub_Status__c in payload
            // ─────────────────────────────────────
            events.add(new Appointment_Status_Changed__e(
                Appointment_ID__c = String.valueOf(a.Id),
                New_Status__c     = a.Status__c,
                Sub_Status__c     = a.Sub_Status__c,
                Carrier__c        = String.valueOf(a.Carrier__c),
                Writing_Number__c = a.Writing_Number__c,
                Contact_Id__c     = String.valueOf(a.Agent__c),
                NPN__c            = a.Agent__r.NPN__c  
            ));

            appointments.add(a);

            // ─────────────────────────────────────
            // Status → 'On Agent Side'
            // AND Carrier_Cert_Required__c = true
            // (field name casing corrected)
            // ─────────────────────────────────────
            if (
                a.Status__c == 'On Agent Side'
                &&
                a.Carrier_Cert_Required__c == true
            ) {

                events.add(new Appointment_Status_Changed__e(
                    Appointment_ID__c = String.valueOf(a.Id),
                    New_Status__c     = 'Carrier Cert Required',
                    Sub_Status__c     = a.Sub_Status__c,
                    Carrier__c        = String.valueOf(a.Carrier__c),
                    Writing_Number__c = a.Writing_Number__c,
                    Contact_Id__c     = String.valueOf(a.Agent__c),
                    NPN__c            = a.Agent__r.NPN__c  
                ));

                appointments.add(a);
            }
        }
    }

    if (!events.isEmpty()) {

        try {

            List<Database.SaveResult> results =
                EventBus.publish(events);

            AppointmentStatusChangedHelper.logErrors(
                results,
                appointments
            );

        } catch (Exception e) {

            insert new Error_Log__c(
                Event_Type__c    = 'Appointment_Status_Changed__e',
                Error_Message__c = e.getMessage(),
                Stack_Trace__c   = e.getStackTraceString(),
                Source__c        = 'AppointmentStatusChangedTrigger',
                Severity__c      = 'High',
                Status__c        = 'New'
            );
        }
    }
}