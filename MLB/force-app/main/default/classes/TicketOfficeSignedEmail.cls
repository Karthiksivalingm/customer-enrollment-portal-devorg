/**
 * Sends the Ticket Office Agreement Details email for a customer-signed Adobe Sign agreement, with the signed PDF
 * attached. Called by the Adobe_Agreement_Notify_Ticket_Office flow for the Signed event only (every other event still
 * uses the Ticket_Office_Agreement_Details email alert).
 *
 * Adobe attaches "<agreement name> - signed.pdf" to the agreement a few seconds around the status change, so the email
 * is sent from a delayed Queueable that waits for the file and retries a few times before sending without it.
 * Recipients match the email alert: Ticket Office (Custom Label Ticket_Office_Email) and the Opportunity Owner Manager,
 * reply-to the Opportunity owner.
 */
public without sharing class TicketOfficeSignedEmail implements Queueable {

    @TestVisible private static final Integer MAX_ATTEMPTS = 4;
    @TestVisible private static final Integer RETRY_DELAY_MINUTES = 2;
    @TestVisible private static List<Messaging.SingleEmailMessage> sentEmails = new List<Messaging.SingleEmailMessage>();

    public class Request {
        @InvocableVariable(label='Adobe Sign Agreement Id' required=true)
        public Id agreementId;
        @InvocableVariable(label='Opportunity Id' required=true)
        public Id opportunityId;
    }

    @InvocableMethod(label='Send Ticket Office Signed Email' description='Emails the Ticket Office the agreement details with the signed PDF attached.' category='Ticket Office')
    public static void send(List<Request> requests) {
        List<Request> work = new List<Request>();
        for (Request r : requests) {
            if (r != null && r.agreementId != null && r.opportunityId != null) {
                work.add(r);
            }
        }
        if (!work.isEmpty()) {
            enqueue(new TicketOfficeSignedEmail(work, 1), 1);
        }
    }

    private final List<Request> requests;
    private final Integer attempt;

    @TestVisible
    private TicketOfficeSignedEmail(List<Request> requests, Integer attempt) {
        this.requests = requests;
        this.attempt = attempt;
    }

    public void execute(QueueableContext ctx) {
        Set<Id> agreementIds = new Set<Id>();
        for (Request r : requests) {
            agreementIds.add(r.agreementId);
        }
        Map<Id, Id> signedPdfByAgreement = findSignedPdfs(agreementIds);

        List<Request> waiting = new List<Request>();
        List<Request> ready = new List<Request>();
        for (Request r : requests) {
            if (signedPdfByAgreement.containsKey(r.agreementId) || attempt >= MAX_ATTEMPTS || Test.isRunningTest()) {
                ready.add(r);
            } else {
                waiting.add(r);
            }
        }
        if (!ready.isEmpty()) {
            sendEmails(ready, signedPdfByAgreement);
        }
        if (!waiting.isEmpty()) {
            enqueue(new TicketOfficeSignedEmail(waiting, attempt + 1), RETRY_DELAY_MINUTES);
        }
    }

    /** Latest "... signed.pdf" File on each agreement -> its ContentVersion Id. */
    @TestVisible
    private static Map<Id, Id> findSignedPdfs(Set<Id> agreementIds) {
        Map<Id, Id> result = new Map<Id, Id>();
        for (ContentDocumentLink link : [
            SELECT LinkedEntityId, ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :agreementIds
              AND ContentDocument.FileExtension = 'pdf'
              AND ContentDocument.Title LIKE '%signed%'
            ORDER BY ContentDocument.CreatedDate DESC
        ]) {
            if (!result.containsKey(link.LinkedEntityId)) {
                result.put(link.LinkedEntityId, link.ContentDocument.LatestPublishedVersionId);
            }
        }
        return result;
    }

    private static void sendEmails(List<Request> ready, Map<Id, Id> signedPdfByAgreement) {
        List<EmailTemplate> templates = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Ticket_Office_Agreement_Details' LIMIT 1];
        if (templates.isEmpty()) {
            return;
        }
        Set<Id> oppIds = new Set<Id>();
        for (Request r : ready) {
            oppIds.add(r.opportunityId);
        }
        Map<Id, Opportunity> opps = new Map<Id, Opportunity>([
            SELECT Id, OwnerId, Owner.Email, Opportunity_Owner_Manager__c, Opportunity_Owner_Manager__r.Email,
                   Opportunity_Owner_Manager__r.IsActive
            FROM Opportunity
            WHERE Id IN :oppIds
        ]);
        String ticketOffice = System.Label.Ticket_Office_Email;

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Request r : ready) {
            Opportunity o = opps.get(r.opportunityId);
            if (o == null) {
                continue;
            }
            List<String> toAddresses = new List<String>();
            if (String.isNotBlank(ticketOffice)) {
                toAddresses.add(ticketOffice.trim());
            }
            if (o.Opportunity_Owner_Manager__c != null && o.Opportunity_Owner_Manager__r.IsActive
                    && String.isNotBlank(o.Opportunity_Owner_Manager__r.Email)) {
                toAddresses.add(o.Opportunity_Owner_Manager__r.Email);
            }
            if (toAddresses.isEmpty()) {
                continue;
            }
            Messaging.SingleEmailMessage rendered = Messaging.renderStoredEmailTemplate(templates[0].Id, o.OwnerId, o.Id);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAddresses);
            mail.setSubject(rendered.getSubject());
            mail.setHtmlBody(rendered.getHtmlBody());
            mail.setPlainTextBody(rendered.getPlainTextBody());
            if (String.isNotBlank(o.Owner.Email)) {
                mail.setReplyTo(o.Owner.Email);
            }
            mail.setSaveAsActivity(false);
            Id pdfVersionId = signedPdfByAgreement.get(r.agreementId);
            if (pdfVersionId != null) {
                mail.setEntityAttachments(new List<Id>{ pdfVersionId });
            }
            emails.add(mail);
        }
        if (emails.isEmpty()) {
            return;
        }
        if (Test.isRunningTest()) {
            sentEmails.addAll(emails);
        } else {
            Messaging.sendEmail(emails, false);
        }
    }

    private static void enqueue(TicketOfficeSignedEmail job, Integer delayMinutes) {
        if (Test.isRunningTest() && job.attempt > 1) {
            return; // chained Queueables are not allowed in tests
        }
        AsyncOptions options = new AsyncOptions();
        options.MinimumQueueableDelayInMinutes = delayMinutes;
        System.enqueueJob(job, options);
    }
}
