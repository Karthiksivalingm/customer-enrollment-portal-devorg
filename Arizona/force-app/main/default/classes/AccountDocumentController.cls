public with sharing class AccountDocumentController {

    private static final Set<String> ALLOWED_FIELDS = new Set<String>{
        'Authorizations__c',
        'PCSP__c'
    };

    public class StatusDocument {
        @AuraEnabled public String label;
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public String status;
        @AuraEnabled public Boolean isCompleted;

        public StatusDocument(String label, String fieldApiName, String rawStatus) {
            this.label = label;
            this.fieldApiName = fieldApiName;
            this.status = String.isBlank(rawStatus) ? 'Pending' : rawStatus;
            this.isCompleted = this.status == 'Completed';
        }
    }

    public class FileInfo {
        @AuraEnabled public String contentDocumentId;
        @AuraEnabled public String fileName;
        @AuraEnabled public String uploadSource;

        public FileInfo(String contentDocumentId, String fileName, String uploadSource) {
            this.contentDocumentId = contentDocumentId;
            this.fileName = fileName;
            this.uploadSource = uploadSource;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<StatusDocument> getAccountDocuments(Id accountId) {
        List<StatusDocument> results = new List<StatusDocument>();

        try {
            if (accountId == null) {
                return results;
            }

            Account acc = [
                SELECT Authorizations__c, PCSP__c
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
            ];

            if (acc == null) {
                return results;
            }

            results.add(new StatusDocument('Authorizations', 'Authorizations__c', acc.Authorizations__c));
            results.add(new StatusDocument('PCSP', 'PCSP__c', acc.PCSP__c));

            return results;

        } catch (QueryException e) {
            System.debug('QueryException in getAccountDocuments: ' + e.getMessage());
            throw new AuraHandledException('Error loading documents. Make sure Authorizations__c and PCSP__c fields exist on Account.');
        } catch (Exception e) {
            System.debug('Exception in getAccountDocuments: ' + e.getMessage());
            throw new AuraHandledException('Error loading documents: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, List<FileInfo>> getUploadedFileInfoForAccount(Id accountId) {
        Map<String, List<FileInfo>> result = new Map<String, List<FileInfo>>();

        try {
            if (accountId == null) {
                return result;
            }

            List<ContentDocumentLink> links = [
                SELECT ContentDocumentId,
                       ContentDocument.Title,
                       ContentDocument.CreatedDate,
                       ContentDocument.LatestPublishedVersion.Description
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :accountId
                ORDER BY ContentDocument.CreatedDate DESC
            ];

            for (ContentDocumentLink link : links) {
                String description = link.ContentDocument.LatestPublishedVersion != null
                    ? link.ContentDocument.LatestPublishedVersion.Description
                    : null;

                String fileTitle = link.ContentDocument.Title;
                String fieldApiName;
                String uploadSource;
                String fileName;

                if (String.isNotBlank(description) && description.contains('::')) {
                    Integer idx = description.indexOf('::');
                    fieldApiName = description.substring(0, idx);
                    String source = description.substring(idx + 2);
                    uploadSource = (source == 'internal' || source == 'portal') ? source : null;
                    fileName = fileTitle;
                } else {
                    continue;
                }

                if (!result.containsKey(fieldApiName)) {
                    result.put(fieldApiName, new List<FileInfo>());
                }

                result.get(fieldApiName).add(new FileInfo(link.ContentDocumentId, fileName, uploadSource));
            }

            return result;

        } catch (Exception e) {
            System.debug('Exception in getUploadedFileInfoForAccount: ' + e.getMessage());
            throw new AuraHandledException('Error loading files: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void uploadAccountDocument(
        Id accountId,
        String fieldApiName,
        String base64Data,
        String fileName,
        String uploadSource
    ) {
        try {
            if (accountId == null || String.isBlank(fieldApiName) || 
                String.isBlank(base64Data) || String.isBlank(fileName)) {
                throw new AuraHandledException('Missing required parameters.');
            }

            if (!ALLOWED_FIELDS.contains(fieldApiName)) {
                throw new AuraHandledException('Invalid field: ' + fieldApiName);
            }

            String source = (uploadSource == 'portal') ? 'portal' : 'internal';

            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = fileName;
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            cv.Description = fieldApiName + '::' + source;

            insert cv;

            cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cv.ContentDocumentId;
            cdl.LinkedEntityId = accountId;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';

            insert cdl;

            Account acc = new Account(Id = accountId);
            acc.put(fieldApiName, 'Pending');
            update acc;

        } catch (AuraHandledException e) {
            throw e;
        } catch (DmlException e) {
            System.debug('DmlException in uploadAccountDocument: ' + e.getMessage());
            throw new AuraHandledException('Error uploading file: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('Exception in uploadAccountDocument: ' + e.getMessage());
            throw new AuraHandledException('Error uploading file: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateAccountDocumentStatus(
        Id accountId,
        String fieldApiName,
        String newStatus
    ) {
        try {
            if (accountId == null || String.isBlank(fieldApiName) || String.isBlank(newStatus)) {
                throw new AuraHandledException('Missing required parameters.');
            }

            if (!ALLOWED_FIELDS.contains(fieldApiName)) {
                throw new AuraHandledException('Invalid field: ' + fieldApiName);
            }

            Account acc = new Account(Id = accountId);
            acc.put(fieldApiName, newStatus);
            update acc;

        } catch (AuraHandledException e) {
            throw e;
        } catch (DmlException e) {
            System.debug('DmlException in updateAccountDocumentStatus: ' + e.getMessage());
            throw new AuraHandledException('Error updating status: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('Exception in updateAccountDocumentStatus: ' + e.getMessage());
            throw new AuraHandledException('Error updating status: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void deleteAccountDocument(
        Id accountId,
        Id contentDocumentId,
        String fieldApiName
    ) {
        try {
            if (accountId == null || contentDocumentId == null || String.isBlank(fieldApiName)) {
                throw new AuraHandledException('Missing required parameters.');
            }

            if (!ALLOWED_FIELDS.contains(fieldApiName)) {
                throw new AuraHandledException('Invalid field: ' + fieldApiName);
            }

            List<ContentDocumentLink> links = [
                SELECT Id
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :accountId
                AND ContentDocumentId = :contentDocumentId
                LIMIT 1
            ];

            if (!links.isEmpty()) {
                delete links;
            }

            Integer remainingFiles = [
                SELECT COUNT()
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :accountId
                AND ContentDocument.LatestPublishedVersion.Description LIKE :('%' + fieldApiName + '::%')
            ];

            if (remainingFiles == 0) {
                Account acc = new Account(Id = accountId);
                acc.put(fieldApiName, null);
                update acc;
            }

        } catch (AuraHandledException e) {
            throw e;
        } catch (DmlException e) {
            System.debug('DmlException in deleteAccountDocument: ' + e.getMessage());
            throw new AuraHandledException('Error deleting file: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('Exception in deleteAccountDocument: ' + e.getMessage());
            throw new AuraHandledException('Error deleting file: ' + e.getMessage());
        }
    }
}