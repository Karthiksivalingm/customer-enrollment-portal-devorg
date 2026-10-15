/**
 * Controller class for PandaDoc document creation
 * Handles Contact, Quote, Opportunity, and custom objects
 */
public with sharing class NewPandaDocController {
    
    @AuraEnabled
    public static String createNewDocumentFromTemplate(Id recordId, String templateId) {
        try {
            // Validate inputs
            if (recordId == null) {
                throw new AuraHandledException('Record ID is missing. Please make sure you are on a valid record.');
            }
            if (String.isBlank(templateId)) {
                throw new AuraHandledException('Template ID is missing. Please configure the template ID in the LWC.');
            }
            
            System.debug('Creating document for record: ' + recordId + ' with template: ' + templateId);
            
            // Call the service method
            String result = NewPandaDocService.createNewDocumentFromTemplate(recordId, templateId);
            System.debug('Document created successfully: ' + result);
            return result;
            
        } catch (AuraHandledException e) {
            System.debug('AuraHandled Exception: ' + e.getMessage());
            throw e;
        } catch (Exception e) {
            System.debug('ERROR in createNewDocumentFromTemplate: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error creating document: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void linkDocumentToSalesforce(Id recordId, String documentUuid) {
        try {
            if (recordId == null) {
                throw new AuraHandledException('Record ID is missing.');
            }
            if (String.isBlank(documentUuid)) {
                throw new AuraHandledException('Document UUID is missing.');
            }
            
            System.debug('Linking document: ' + documentUuid + ' to record: ' + recordId);
            NewPandaDocService.linkDocumentToSalesforce(recordId, documentUuid);
            System.debug('Document linked successfully');
            
        } catch (AuraHandledException e) {
            System.debug('AuraHandled Exception: ' + e.getMessage());
            throw e;
        } catch (Exception e) {
            System.debug('ERROR in linkDocumentToSalesforce: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error linking document: ' + e.getMessage());
        }
    }
}