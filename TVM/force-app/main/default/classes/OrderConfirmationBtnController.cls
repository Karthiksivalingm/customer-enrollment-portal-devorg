public class OrderConfirmationBtnController {
    
    public ID oppoID { get; set; }
    public Boolean isError { get; set; }
    public List<Contact> lstConSigner { get; set; }

    public OrderConfirmationBtnController(ApexPages.StandardController controller){
        isError = false;
        oppoID = controller.getId();

        if(oppoID != null){
            Opportunity opp = [SELECT Id, AccountId 
                               FROM Opportunity 
                               WHERE Id = :oppoID 
                               LIMIT 1];

            // Check if the account has a Foundation Contract Signer
            lstConSigner = [SELECT Id, Name, Email, Title__c
                            FROM Contact 
                            WHERE AccountId = :opp.AccountId 
                            AND Contact_Role__c includes ('Foundation Contract Signer') 
                            LIMIT 1];

            if(lstConSigner.isEmpty()){
                isError = true;
                ApexPages.addMessage(new ApexPages.Message(
                    ApexPages.Severity.ERROR, 
                    'There is no Foundation Contract Signer role on this account. Please add Foundation Contract Signer and try again.'
                ));
            }
        }
    }

    public PageReference savePDF() {
        if(isError){
            // Safety check: prevent sending PDF/email if no signer
            return null;
        }

        Id oppId = oppoID;
        
        // UPDATED LINE: Pointing to the correct _FNDN Visualforce page
        PageReference pdfPage = new PageReference('/apex/OrderConfirmationPDF_FNDN');
        
        pdfPage.getParameters().put('id', oppId);
        pdfPage.getParameters().put('renderAs', 'pdf');
        pdfPage.setRedirect(true);

        PageReference ret;

        Blob pdfBlob = Test.isRunningTest()
            ? Blob.valueOf('Test PDF Content')
            : pdfPage.getContentAsPDF();

        Opportunity opp = [SELECT Id, Account.Id, Account.Name, Contract_Signer__c, Contract_Signer_Email__c, Contract_Sent_Date__c,
                           Contract_Signer_Title__c, Contract_Signer_Phone__c, Target_Launch_Month__c, 
                           Account.Regional_performance_manager__r.Email, Account.Account_Technician__r.Email
                           FROM Opportunity 
                           WHERE Id = :oppId LIMIT 1];

        String dttoday = System.Today().format();

        ContentVersion cv = new ContentVersion(                
            Title = 'Order Confirmation ' + opp.Account.Name + ' ' + dttoday,
            PathOnClient = 'Order Confirmation ' + opp.Account.Name + ' ' + dttoday + '.pdf',
            VersionData = pdfBlob,
            FirstPublishLocationId = oppId
        );
        insert cv;

        ret = new ApexPages.StandardController([SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id]).view();

        // Use the signer queried in constructor
        Contact signer = lstConSigner[0];

        String productList = '';        	
        for (OpportunityLineItem opli : [SELECT Id, Product2.Name,Contract_Product_Name__c FROM OpportunityLineItem WHERE OpportunityId = :oppId]) {
            //productList += opli.Product2.Name + '<br/>';
            productList += opli.Contract_Product_Name__c + '<br/>';
        }

        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        Messaging.EmailFileAttachment efa1 = new Messaging.EmailFileAttachment();

        efa1.setBody(pdfBlob);
        efa1.setFileName(cv.Title);
        efa1.setContentType('application/pdf');
        mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa1});

        mail.setSubject('Revised Foundation Direct Agreement: ' + opp.Account.Name);
        mail.setToAddresses(new String[] {signer.Email});

        List<String> ccEmails = new List<String>();
        if (!String.isEmpty(Label.Order_Confirmation_CC_Email_Addr)) {
            ccEmails = Label.Order_Confirmation_CC_Email_Addr.split(',');
        }
        if(opp.Account.Regional_performance_manager__r.Email != null){
            ccEmails.add(opp.Account.Regional_performance_manager__r.Email);	
        }
        if(opp.Account.Account_Technician__r.Email != null){
            ccEmails.add(opp.Account.Account_Technician__r.Email);	
        }        
        mail.setCcAddresses(ccEmails);    

        String emailBody = 'Hi ' + opp.Account.Name + ',<br/><br/>' +
            'Attached are the agreed upon changes to your Digital Advertisement Agreement. Per your request, your account has been updated to include the following product(s):<br/><br/>' +
            productList + 
            '<br/>These changes are expected to take effect with a target launch of ' + opp.Target_Launch_Month__c + 
            ', pending all required approvals. Timelines may be adjusted based on review processes and implementation requirements; we will keep you informed of any updates.<br/><br/>' +
            'We look forward to supporting your business with this updated service. Thank you for your partnership!<br/><br/>' +
            'Sincerely,<br/>' +
            'contract@foundationdirect.com';

        String fromEmail = '';
        if (!String.isEmpty(Label.Contract_Email_Address)) {
            fromEmail = Label.Contract_Email_Address;
        }

        if (fromEmail != ''){
            if(!Test.isRunningTest()){
                OrgWideEmailAddress[] orgWideEmails = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :fromEmail LIMIT 1];
                mail.setOrgWideEmailAddressId(orgWideEmails[0].id);
            } else {
                OrgWideEmailAddress[] orgWideEmails = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
                mail.setOrgWideEmailAddressId(orgWideEmails[0].id);
            }
        }

        mail.setHtmlBody(emailBody);            
        messages.add(mail);
        Messaging.sendEmail(messages);

        // Update Opportunity with contract info
        opp.Contract_Signer__c = signer.Name;
        opp.Contract_Signer_Email__c = signer.Email;
        opp.Contract_Sent_Date__c = System.today();
        opp.Contract_Signer_Title__c = signer.Title__c;
        opp.Order_Conformation_Sent__c = true;
        update opp;

        return ret;
    }
}