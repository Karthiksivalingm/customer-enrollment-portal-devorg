public class SendAttachmentHandler {
    
    @RemoteAction
    public static string SendAttachment(String sEmailAddress, String OpportunityID){
        String sMessage='';
        try{            
            Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
            // Replace Visualforce(AccountDetails) page with your visualforce page
            sMessage='SUCCESS';
            
            PageReference pref = page.PDF_Generator_Beta;
            pref.getParameters().put('id', OpportunityID);
            pref.setRedirect(true);
            
            try{
                Blob b = pref.getContent();
                attach.setBody(b);}
            catch(Exception x){}
            
            attach.setFileName('Order Details.pdf');
            semail.setSubject('Order Details');
            semail.setToAddresses(new List<String>{sEmailAddress});
            semail.setPlainTextBody('Please find the attached deal details');
            semail.setFileAttachments(new Messaging.EmailFileAttachment[]{attach});
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{semail});        
        }
        catch(Exception ex){
            sMessage=ex.getMessage()+'\n'+ex.getLineNumber()+'\n'+ex.getCause();
        }
        return sMessage;
    }
 }