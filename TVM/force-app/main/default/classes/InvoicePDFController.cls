public class InvoicePDFController {//this part grabs fields and passes it along to PDF Generator
    
    public Opportunity opportunity {get; set;}
    
    public invoicePDFController(){
        
        String opportunityId = ApexPages.currentPage().getParameters().get('opportunityId');
        
        this.opportunity = [SELECT Id, Launch_Month__c, Order_Confirmation_Products__c, Contracted_Amount__c, Dealer_DocuSign_Contact__r.Name, Dealer_DocuSign_Contact__r.Contact_Title__c, Account_RAD__c, Account.Name, Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode, Account.Analytics_Franchise__c 
                           FROM Opportunity
                           WHERE Id = :opportunityId
                            
                           ];
                           
                          
    }

	@InvocableMethod(label='Email PDF' description='Generates and Emails a PDF')//This part talks to the Screen Flow
    public static void generatePDF(List<List<String>> args){
        List<String> nested = args[0];
        
        String email = nested[0];
        String recordId = nested[1];
        
        PageReference PDF = new PageReference('/apex/PDF_Generator_Beta?Id=' + recordId);//creates the pdf with PDF Generator
        
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setContentType('application/pdf');
        attachment.setFileName('Order.pdf');
        try{
		Blob b = PDF.getContentAsPDF();//Converts to blob object type pdf
        attachment.setBody(b);
        }
        catch(exception e){
            Messaging.SingleEmailMessage ErrorEmail= new Messaging.SingleEmailMessage();
            ErrorEmail.setToAddresses(new String[] {email});
            ErrorEmail.setSubject('Upsell Attachment Issue');
            ErrorEmail.setHtmlBody('Upsell Attachment Issue: '+e);
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { ErrorEmail });
        }
        attachment.setInline(false);
        
        
        
        Messaging.SingleEmailMessage mail= new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] {email});
        mail.setSubject('Order Details');
        //here is Email body
        mail.setHtmlBody('Here are the details of the deal.');
        mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
        
        try{
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
        catch(exception e){
            Messaging.SingleEmailMessage ErrorEmail= new Messaging.SingleEmailMessage();
            ErrorEmail.setToAddresses(new String[] {email});
            ErrorEmail.setSubject('Upsell Emailing Issue');
            ErrorEmail.setHtmlBody('Upsell emailing Issue: '+e);
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { ErrorEmail });
        }

    }
}