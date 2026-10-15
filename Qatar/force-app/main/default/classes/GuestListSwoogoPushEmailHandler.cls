/**
 * GuestListSwoogoPushEmailHandler
 * ---------------------------------------------------------------------
 * Fires when a Guest_List__c record's Swoogo_Push_Status__c field changes
 * and its new value contains "success" (case-insensitive), the record is
 * a "parent" guest (Main_Guest__c is blank), and the related Invitation__c
 * name contains one of the tracked event keywords. Sends a styled HTML
 * notification email to the matching distribution list(s).
 *
 * NOTE ON ASSUMPTIONS (please confirm / adjust if wrong):
 * 1. Swoogo_Push_Status__c is treated as a TEXT field whose value contains
 *    the word "Success" somewhere (e.g. "Push Success", "Success"). If it's
 *    actually a Checkbox, see the alternate boolean check commented below.
 * 2. "Parent record" = Main_Guest__c is null on the Guest_List__c record
 *    itself (Main_Guest__c is the self-lookup used elsewhere for +1 guests).
 * 3. Invitation__c Name matching is a case-insensitive CONTAINS match
 *    against: September, October, Design Doha, Rubaiya, fta.
 * 4. If an Invitation Name matches more than one keyword, the email is
 *    sent to ALL matching distribution addresses at once (one email).
 */
public with sharing class GuestListSwoogoPushEmailHandler {

  
}