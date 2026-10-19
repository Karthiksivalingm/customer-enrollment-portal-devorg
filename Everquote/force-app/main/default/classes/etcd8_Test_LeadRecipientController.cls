/*
 * eightCloud (2014)
 * Test class for etcd8_LeadRecipientController class
 */
@isTest
private class etcd8_Test_LeadRecipientController {
  static testMethod void testLeadRecipientController() {
    Profile pfl = [SELECT id FROM profile WHERE name = 'Standard User'];

    List<User> lstUser = new List<User>();
    for (Integer i = 0; i < 2; i++) {
      User testUser = getUserObject(pfl, 'test' + i);
      lstUser.add(testUser);
    }
    insert lstUser;
    Boolean setNextFlag = false;

    etcd8_LeadRecipientController control = new etcd8_LeadRecipientController();

    control.leadRecipient.user__c = lstUser[0].Id;
    control.add();

    List<etcd8_LeadRecipient__c> leadRecip = [
      SELECT Id, nextup__c, user__c
      FROM etcd8_LeadRecipient__c
      ORDER BY createddate
    ];
    //To add asserts
    system.assert(!leadRecip.isEmpty());
    system.assert(leadRecip.size() == 1);
    system.assert(leadRecip[0].nextup__c);

    control.leadRecipient.user__c = lstUser[1].Id;
    control.add();

    leadRecip = [SELECT Id, nextup__c FROM etcd8_LeadRecipient__c ORDER BY createddate];
    //To add asserts
    system.assert(!leadRecip.isEmpty());
    system.assert(leadRecip.size() == 2);
    system.assert(!leadRecip[1].nextup__c);

    control.leadRecipient.user__c = lstUser[0].Id;
    control.add();

    leadRecip = [SELECT Id, nextup__c FROM etcd8_LeadRecipient__c];
    //To add asserts
    system.assert(!leadRecip.isEmpty());
    system.assert(leadRecip.size() == 2);

    control.getLeadRecipients();
    system.assert(!control.lstLeadRecipient.isEmpty());

    control.save();
    control.populateOpenLeadCount();
    leadRecip = [
      SELECT Id, nextup__c, openleads__c, available__c
      FROM etcd8_LeadRecipient__c
      ORDER BY createddate
    ];
    for (etcd8_LeadRecipient__c recip : leadRecip) {
      system.assert(recip.openleads__c == 0);
      system.assert(recip.available__c);
    }

    control.queryLeadRecipients();
    control.onLoad();
    system.assert(true);
  }

  /******************************************************************************************
   * Create user record
   ******************************************************************************************/
  public static User getUserObject(Profile pfl, String username) {
    return new User(
      alias = username,
      email = 'u1@everquote.ai',
      emailencodingkey = 'UTF-8',
      lastname = 'Testing',
      languagelocalekey = 'en_US',
      localesidkey = 'en_US',
      profileid = pfl.Id,
      country = 'United States',
      CommunityNickname = username,
      timezonesidkey = 'America/Los_Angeles',
      Odie_Agent_ID__c = Integer.valueof((Math.random() * 10000)),
      username = username +
        Datetime.now().hour() +
        Datetime.now().minute() +
        Datetime.now().second() +
        '@everquote.ai'
    );
  }
}