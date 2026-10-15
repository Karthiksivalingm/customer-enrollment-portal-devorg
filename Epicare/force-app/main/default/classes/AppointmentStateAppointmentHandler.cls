public class AppointmentStateAppointmentHandler {

    public static void createStateAppointments(
        List<Appointment__c> newRecords,
        Map<Id, Appointment__c> oldMap
    ) {

        Set<Id> appointmentIds = new Set<Id>();
        Map<Id, Appointment__c> appointmentsToProcess = new Map<Id, Appointment__c>();

        for(Appointment__c app : newRecords) {

            Boolean shouldProcess = false;

            // Insert
            if(oldMap == null) {
                shouldProcess = true;
            }
            // Update only when State_s__c changes
            else {
                Appointment__c oldApp = oldMap.get(app.Id);

                if(app.State_s__c != oldApp.State_s__c) {
                    shouldProcess = true;
                }
            }

            if(shouldProcess && String.isNotBlank(app.State_s__c)) {
                appointmentIds.add(app.Id);
                appointmentsToProcess.put(app.Id, app);
            }
        }

        if(appointmentIds.isEmpty()) {
            return;
        }

        Map<Id, Set<String>> existingStatesByAppointment = new Map<Id, Set<String>>();

        for(State_Appointment__c sa : [
            SELECT Id, Appointment__c, State__c
            FROM State_Appointment__c
            WHERE Appointment__c IN :appointmentIds
        ]) {

            if(!existingStatesByAppointment.containsKey(sa.Appointment__c)) {
                existingStatesByAppointment.put(
                    sa.Appointment__c,
                    new Set<String>()
                );
            }

            existingStatesByAppointment.get(sa.Appointment__c)
                .add(sa.State__c);
        }

        List<State_Appointment__c> recordsToInsert = new List<State_Appointment__c>();

        for(Appointment__c app : appointmentsToProcess.values()) {

            Set<String> existingStates =
                existingStatesByAppointment.containsKey(app.Id)
                ? existingStatesByAppointment.get(app.Id)
                : new Set<String>();

            for(String stateValue : app.State_s__c.split(';')) {

                stateValue = stateValue.trim();

                if(String.isBlank(stateValue)) {
                    continue;
                }

                // Skip if already exists
                if(existingStates.contains(stateValue)) {
                    continue;
                }

                recordsToInsert.add(
                    new State_Appointment__c(
                        Appointment__c = app.Id,
                        State__c = stateValue,
                        State_Status__c = 'On agent Side'
                    )
                );

                existingStates.add(stateValue);
            }
        }

        if(!recordsToInsert.isEmpty()) {
            insert recordsToInsert;
        }
    }
}