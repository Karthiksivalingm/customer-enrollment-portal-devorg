/**********************************
Class Name    : SendEmailForMissedCallAlertVC
Description     :This is for sending email on missed call.
Test Class      : SendEmailForMissedCallAlertVCTest
Created Date    : 7-july-2024
Reviewd By      :
VERSION          DATE                                   DETAIL
--------------------------------------------------------------------------------------------------------- 
1.0             7-july-2024                                      
***********************************/
public class SendEmailForMissedCallAlertVC {
    @InvocableMethod(label='Send Email on missed call' description=' Send Email on missed call' category='Email')
    public static void  getEmailInfoAndSend(List<GettingInputDataForEmail> listOfEmailInfo) {
        
        if(!listOfEmailInfo.IsEmpty()){
            List<OrgWideEmailAddress> formEmailAddress = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'For missed call' LIMIT 1];
            for(GettingInputDataForEmail sendingEmail : listOfEmailInfo ){
                Messaging.SingleEmailMessage mymail = new Messaging.SingleEmailMessage();
                String[] toAddresses = new String[] {sendingEmail.emailRecipientAddress};
                    if(!formEmailAddress.IsEmpty()){
                        mymail.setOrgWideEmailAddressId(formEmailAddress[0].Id);    
                    }
                mymail.setToAddresses(toAddresses);
                mymail.setSubject(sendingEmail.emailSubject);
                mymail.setHtmlBody(sendingEmail.emailBody);
                Messaging.sendEmail(new  Messaging.SingleEmailMessage[]{mymail}); 
            }
        }
    }
    public  class GettingInputDataForEmail {
        @InvocableVariable
        public string emailRecipientAddress;
        @InvocableVariable
        public string emailBody;
        @InvocableVariable
        public string emailSubject;
    }
    
}