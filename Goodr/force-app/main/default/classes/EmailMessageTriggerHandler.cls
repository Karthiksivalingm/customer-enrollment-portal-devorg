public class EmailMessageTriggerHandler {

    public static void handleAfterInsert(List<EmailMessage> newEmailMessages) {
        EmailMessageTriggerHelper.processNewEmailMessages(newEmailMessages);
    }
}