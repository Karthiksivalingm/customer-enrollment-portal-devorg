/**
 * Trigger  : EnrollmentApprovedSubscriber
 * Object   : Enrollment_Approved__e  (Platform Event)
 *
 * Rewritten per ticket 2.6 (CD2 C0d/C11/C12/C17 + CMR §§1-4). All logic now
 * lives in EnrollmentApprovedSubscriberHandler — see that class for the full
 * design, the record-generation rules, and every flagged assumption that
 * still needs schema verification.
 */
trigger EnrollmentApprovedSubscriber on Enrollment_Approved__e (after insert) {
    EnrollmentApprovedSubscriberHandler.handleAfterInsert(Trigger.new);
}