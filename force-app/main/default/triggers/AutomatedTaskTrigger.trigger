/**
 * AutomatedTaskTrigger
 *
 * Replaces DeleteAutomatedTasksBatch (scheduled batch job) with immediate,
 * on-insert deletion of Tasks auto-created by Einstein Activity Capture.
 *
 * Per team decision (Slack thread, Kayla / Sandip Patel):
 *   - Delete automated tasks as soon as they're created, not on a daily
 *     schedule, and not gated behind a 5-7 day age threshold.
 *   - Trigger instead of schedule, since deletion needs to happen
 *     immediately, not periodically.
 *
 * NOTE: This only handles Tasks created from this point forward. Any
 * existing backlog of matching Tasks should be cleared with one final
 * manual run of DeleteAutomatedTasksBatch before it's retired.
 */
trigger AutomatedTaskTrigger on Task (after insert) {

    if (Trigger.isAfter && Trigger.isInsert) {
        AutomatedTaskTriggerHandler.deleteAutomatedTasks(Trigger.new);
    }
}