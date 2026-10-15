public with sharing class GuestApprovalController {
/*
    // 🔹 Get Contacts (Requester Page)
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContacts() {
        return [
            SELECT Id, Name, Email, Title, Approval_Status__c
            FROM Contact
            LIMIT 50
        ];
    }

    // 🔹 Send for Approval
    @AuraEnabled
    public static void sendForApproval(List<Id> recordIds) {

        if (recordIds == null || recordIds.isEmpty()) return;

        List<Contact> contacts = [
            SELECT Id, Name, Email
            FROM Contact
            WHERE Id IN :recordIds
        ];

        for (Contact c : contacts) {
            c.Approval_Status__c = 'Pending';
        }
        update contacts;

        sendApprovalEmail(recordIds, contacts);
    }

    // 🔹 Bulk Approve / Reject
    @AuraEnabled
    public static void updateStatus(List<Id> recordIds, String status) {

        if (recordIds == null || recordIds.isEmpty()) return;

        List<Contact> contacts = [
            SELECT Id, Approval_Status__c
            FROM Contact
            WHERE Id IN :recordIds
        ];

        for (Contact c : contacts) {
            c.Approval_Status__c = status;
        }

        update contacts;
    }

    // 🔹 EMAIL WITH IMAGE
    private static void sendApprovalEmail(List<Id> recordIds, List<Contact> contacts) {

        String body = '<h2>Guest Approval Request</h2><br/>';

        // ✅ FIX: Convert List → Set
        Map<Id, ContentVersion> imageMap = getImages(new Set<Id>(recordIds));

        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();

        for (Contact c : contacts) {

            body += '<div style="margin-bottom:15px;">';
            body += '<b>' + c.Name + '</b><br/>';
            body += c.Email + '<br/>';

            if (imageMap.containsKey(c.Id)) {

                ContentVersion cv = imageMap.get(c.Id);

                String imageUrl = baseUrl + '/sfc/servlet.shepherd/version/download/' + cv.Id;

                // Show image
                body += '<img src="' + imageUrl + '" width="100"/><br/>';

                // Attach image
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(cv.Title);
                efa.setBody(cv.VersionData);

                attachments.add(efa);
            }

            body += '</div><hr/>';
        }

        body += '<br/><a href="https://qatarmuseums2--qatarsand.sandbox.lightning.force.com/lightning/cmp/c__GuestApprovalPage">';
        body += 'Click here to Review & Approve</a>';

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        // Send to logged-in user (testing)
        mail.setToAddresses(new String[] { UserInfo.getUserEmail() });

        mail.setSubject('Guest Approval Request');
        mail.setHtmlBody(body);
        mail.setFileAttachments(attachments);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    // 🔹 Get Pending Contacts (with image URL)
    @AuraEnabled(cacheable=true)
    public static List<Contact> getPendingContacts() {

        List<Contact> contacts = [
            SELECT Id, Name, Email, Approval_Status__c
            FROM Contact
            WHERE Approval_Status__c = 'Pending'
        ];

        Map<Id, ContentVersion> imageMap = getImages(
            new Map<Id, Contact>(contacts).keySet()
        );

        String baseUrl = URL.getOrgDomainUrl().toExternalForm();

        for (Contact c : contacts) {
            if (imageMap.containsKey(c.Id)) {
                String url = baseUrl + '/sfc/servlet.shepherd/version/download/' + imageMap.get(c.Id).Id;
                c.put('ImageUrl', url);
            }
        }

        return contacts;
    }

    // 🔹 Update Approval from UI
    @AuraEnabled
    public static void updateApproval(Map<Id, String> decisions) {

        List<Contact> updateList = new List<Contact>();

        for (Id conId : decisions.keySet()) {
            updateList.add(new Contact(
                Id = conId,
                Approval_Status__c = decisions.get(conId)
            ));
        }

        update updateList;
    }

    // 🔹 COMMON METHOD: Get Images (SET)
    private static Map<Id, ContentVersion> getImages(Set<Id> recordIds) {

        Map<Id, ContentVersion> result = new Map<Id, ContentVersion>();

        if (recordIds == null || recordIds.isEmpty()) return result;

        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :recordIds
        ];

        Map<Id, Id> contactToDoc = new Map<Id, Id>();

        for (ContentDocumentLink l : links) {
            contactToDoc.put(l.LinkedEntityId, l.ContentDocumentId);
        }

        if (contactToDoc.isEmpty()) return result;

        List<ContentVersion> versions = [
            SELECT Id, Title, VersionData, ContentDocumentId
            FROM ContentVersion
            WHERE ContentDocumentId IN :contactToDoc.values()
            AND IsLatest = true
        ];

        Map<Id, ContentVersion> docToVersion = new Map<Id, ContentVersion>();

        for (ContentVersion cv : versions) {
            docToVersion.put(cv.ContentDocumentId, cv);
        }

        for (Id contactId : contactToDoc.keySet()) {
            Id docId = contactToDoc.get(contactId);
            if (docToVersion.containsKey(docId)) {
                result.put(contactId, docToVersion.get(docId));
            }
        }

        return result;
    }

    // 🔹 OPTIONAL: Overloaded method (List support)
    private static Map<Id, ContentVersion> getImages(List<Id> recordIds) {
        return getImages(new Set<Id>(recordIds));
    }*/
}