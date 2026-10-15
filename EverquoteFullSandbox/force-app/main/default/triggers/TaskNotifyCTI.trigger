trigger TaskNotifyCTI on Task (after insert, after update) {

    NotifyCTI.sendUpdate('task');

}