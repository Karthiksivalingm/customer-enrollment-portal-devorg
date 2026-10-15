trigger AppointmentStatusChangedEventSubscriber on Appointment_Status_Changed__e (after insert) {
    AppointmentStatusChangedHelper.sendToGoAMS(Trigger.new);
}