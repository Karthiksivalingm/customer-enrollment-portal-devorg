/*
 * UpdateLeadMobilePhone.trigger
 *
 * Update Lead MobilePhone to match Phone
 * Twillio use MobilePhone field for sending sms
 *
 * Created By:      Daniel Voicu (dvoicu@everquote.com)
 * Created Date:    Apr 15, 2020
 *
 * Updated By:      Daniel Voicu (dvoicu@everquote.com)
 * Updated Date:    May 05, 2020
 *
 */
trigger UpdateLeadMobilePhone on Lead(before insert, before update) {
  String trigger_identifier = 'UpdateLeadMobilePhone';

  if (checkTriggerRecursion.canRun(trigger_identifier)) {
    for (Lead lead : Trigger.new) {
      if (lead.MobilePhone != lead.Phone) {
        lead.MobilePhone = lead.Phone;
      }
    }
  }
}