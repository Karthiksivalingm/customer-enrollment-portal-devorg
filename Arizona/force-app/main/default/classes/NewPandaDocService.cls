/**
 * Service class for PandaDoc API integration
 * Handles document creation and linking for any Salesforce object
 */
public with sharing class NewPandaDocService {
    
    @TestVisible
    private static final String PANDADOC_METADATA_KEY = 'salesforce.{0}_id';
    
    @TestVisible
    private static final String CREATE_DOCUMENT_ENDPOINT = 'callout:PandaDoc/v1/documents';
    
    @TestVisible
    private static final String CREATE_LINKED_OBJECT_ENDPOINT_TEMPLATE = 'callout:PandaDoc/v1/documents/{0}/linked-objects';

    /**
     * Creates a new document from a PandaDoc template
     * Works with Contact, Quote, Opportunity, or any standard/custom object
     */
    public static String createNewDocumentFromTemplate(Id recordId, String templateId) {
        
        if (recordId == null) {
            throw new NewPandaDocServiceException('recordId missing!');
        }
        if (String.isBlank(templateId)) {
            throw new NewPandaDocServiceException('templateId missing!');
        }

        // Get the object type and retrieve the record data
        String objectApiName = recordId.getSobjectType().getDescribe().getName();
        System.debug('Creating document for object type: ' + objectApiName);
        
        // Retrieve contact data if Contact object
        Map<String, Object> contactData = new Map<String, Object>();
        if (objectApiName == 'Contact') {
            Contact contact = [
                SELECT Id, FirstName, LastName, Email, Phone, Title, Account.Name
                FROM Contact
                WHERE Id = :recordId
                LIMIT 1
            ];
            contactData.put('firstName', contact.FirstName);
            contactData.put('lastName', contact.LastName);
            contactData.put('email', contact.Email);
            contactData.put('phone', contact.Phone);
            contactData.put('title', contact.Title);
            contactData.put('accountName', contact.Account?.Name);
        }

        // Build the request
        PandaDocCreateDocumentRequestWrapper createDocRequestWrapper = new PandaDocCreateDocumentRequestWrapper();
        
        // Document name
        createDocRequestWrapper.name = 'Document from ' + objectApiName;
        createDocRequestWrapper.template_uuid = templateId;

        // Metadata - important for linking
        String metadataKey = String.format(PANDADOC_METADATA_KEY, new List<String>{ objectApiName.toLowerCase() });
        createDocRequestWrapper.metadata = new Map<String, Object>{
            metadataKey => String.valueOf(recordId)
        };

        // Recipients - set from contact if available
        PandaDocCreateDocumentRequestWrapper.RecipientWrapper recipient = new PandaDocCreateDocumentRequestWrapper.RecipientWrapper();
        if (objectApiName == 'Contact') {
            Contact contact = [SELECT FirstName, LastName, Email FROM Contact WHERE Id = :recordId ];
            recipient.email = contact.Email;
            recipient.first_name = contact.FirstName;
            recipient.last_name = contact.LastName;
        } else {
            // Default recipient
            recipient.email = 'noreply@salesforce.com';
            recipient.first_name = 'Salesforce';
            recipient.last_name = 'User';
        }
        createDocRequestWrapper.recipients = new List<PandaDocCreateDocumentRequestWrapper.RecipientWrapper>{ recipient };

        // Add tokens/fields for Contact
        if (objectApiName == 'Contact') {
            Contact contact = [SELECT FirstName, LastName, Email, Phone, Title, Account.Name FROM Contact WHERE Id = :recordId LIMIT 1];
            
            // Tokens
            createDocRequestWrapper.tokens = new List<PandaDocCreateDocumentRequestWrapper.TokenWrapper>();
            
            PandaDocCreateDocumentRequestWrapper.TokenWrapper firstNameToken = new PandaDocCreateDocumentRequestWrapper.TokenWrapper();
            firstNameToken.name = 'FirstName';
            firstNameToken.value = contact.FirstName;
            createDocRequestWrapper.tokens.add(firstNameToken);
            
            PandaDocCreateDocumentRequestWrapper.TokenWrapper lastNameToken = new PandaDocCreateDocumentRequestWrapper.TokenWrapper();
            lastNameToken.name = 'LastName';
            lastNameToken.value = contact.LastName;
            createDocRequestWrapper.tokens.add(lastNameToken);
            
            // Fields
            createDocRequestWrapper.fields = new Map<String, Map<String, Object>>{
                'FirstName' => new Map<String, Object>{ 'value' => contact.FirstName },
                'LastName' => new Map<String, Object>{ 'value' => contact.LastName },
                'Email' => new Map<String, Object>{ 'value' => contact.Email },
                'Phone' => new Map<String, Object>{ 'value' => contact.Phone },
                'Title' => new Map<String, Object>{ 'value' => contact.Title },
                'AccountName' => new Map<String, Object>{ 'value' => contact.Account?.Name }
            };
        }

        // Serialize the request
        String createDocRequestBody = JSON.serialize(createDocRequestWrapper, true).replaceAll('default_x', 'default');
        
        System.debug('Request Body: ' + createDocRequestBody);

        // Make the HTTP request
        HttpRequest createDocRequest = new HttpRequest();
        createDocRequest.setEndpoint(CREATE_DOCUMENT_ENDPOINT);
        createDocRequest.setMethod('POST');
        createDocRequest.setHeader('Content-Type', 'application/json');
        createDocRequest.setBody(createDocRequestBody);
        createDocRequest.setTimeout(60000);

        HttpResponse createDocResponse = sendRequestToPandaDoc(createDocRequest);
        String createDocResponseBody = createDocResponse.getBody();
        
        System.debug('Response Body: ' + createDocResponseBody);

        // Parse response
        Map<String, Object> createDocResponseMap = (Map<String, Object>) JSON.deserializeUntyped(createDocResponseBody);
        String documentUuid = (String) createDocResponseMap.get('id');
        String documentName = (String) createDocResponseMap.get('name');

        // Create PandaDoc document record in Salesforce
        pandadoc__PandaDocDocument__c document = new pandadoc__PandaDocDocument__c();
        document.Name = documentName;
        document.pandadoc__UUID__c = documentUuid;
        document.pandadoc__Template_Id__c = templateId;
        document.pandadoc__Status__c = 'document.draft';
        document.pandadoc__Editor_Version__c = 'EV2';

        // Link to the appropriate object
        if (objectApiName == 'Opportunity') {
            document.pandadoc__Opportunity__c = recordId;
        } else if (objectApiName == 'Contact') {
            // If using a custom field for Contact, uncomment and update field name
            // document.Contact_ID__c = recordId;
            document.pandadoc__Custom_Object_Id__c = recordId;
        } else {
            document.pandadoc__Custom_Object_Id__c = recordId;
        }

        insert document;
        System.debug('PandaDoc document record created: ' + document.Id);
        
        return documentUuid;
    }

    /**
     * Links the created PandaDoc document with the Salesforce record
     */
    public static void linkDocumentToSalesforce(Id recordId, String documentUuid) {
        
        if (recordId == null) {
            throw new NewPandaDocServiceException('recordId missing!');
        }
        if (String.isBlank(documentUuid)) {
            throw new NewPandaDocServiceException('documentUuid missing!');
        }

        String objectApiName = recordId.getSobjectType().getDescribe().getName();
        System.debug('Linking document to ' + objectApiName + ': ' + recordId);
        
        String linkEndpoint = String.format(CREATE_LINKED_OBJECT_ENDPOINT_TEMPLATE, new List<String>{ documentUuid });

        Map<String, Object> linkRequestMap = new Map<String, Object>{
            'provider' => 'salesforce-oauth2',
            'entity_type' => objectApiName.toLowerCase(),
            'entity_id' => String.valueOf(recordId)
        };

        HttpRequest linkRequest = new HttpRequest();
        linkRequest.setEndpoint(linkEndpoint);
        linkRequest.setMethod('POST');
        linkRequest.setHeader('Content-Type', 'application/json');
        linkRequest.setBody(JSON.serialize(linkRequestMap));

        System.debug('Link Request Body: ' + JSON.serialize(linkRequestMap));
        
        sendRequestToPandaDoc(linkRequest);
        System.debug('Document linked successfully');
    }

    /**
     * Sends HTTP request to PandaDoc API
     */
  private static HttpResponse sendRequestToPandaDoc(HttpRequest req) {
    Http http = new Http();
    HttpResponse res = http.send(req);

    Integer responseStatusCode = res.getStatusCode();
    String responseBody = res.getBody();
    
    System.debug('PandaDoc API Response Status: ' + responseStatusCode);
    System.debug('PandaDoc API Response Body: ' + responseBody);

    if (responseStatusCode != 200 && responseStatusCode != 201) {
        String errorMessage = 'Callout error HTTP Status Code: ' + String.valueOf(responseStatusCode);
        if (String.isNotBlank(responseBody)) {
            errorMessage += ', Body: ' + responseBody;
        }
        System.debug(errorMessage);  // ✅ FIXED: Changed from System.error() to System.debug()
        throw new NewPandaDocServiceException(errorMessage);
    }

    return res;
}
    public class NewPandaDocServiceException extends Exception {
    }
}