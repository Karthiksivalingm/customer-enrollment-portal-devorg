@isTest
public class slack_tst_User_Ticket {
	@isTest 
	static void testTrigger() {
		User_Story__c obj0 = new User_Story__c(
			Priority__c = 'Backlog',
			Short_Description__c = 's',
			Application__c = 'General'
		);
		insert obj0;
	}
}