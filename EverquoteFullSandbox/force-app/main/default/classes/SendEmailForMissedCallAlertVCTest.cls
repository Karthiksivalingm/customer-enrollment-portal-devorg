/**********************************
Class Name    : SendEmailForMissedCallAlertVCTest
Description     :This is test class for sending email on missed call.
Test Class      : 
Created Date    : 7-july-2024
Reviewd By      :
VERSION          DATE                                   DETAIL
--------------------------------------------------------------------------------------------------------- 
1.0             7-july-2024                                      
***********************************/
@isTest
public class SendEmailForMissedCallAlertVCTest {
    @isTest
    static void getEmailInfoAndSendTest() {
        SendEmailForMissedCallAlertVC.GettingInputDataForEmail emailRequest = new SendEmailForMissedCallAlertVC.GettingInputDataForEmail();
        OrgWideEmailAddress formEmailAddress = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'For missed call' LIMIT 1];
        emailRequest.emailRecipientAddress = 'recipient@example.com';
        emailRequest.emailBody = 'This is a test email body.';
        List<SendEmailForMissedCallAlertVC.GettingInputDataForEmail> emailRequestList = new List<SendEmailForMissedCallAlertVC.GettingInputDataForEmail>();
        emailRequestList.add(emailRequest);
        Test.startTest();
        SendEmailForMissedCallAlertVC.getEmailInfoAndSend(emailRequestList);
        Test.stopTest();
    }
}