trigger CaseReopenOnCustomerReply on EmailMessage (after insert) {
    
    CaseReopenHandler.reopenClosedCases(Trigger.new);
}