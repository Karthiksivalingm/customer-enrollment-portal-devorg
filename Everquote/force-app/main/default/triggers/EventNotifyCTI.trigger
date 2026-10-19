trigger EventNotifyCTI on Event (after insert, after update) {
    // moved to ConvertedLead since callout need to be first
	// NotifyCTI.sendUpdate('event');
}