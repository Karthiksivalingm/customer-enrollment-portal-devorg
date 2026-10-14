public class TypeformBackfill implements Database.Batchable<String>,
                                         Database.AllowsCallouts,
                                         Database.Stateful {

    private String formId;
    private Map<String, String> emailToLeadId;
    private List<String> emails;

    public TypeformBackfill(String formId, Map<String, String> emailToLeadId) {
        this.formId        = formId;
        this.emailToLeadId = emailToLeadId;
        this.emails        = new List<String>(emailToLeadId.keySet());
    }

    public List<String> start(Database.BatchableContext bc) {
        return emails;
    }

    public void execute(Database.BatchableContext bc, List<String> scope) {
        Typeform_Config__c config = Typeform_Config__c.getOrgDefaults();
        String token = 'Bearer ' + config.Personal_Access_Token__c;

        Http http = new Http();
        List<ContentVersion> allContentVersions = new List<ContentVersion>();
        List<String> leadIdMapping = new List<String>();

        // Search Typeform directly by email using query param
        for (String email : scope) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(
                'https://api.typeform.com/forms/' + formId +
                '/responses?query=' + EncodingUtil.urlEncode(email, 'UTF-8') +
                '&page_size=5'
            );
            req.setMethod('GET');
            req.setHeader('Authorization', token);

            HttpResponse res = http.send(req);
            System.debug('Query for ' + email + ' status: ' + res.getStatusCode());

            if (res.getStatusCode() != 200) {
                System.debug('ERROR for ' + email + ': ' + res.getBody());
                continue;
            }

            Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> items = (List<Object>) parsed.get('items');

            if (items == null || items.isEmpty()) {
                System.debug('No response found for: ' + email);
                continue;
            }

            // Take the latest response for this email
            Map<String, Object> matchedResponse = (Map<String, Object>) items[0];
            String leadId = emailToLeadId.get(email);
            System.debug('Matched: ' + leadId + ' - ' + email);

            // Save JSON
            ContentVersion jsonFile = new ContentVersion();
            jsonFile.Title = 'Typeform_' + formId + '_' + leadId + '.json';
            jsonFile.PathOnClient = '/' + jsonFile.Title;
            jsonFile.VersionData = Blob.valueOf(JSON.serializePretty(matchedResponse));
            allContentVersions.add(jsonFile);
            leadIdMapping.add(leadId);

            // Download attachments
            List<Object> answers = (List<Object>) matchedResponse.get('answers');
            if (answers == null) continue;
            for (Object answerObj : answers) {
                Map<String, Object> answer = (Map<String, Object>) answerObj;
                if (!answer.containsKey('file_url')) continue;
                String fileUrl = (String) answer.get('file_url');
                String[] parts = fileUrl.split('/');
                HttpRequest fileReq = new HttpRequest();
                fileReq.setEndpoint(fileUrl);
                fileReq.setMethod('GET');
                fileReq.setHeader('Authorization', token);
                HttpResponse fileRes = http.send(fileReq);
                if (fileRes.getStatusCode() == 200) {
                    ContentVersion cv = new ContentVersion();
                    cv.Title = leadId + '_' + formId + '_' + parts[parts.size()-1];
                    cv.PathOnClient = '/' + cv.Title;
                    cv.VersionData = fileRes.getBodyAsBlob();
                    allContentVersions.add(cv);
                    leadIdMapping.add(leadId);
                    System.debug('File saved: ' + cv.Title);
                } else {
                    System.debug('File fetch failed: ' + fileRes.getStatusCode());
                }
            }
        }

        // Insert & Link
        if (!allContentVersions.isEmpty()) {
            Database.SaveResult[] cvResults = Database.insert(allContentVersions, false);
            Map<Id, String> cvIdToLeadId = new Map<Id, String>();
            for (Integer i = 0; i < cvResults.size(); i++) {
                if (cvResults[i].isSuccess()) cvIdToLeadId.put(cvResults[i].getId(), leadIdMapping[i]);
                else System.debug('Insert failed: ' + cvResults[i].getErrors());
            }
            List<ContentVersion> insertedCVs = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :cvIdToLeadId.keySet()];
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for (ContentVersion cv : insertedCVs) {
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = cv.ContentDocumentId;
                cdl.LinkedEntityId = cvIdToLeadId.get(cv.Id);
                cdl.ShareType = 'V';
                cdl.Visibility = 'AllUsers';
                links.add(cdl);
            }
            if (!links.isEmpty()) {
                insert links;
                System.debug('SUCCESS: ' + links.size() + ' files linked.');
            }
        } else {
            System.debug('No matches found in this batch.');
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('TypeformBackfill complete.');
    }
}