trigger AppointmentTrigger
on Appointment__c (
    before insert,
    before update,
    after insert,
    after update
) {

  /*  new AppointmentTriggerHandler().run();

    if(Trigger.isAfter){
        AppointmentStateAppointmentHandler.createStateAppointments(
            Trigger.new,
            Trigger.isInsert ? null : Trigger.oldMap
        );
    }*/
}