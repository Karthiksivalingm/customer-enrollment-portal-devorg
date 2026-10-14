trigger FeedItemTrigger on FeedItem (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        CreateCaseCommentHandler.handleAfterInsert(Trigger.new);
    }
}