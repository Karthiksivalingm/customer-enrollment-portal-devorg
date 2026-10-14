public class OrderConfirmationSend {
    public Opportunity opportunity {get; set;}
    public List<OpportunityLineItem> lineItems {get; set;}
    public Boolean isError {get; set;}
    public String specialNotes {get; set;}
    public Boolean showOemDealerCode {get; set;}
   
    public String isPDF { get { return 'pdf'; } } 
    
    
    public OrderConfirmationSend(){        
        String opportunityId = ApexPages.currentPage().getParameters().get('Id');
        
        if (String.isBlank(opportunityId)) {
            isError = true;
            return;
        }
        
        isError = false;
        
        // OEM_Dealer_Code__c added to SOQL below
        this.opportunity = [SELECT Id, Account.Name, Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode, Dealer_DocuSign_Contact__r.Name, Dealer_DocuSign_Contact__r.Contact_Title__c,  Analytics_Franchise__c, OEM_Dealer_Code__c, Account_RAD__c, Contracted_Amount__c, Order_Confirmation_Products__c, Launch_Month__c, Order_Confirmation_Subject_Line__c, Order_Confirmation_Notify__c, Addendum__c
                            FROM Opportunity
                           WHERE Id = :opportunityId LIMIT 1];
                           
        specialNotes = this.opportunity.Addendum__c; 
                           
        this.lineItems = [SELECT Id, Contract_Product_Name__c, MRR__c, Product2.Addendum_Language__c 
                          FROM OpportunityLineItem 
                          WHERE OpportunityId = :opportunityId];

        // Logic to conditionally display the OEM Dealer Code on the VF page
        showOemDealerCode = false;
        if (String.isNotBlank(this.opportunity.Analytics_Franchise__c)) {
            Set<String> targetFranchises = new Set<String>{'BUICK', 'BUICK GMC', 'CADILLAC', 'CHEVROLET', 'GM', 'GMC'};
            if (targetFranchises.contains(this.opportunity.Analytics_Franchise__c.toUpperCase())) {
                showOemDealerCode = true;
            }
        }
    }

 
    public Boolean getHasAddendum() {
    
        if (String.isNotBlank(specialNotes)) {
            return true;
        }
        
       
        if (lineItems != null) {
            for (OpportunityLineItem a : lineItems) { 
                if (String.isNotBlank(a.Product2.Addendum_Language__c)) {
                    return true;
                }
            }
        }
        
        return false;
    }
    // --------------------------------------------------------

    public class FlowInput {
        @InvocableVariable(label='Opportunity Record ID' required=true)
        public Id oppId;

        @InvocableVariable(label='Email Body (Rich Text)' required=true)
        public String emailBody;

        @InvocableVariable(label='Subject' required=true)
        public String subject;

        @InvocableVariable(label='To (Comma-separated)' required=true)
        public String toAddresses;

        @InvocableVariable(label='CC (Comma-separated)' required=false)
        public String ccAddresses;

        @InvocableVariable(label='BCC (Comma-separated)' required=false)
        public String bccAddresses;
        
        @InvocableVariable(label='Is Preview Mode?' required=false description='If true, saves the PDF to the Opportunity for previewing instead of sending an email.')
        public Boolean isPreview;
    }
    
    public class FlowOutput {
        @InvocableVariable(label='Content Document ID' description='The ID of the generated PDF File. Use this to preview the document in a Flow Screen.')
        public Id contentDocumentId;
    }

    private static List<String> parseEmailAddresses(String emailString) {
        List<String> validEmails = new List<String>();
        if (String.isNotBlank(emailString)) {
            String sanitizedString = emailString.replaceAll('[\\s\\p{Z}\\[\\]\\(\\)]+', '');
            for (String emailAddress : sanitizedString.split(',')) {
                emailAddress = emailAddress.replaceAll('\\p{C}', '');
                if (String.isNotBlank(emailAddress)) {
                    validEmails.add(emailAddress);
                }
            }
        }
        return validEmails;
    }

  @InvocableMethod(label='Order Confirmation Send' description='Generates PDF to preview, or sends Order Confirmation to Client.' category='Opportunity')
  public static List<FlowOutput> sendpdf(List<FlowInput> inputs) {
    List<FlowOutput> results = new List<FlowOutput>();

    for (FlowInput input : inputs) {
        FlowOutput result = new FlowOutput();
        Boolean isPreviewMode = (input.isPreview != null && input.isPreview);
        
        Opportunity opp = [SELECT Id, debug__c, RecordTypeId FROM Opportunity WHERE Id = :input.oppId LIMIT 1][0];
        String recordId = opp.id;
        String debugLog = '--- PDF GENERATION TELEMETRY ---\n'; 
        
        PageReference PDF;
        if (opp.RecordTypeId == '012Vb000007jxvxIAA' || opp.RecordTypeId == '012Vb00000CtrftIAB') {
            PDF = Page.OrderConfirmationDE;
        } else {
            PDF = Page.OrderConfirmationPDF;
        }
        PDF.getParameters().put('Id', recordId);
        
        debugLog += 'Target URL: ' + PDF.getUrl() + '\n';
        
        Blob b;
        try {
            if (Test.isRunningTest()) {
                b = Blob.valueOf('Unit.Test');
            } else {
                b = PDF.getContentAsPDF();
            }
            
            debugLog += 'PDF Blob Size: ' + b.size() + ' bytes.\n';
            if (b.size() < 5000) {
                debugLog += 'WARNING: Blob is suspiciously small. Salesforce likely redirected to a Login or Error page instead of rendering the document.\n';
            } else {
                debugLog += 'SUCCESS: Blob size looks normal.\n';
            }
        } catch(Exception e) {
            debugLog += 'PDF EXCEPTION: ' + e.getMessage() + '\n';
        }

        // --- BRANCH LOGIC: PREVIEW VS SEND ---
        if (isPreviewMode && b != null) {
            try {
                ContentVersion cv = new ContentVersion();
                cv.Title = 'Preview - Order Confirmation - ' + Datetime.now().format('MM-dd-yyyy HH:mm');
                cv.PathOnClient = 'OrderConfirmationPreview.pdf';
                cv.VersionData = b;
                cv.FirstPublishLocationId = recordId; // Attaches file to Opportunity
                insert cv;
                
                // Get the ContentDocumentId to pass back to the flow
                cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
                result.contentDocumentId = cv.ContentDocumentId;
                
                debugLog += 'PREVIEW MODE: PDF saved to Opportunity as File. Email aborted.\n';
            } catch(Exception e) {
                debugLog += 'PREVIEW EXCEPTION: ' + e.getMessage() + '\n';
            }
        } else if (!isPreviewMode && b != null) {
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setContentType('application/pdf');
            attachment.setFileName('OrderPDF.pdf');
            attachment.body = b;
            attachment.setInline(false);
              
            Messaging.SingleEmailMessage mail= new Messaging.SingleEmailMessage();
            
            List<String> toList = parseEmailAddresses(input.toAddresses);
            List<String> ccList = parseEmailAddresses(input.ccAddresses);
            List<String> bccList = parseEmailAddresses(input.bccAddresses);
            
            debugLog += 'Parsed To: ' + toList + '\nParsed CC: ' + ccList + '\nParsed BCC: ' + bccList + '\n';
            
            if (!toList.isEmpty()) mail.setToAddresses(toList);
            if (!ccList.isEmpty()) mail.setCcAddresses(ccList);
            if (!bccList.isEmpty()) mail.setBccAddresses(bccList);
            
            mail.setSubject(input.subject);
            mail.setHtmlBody(input.emailBody);
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
            
            try {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                debugLog += 'Email sent successfully.';
            } catch(Exception e) {
                debugLog += 'EMAIL SEND EXCEPTION: ' + e.getMessage() + '\n';
                Messaging.SingleEmailMessage ErrorEmail= new Messaging.SingleEmailMessage();
                ErrorEmail.setToAddresses(new String[] {'dchen@teamvelocitymarketing.com'});
                ErrorEmail.setSubject('Upsell Attachment Issue');
                ErrorEmail.setHtmlBody('Upsell Attachment Issue: '+e);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { ErrorEmail });
            }
        }
        // -------------------------------------
        
        opp.debug__c = debugLog;
        update opp;
        
        results.add(result);
    }
    return results;
  }
}