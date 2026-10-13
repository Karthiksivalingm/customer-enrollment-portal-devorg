public class OpportuntiyClosedWonAlert {
    
    @InvocableMethod(label='Send Eamil To Primary Contact')
    public static void sendEmailAlert(List<Id> contactId) {
        EmailTemplate template = [SELECT Id from EmailTemplate where Name ='Starter IA CSA Outreach' LIMIT 1];
        OrgWideEmailAddress orgEmail = [select Id,Address from OrgWideEmailAddress WHERE Address = 'customersupport@everquote.com' LIMIT 1];
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        eMail.setTemplateId(template.Id);
        eMail.setTargetObjectId(contactId[0]);
        Email.setOrgWideEmailAddressId(orgEmail.Id);
        if(!Test.isRunningTest())
        	Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
    
}