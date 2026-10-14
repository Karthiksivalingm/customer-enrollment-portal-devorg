// NEW CHANGE: Enforcing sharing
public inherited sharing class TypeFormFileFetcher {

    private static final String ACCESS_TOKEN = getAccessToken();

    public class FileResult {
        public String leadId;
        public String formId;
        public List<Blob> fileBlobs;
        public List<String> fileNames;
        public Map<String, Object> typeformResponse;
        
        public FileResult(String leadId, String formId) {
            this.leadId = leadId;
            this.formId = formId;
            fileBlobs = new List<Blob>();
            fileNames = new List<String>();
        }
    }

    public static void fetchAndSaveFiles(List<TypeFormFileFetcherInvoker.Input> inputs) {

        List<FileResult> results = new List<FileResult>();
        List<Store__c> storesToInsert = new List<Store__c>();

        Http http = new Http();

        // ================================
        // NEW CHANGE: Move SOQL outside loop
        // ================================
        Set<Id> leadIds = new Set<Id>();
        for (TypeFormFileFetcherInvoker.Input input : inputs) {
            if (input.leadId != null) {
                leadIds.add(input.leadId);
            }
        }

        Map<Id, Lead> leadMap = new Map<Id, Lead>(
            [SELECT Id, Email FROM Lead WHERE Id IN :leadIds]
        );
        // ================================

        for (TypeFormFileFetcherInvoker.Input input : inputs) {

            FileResult fr = new FileResult(input.leadId, input.formId);

            Datetime twoHoursAgo = Datetime.now().addHours(-2);
            String isoSince = twoHoursAgo.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');

            HttpRequest req = new HttpRequest();
            req.setEndpoint(
                'https://api.typeform.com/forms/' +
                input.formId +
                '/responses?since=' +
                EncodingUtil.urlEncode(isoSince, 'UTF-8')
            );

            req.setMethod('GET');
            req.setHeader('Authorization', ACCESS_TOKEN);

            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {

                Map<String, Object> parsed =
                    (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                List<Object> items = (List<Object>) parsed.get('items');

                // ================================
                // NEW CHANGE: Using email from Map instead of SOQL
                // ================================
                String leadEmail =
                    leadMap.containsKey((Id)input.leadId)
                    ? leadMap.get((Id)input.leadId).Email
                    : null;

                Map<String, Object> latestResponse =
                    findLatestResponseWithMatchingEmail(items, leadEmail);
                // ================================

                ExternalStoreCreation.createStoresFromTypeformResponse(
                    latestResponse,
                    input.leadId,
                    storesToInsert,
                    input.formId
                );

                if (items != null && !items.isEmpty()) {

                    if (latestResponse != null) {

                        fr.typeformResponse = latestResponse;

                        Map<String, String> filesMap = extractFiles(latestResponse);

                        for (String fileUrl : filesMap.keySet()) {

                            HttpRequest fileReq = new HttpRequest();
                            fileReq.setEndpoint(fileUrl);
                            fileReq.setMethod('GET');
                            fileReq.setHeader('Authorization', ACCESS_TOKEN);

                            HttpResponse fileRes = http.send(fileReq);

                            if (fileRes.getStatusCode() == 200) {

                                fr.fileBlobs.add(fileRes.getBodyAsBlob());
                                fr.fileNames.add(filesMap.get(fileUrl));
                            }
                        }
                    }
                }

            } else {

                System.debug('Typeform error: ' + res.getStatus());

                APILogger.logCalloutError(
                    'Typeform Response Fetch - TypeFormFileFetcher.fetchAndSaveFiles',
                    res.getStatusCode(),
                    req.getBody(),
                    res.getBody(),
                    null,
                    input.leadId,
                    'API Errors'
                );
            }

            results.add(fr);
        }

        List<ContentVersion> allContentVersions = new List<ContentVersion>();
        List<String> leadIdMapping = new List<String>();

        for (FileResult fr : results) {

            if (fr.fileBlobs != null && fr.fileBlobs.size() > 0) {

                for (Integer i = 0; i < fr.fileBlobs.size(); i++) {

                    ContentVersion cv = new ContentVersion();

                    String fileName = fr.leadId + '_' + fr.fileNames[i];

                    cv.Title = fileName;
                    cv.PathOnClient = '/' + fileName;
                    cv.VersionData = fr.fileBlobs[i];

                    allContentVersions.add(cv);
                    leadIdMapping.add(fr.leadId);
                }
            }

            if (fr.typeformResponse != null) {

                ContentVersion jsonFile = new ContentVersion();

                String jsonFileName =
                    'Typeform_Response_' +
                    fr.formId +
                    '_' +
                    DateTime.now().format('yyyyMMdd_HHmmss') +
                    '.json';

                jsonFile.Title = jsonFileName;
                jsonFile.PathOnClient = '/' + jsonFileName;
                jsonFile.VersionData =
                    Blob.valueOf(JSON.serializePretty(fr.typeformResponse));

                allContentVersions.add(jsonFile);
                leadIdMapping.add(fr.leadId);
            }
        }

        if (!allContentVersions.isEmpty()) {

            Database.SaveResult[] cvResults =
                Database.insert(allContentVersions, false);

            Map<Id, String> cvIdToLeadId = new Map<Id, String>();

            for (Integer i = 0; i < cvResults.size(); i++) {

                if (cvResults[i].isSuccess()) {

                    cvIdToLeadId.put(cvResults[i].getId(), leadIdMapping[i]);
                }
            }

            List<ContentVersion> insertedCVs = [
                SELECT Id, ContentDocumentId
                FROM ContentVersion
                WHERE Id IN :cvIdToLeadId.keySet()
            ];

            List<ContentDocumentLink> linksToInsert =
                new List<ContentDocumentLink>();

            for (ContentVersion cv : insertedCVs) {

                String leadId = cvIdToLeadId.get(cv.Id);

                ContentDocumentLink cdl = new ContentDocumentLink();

                cdl.ContentDocumentId = cv.ContentDocumentId;
                cdl.LinkedEntityId = leadId;
                cdl.ShareType = 'V';
                cdl.Visibility = 'AllUsers';

                linksToInsert.add(cdl);
            }

            if (!linksToInsert.isEmpty()) {
                insert linksToInsert;
            }
        }

        if (!storesToInsert.isEmpty()) {
            insert storesToInsert;
        }
    }

    // =====================================================
    // NEW CHANGE: Removed SOQL from this method
    // =====================================================
    private static Map<String, Object> findLatestResponseWithMatchingEmail(
        List<Object> items,
        String leadEmail
    ) {

        if (leadEmail == null) {
            return null;
        }

        for (Object itemObj : items) {

            Map<String, Object> item = (Map<String, Object>) itemObj;

            List<Object> answers = (List<Object>) item.get('answers');

            for (Object answerObj : answers) {

                Map<String, Object> answer =
                    (Map<String, Object>) answerObj;

                if (answer.containsKey('email') &&
                    answer.get('email') == leadEmail) {

                    return item;
                }
            }
        }

        return null;
    }

    private static Map<String, String> extractFiles(
        Map<String, Object> response
    ) {

        Map<String, String> fileUrlToName = new Map<String, String>();

        List<Object> answers = (List<Object>) response.get('answers');

        for (Object answerObj : answers) {

            Map<String, Object> answer =
                (Map<String, Object>) answerObj;

            if (answer.containsKey('file_url')) {

                String fileUrl = (String) answer.get('file_url');

                String[] parts = fileUrl.split('/');

                String fileName =
                    'Typeform_File_' + parts[parts.size() - 1];

                fileUrlToName.put(fileUrl, fileName);
            }
        }

        return fileUrlToName;
    }

    private static String getAccessToken() {

        Typeform_Config__c config =
            Typeform_Config__c.getOrgDefaults();

        return 'Bearer ' + config.Personal_Access_Token__c;
    }
}