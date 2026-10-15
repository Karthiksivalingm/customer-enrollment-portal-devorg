/**
 * TSDocumentService
 * -----------------------------------------------------------------------
 * Bridges the custom "Review and Complete the form" buttons to the TS
 * Documents managed package, so the user never has to open the TS
 * Documents component and pick a template from the dropdown by hand.
 *
 * v4 - PDF ONLY, NO GOOGLE DOC LINK MODE
 * REVIEW_MODE used to be a toggle ('gdoc' / 'pdf' / 'template') and was
 * left set to 'gdoc' - meaning getReviewTarget() always handed back a raw
 * docs.google.com edit link and never attempted the PDF export path.
 * That flag has been removed. getReviewTarget() now always tries to
 * export the template's Google Doc to PDF and save it as a File; it only
 * falls back to the "template record" mode when the template has no
 * Google Doc attached to export in the first place. It never again
 * returns a Google Doc URL.
 *
 * Also removed in v4 (both existed solely to support the retired
 * per-contact Google Doc copy flow / the "Open Google Doc" link that used
 * to sit under each form row):
 *   - getTemplateGoogleDocId()  (was only called by PerContactDocumentService)
 *   - getTemplateDocUrls()      (was only called to render "Open Google Doc")
 *   - fetchGoogleDocBytes() / exportGoogleDocAsDocx() / GDOC_DOCX_EXPORT
 *     (was only called by the retired FormWorkflowService.saveEditableCopy())
 *
 * If your Forms LWC still renders an "Open Google Doc" link or calls
 * getTemplateDocUrls(), remove that from the component too - the link
 * has no backing Apex method anymore.
 *
 * v13 - PORTAL-SAFE "EXISTING PDF ONLY" LOOKUP
 * Added getExistingPdfOnly(): unlike getReviewTarget(), it never calls
 * exportGoogleDocAsPdf() / GoogleServiceAccountAuth. Used by
 * FormWorkflowService.openBasedFormForContact() (the portal's "Review
 * and Complete the form" button) so a contact clicking that button can
 * never trigger a live Google Doc export - it only ever opens a PDF
 * that's already been generated and stored on the record.
 */
public with sharing class TSDocumentService {
    /* =====================================================================
     * PACKAGE CONSTANTS
     * ===================================================================== */
    private static final String TEMPLATE_OBJECT   = 'docb__Document_Builder__c';
    private static final String NAME_FIELD        = 'Name';
    private static final String ALT_NAME_FIELD    = 'docb__Template_Name__c';
    private static final String BASE_OBJECT_FIELD = 'docb__Base_object_API__c';
    private static final String ACTIVE_FIELD      = 'docb__Is_Active__c';
    private static final String OUTPUT_FIELD      = 'docb__Output_format__c';
    private static final String GDOC_ID_FIELD     = 'docb__GDoc_Template_Document_ID__c';
    private static final String DEFAULT_NAME_FLD  = 'docb__Default_File_Name__c';
    private static final String GENERATOR_MODE = 'none';
    private static final String GENERATOR_FLOW = 'Generate_TS_Document';
    private static final String GENERATOR_PAGE = '';
    private static final Integer ASYNC_GRACE_SECONDS = 120;
    private static final Integer CALLOUT_TIMEOUT = 120000;
    private static final Boolean REGENERATE_ON_EACH_CLICK = false;
    /* ===================================================================== */
    public class TSDocumentException extends Exception {}
    public class GeneratedDocument {
        @AuraEnabled public String  contentDocumentId;
        @AuraEnabled public String  contentVersionId;
        @AuraEnabled public String  fileName;
        @AuraEnabled public String  templateId;
        @AuraEnabled public Boolean pending;
        @AuraEnabled public Boolean unsupported;
        @AuraEnabled public String  handoffUrl;
    }
    public class ReviewTarget {
        @AuraEnabled public String  templateId;
        @AuraEnabled public String  templateName;
        @AuraEnabled public String  url;
        @AuraEnabled public String  mode;
        @AuraEnabled public Boolean available;
        @AuraEnabled public String  message;
        @AuraEnabled public String  contentDocumentId;
        @AuraEnabled public String  fileName;
        @AuraEnabled public Boolean reusedExisting;
    }
    public class TemplateInfo {
        @AuraEnabled public String  templateId;
        @AuraEnabled public String  name;
        @AuraEnabled public String  baseObject;
        @AuraEnabled public String  outputFormat;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public Boolean hasGDocId;
    }
    @AuraEnabled
    public static GeneratedDocument generateDocument(Id recordId, String templateName) {
        if (recordId == null) {
            throw new AuraHandledException('No record Id was supplied.');
        }
        if (String.isBlank(templateName)) {
            throw new AuraHandledException(
                'No TS Documents template is mapped to this form.'
            );
        }
        try {
            SObject template = findTemplate(templateName);
            validateTemplate(template, recordId, templateName);
            Id templateId = (Id) template.get('Id');
            if (GENERATOR_MODE == 'none') {
                GeneratedDocument unsupportedDoc = new GeneratedDocument();
                unsupportedDoc.templateId  = templateId;
                unsupportedDoc.fileName    = templateName;
                unsupportedDoc.unsupported = true;
                unsupportedDoc.pending     = false;
                return unsupportedDoc;
            }
            if (GENERATOR_MODE == 'url') {
                GeneratedDocument handoff = new GeneratedDocument();
                handoff.templateId  = templateId;
                handoff.fileName    = templateName;
                handoff.handoffUrl  = buildHandoffUrl(recordId, templateId);
                handoff.unsupported = false;
                handoff.pending     = false;
                return handoff;
            }
            Set<Id> before = existingFileIds(recordId);
            invokePackage(recordId, templateId, templateName);
            GeneratedDocument doc = findGeneratedFile(recordId, before, templateName, template);
            if (doc == null) {
                GeneratedDocument pendingDoc = new GeneratedDocument();
                pendingDoc.templateId = templateId;
                pendingDoc.fileName   = templateName;
                pendingDoc.pending    = true;
                return pendingDoc;
            }
            doc.templateId = templateId;
            doc.pending    = false;
            return doc;
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Could not generate "' + templateName + '": ' + e.getMessage()
            );
        }
    }
    @AuraEnabled
    public static GeneratedDocument pollForDocument(
        Id recordId, String templateName, String knownIdsCsv
    ) {
        Set<Id> before = parseIdCsv(knownIdsCsv);
        SObject template;
        try {
            template = findTemplate(templateName);
        } catch (Exception ignored) {
            template = null;
        }
        GeneratedDocument doc = findGeneratedFile(recordId, before, templateName, template);
        if (doc == null) {
            GeneratedDocument pendingDoc = new GeneratedDocument();
            pendingDoc.fileName = templateName;
            pendingDoc.pending  = true;
            return pendingDoc;
        }
        doc.pending = false;
        return doc;
    }
    @AuraEnabled
    public static String getExistingFileIds(Id recordId) {
        return String.join(new List<Id>(existingFileIds(recordId)), ',');
    }
    private static void invokePackage(Id recordId, Id templateId, String templateName) {
        if (GENERATOR_MODE == 'flow') {
            runFlow(recordId, templateId);
        } else if (GENERATOR_MODE == 'apex') {
            runApex(recordId, templateId);
        } else if (GENERATOR_MODE == 'action') {
            runAction(recordId, templateId);
        } else {
            throw new AuraHandledException(
                'GENERATOR_MODE "' + GENERATOR_MODE + '" is not recognised. ' +
                'Set it to none, flow, apex, action or url in TSDocumentService.'
            );
        }
    }
    private static void runFlow(Id recordId, Id templateId) {
        if (!flowExists(GENERATOR_FLOW)) {
            throw new AuraHandledException(
                'The Flow "' + GENERATOR_FLOW + '" does not exist or is not active. ' +
                'Build and activate it, or set GENERATOR_MODE to a different mode.'
            );
        }
        Map<String, Object> inputs = new Map<String, Object>{
            'recordId'   => String.valueOf(recordId),
            'templateId' => String.valueOf(templateId)
        };
        try {
            Flow.Interview generator = Flow.Interview.createInterview(GENERATOR_FLOW, inputs);
            generator.start();
        } catch (System.TypeException e) {
            throw new AuraHandledException(
                'The Flow "' + GENERATOR_FLOW + '" could not be started: ' + e.getMessage()
            );
        } catch (Exception e) {
            throw new AuraHandledException(
                'The Flow "' + GENERATOR_FLOW + '" failed while generating: ' + e.getMessage()
            );
        }
    }
    private static void runApex(Id recordId, Id templateId) {
        throw new AuraHandledException(
            'GENERATOR_MODE is "apex" but runApex() has not been filled in yet. ' +
            'Add the docb class call, or set GENERATOR_MODE back to "none".'
        );
    }
    private static void runAction(Id recordId, Id templateId) {
        throw new AuraHandledException(
            'GENERATOR_MODE is "action" but runAction() has not been filled in yet. ' +
            'Add the action name, or set GENERATOR_MODE back to "none".'
        );
    }
    private static String buildHandoffUrl(Id recordId, Id templateId) {
        if (String.isBlank(GENERATOR_PAGE)) {
            throw new AuraHandledException(
                'GENERATOR_MODE is "url" but GENERATOR_PAGE is empty. ' +
                'Set it to the package Visualforce page name.'
            );
        }
        return '/apex/' + GENERATOR_PAGE
             + '?id=' + recordId
             + '&templateId=' + templateId;
    }
    private static Boolean flowExists(String flowApiName) {
        List<FlowDefinitionView> defs = [
            SELECT ApiName, IsActive, ProcessType
            FROM FlowDefinitionView
            WHERE ApiName = :flowApiName
            LIMIT 1
        ];
        return !defs.isEmpty() && defs[0].IsActive == true;
    }
    private static SObject findTemplate(String templateName) {
        SObject template = TSTemplateSelector.findByName(templateName);
        if (template == null) {
            Integer total = 0;
            try {
                total = TSTemplateSelector.countAll();
            } catch (Exception ignored) {
                total = -1;
            }
            String detail;
            if (total == 0) {
                detail = 'No TS Documents templates exist in this org yet.';
            } else if (total < 0) {
                detail = 'The TS Documents template object could not be read - '
                       + 'check the running user has access to '
                       + TEMPLATE_OBJECT + '.';
            } else {
                detail = 'There are ' + total + ' templates, but none named that. '
                       + 'Check the spelling against the template record - '
                       + 'matching ignores case, punctuation and a trailing '
                       + '"- English"/"- Spanish", but not a real difference '
                       + 'such as EVV versus EVM.';
            }
            throw new AuraHandledException(
                'No TS Documents template named "' + templateName + '" was found. '
                + detail
            );
        }
        return template;
    }
    private static void validateTemplate(SObject template, Id recordId, String templateName) {
        Boolean isActive = (Boolean) template.get(ACTIVE_FIELD);
        if (isActive != true) {
            throw new AuraHandledException(
                'The TS Documents template "' + templateName + '" is not active. ' +
                'Tick "Is Active?" on the template record.'
            );
        }
        String baseObject = (String) template.get(BASE_OBJECT_FIELD);
        String actualType = String.valueOf(recordId.getSObjectType());
        if (String.isNotBlank(baseObject) && !baseObject.equalsIgnoreCase(actualType)) {
            throw new AuraHandledException(
                'The template "' + templateName + '" is built for ' + baseObject +
                ' records, but this is a ' + actualType + ' record. ' +
                'Change "Base object API" on the template, or map this form to a different template.'
            );
        }
        String gdocId = (String) template.get(GDOC_ID_FIELD);
        if (String.isBlank(gdocId)) {
            throw new AuraHandledException(
                'The template "' + templateName + '" has no Google Doc attached ' +
                '(GDoc Template Document ID is empty). Open it in Template Builder first.'
            );
        }
    }
    private static Set<Id> existingFileIds(Id recordId) {
        Set<Id> ids = new Set<Id>();
        for (ContentDocumentLink link : [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
        ]) {
            ids.add(link.ContentDocumentId);
        }
        return ids;
    }
    private static Set<Id> parseIdCsv(String csv) {
        Set<Id> ids = new Set<Id>();
        if (String.isBlank(csv)) {
            return ids;
        }
        for (String raw : csv.split(',')) {
            String trimmed = raw.trim();
            if (String.isBlank(trimmed)) {
                continue;
            }
            try {
                ids.add((Id) trimmed);
            } catch (Exception ignored) {
                // not a valid Id - skip it
            }
        }
        return ids;
    }
    private static GeneratedDocument findGeneratedFile(
        Id recordId, Set<Id> before, String templateName, SObject template
    ) {
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId,
                   ContentDocument.Title,
                   ContentDocument.FileExtension,
                   ContentDocument.LatestPublishedVersionId,
                   ContentDocument.CreatedDate
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
            ORDER BY ContentDocument.CreatedDate DESC
        ];
        ContentDocumentLink match;
        for (ContentDocumentLink link : links) {
            if (!before.contains(link.ContentDocumentId)) {
                match = link;
                break;
            }
        }
        if (match == null) {
            Set<String> needles = new Set<String>();
            if (String.isNotBlank(templateName)) {
                needles.add(templateName.toLowerCase());
            }
            if (template != null) {
                String defaultName = (String) TSTemplateSelector.safeGet(template, DEFAULT_NAME_FLD);
                if (String.isNotBlank(defaultName)) {
                    needles.add(defaultName.toLowerCase());
                }
            }
            Datetime cutoff = Datetime.now().addSeconds(-ASYNC_GRACE_SECONDS);
            for (ContentDocumentLink link : links) {
                String title = link.ContentDocument.Title;
                if (title == null || link.ContentDocument.CreatedDate < cutoff) {
                    continue;
                }
                String lower = title.toLowerCase();
                for (String needle : needles) {
                    if (lower.contains(needle) || needle.contains(lower)) {
                        match = link;
                        break;
                    }
                }
                if (match != null) {
                    break;
                }
            }
        }
        if (match == null) {
            return null;
        }
        GeneratedDocument out = new GeneratedDocument();
        out.contentDocumentId = match.ContentDocumentId;
        out.contentVersionId  = match.ContentDocument.LatestPublishedVersionId;
        out.fileName          = match.ContentDocument.Title;
        return out;
    }
    /**
     * v4: PDF export is the only path. Reuses an already-saved PDF for
     * this record/template when one exists (unless REGENERATE_ON_EACH_CLICK
     * is true), otherwise exports the template's master Google Doc to PDF
     * via HTTP callout and saves it as a File. If the template has no
     * Google Doc attached at all, falls back to opening the template
     * record so someone can attach one - it never returns a Google Doc
     * edit link, and a failed export is now a real, visible error rather
     * than a silent fallback to 'gdoc'.
     */
    @AuraEnabled
    public static ReviewTarget getReviewTarget(Id recordId, String templateName) {
        ReviewTarget target = new ReviewTarget();
        target.templateName = templateName;
        target.available    = false;
        if (String.isBlank(templateName)) {
            target.message = 'No TS Documents template is mapped to this form.';
            return target;
        }
        SObject template;
        try {
            template = findTemplate(templateName);
        } catch (Exception e) {
            target.message =
                'Could not load the TS Documents template "' + templateName + '": '
                + e.getMessage();
            return target;
        }
        Id templateId = (Id) template.get('Id');
        target.templateId = templateId;
        if (template.get(ACTIVE_FIELD) != true) {
            target.message =
                'The template "' + templateName + '" exists but is not active. ' +
                'Tick "Is Active?" on the template record.';
            return target;
        }
        String gdocId = (String) template.get(GDOC_ID_FIELD);
        if (String.isBlank(gdocId)) {
            target.url       = '/' + templateId;
            target.mode      = 'template';
            target.available = true;
            target.message   =
                'This template has no Google Doc attached yet - opening the ' +
                'template record so you can add one in Template Builder.';
            return target;
        }
        String fileTitle = pdfTitle(template, templateName);
        if (!REGENERATE_ON_EACH_CLICK) {
            ContentDocumentLink existing =
                findExistingPdf(recordId, template, templateName);
            if (existing != null) {
                target.mode              = 'file';
                target.contentDocumentId = existing.ContentDocumentId;
                target.fileName          = existing.ContentDocument.Title;
                target.reusedExisting    = true;
                target.available         = true;
                return target;
            }
        }
        try {
            Blob pdf = exportGoogleDocAsPdf(gdocId.trim());
            Id contentDocId = saveFileToRecord(recordId, fileTitle, pdf, 'pdf');
            target.mode              = 'file';
            target.contentDocumentId = contentDocId;
            target.fileName          = fileTitle;
            target.reusedExisting    = false;
            target.available         = true;
            return target;
        } catch (Exception e) {
            target.mode      = null;
            target.available = false;
            target.message   = 'Could not generate a PDF for "' + templateName + '": '
                             + e.getMessage();
            return target;
        }
    }

    /**
     * v13 - Portal-safe variant of getReviewTarget() - only ever reuses
     * an already-generated PDF already stored on the record. Never
     * attempts the live Google Doc export (exportGoogleDocAsPdf()),
     * since that requires GoogleServiceAccountAuth to succeed, which
     * depends on Google/certificate setup outside Salesforce's control
     * and shouldn't be triggered by a contact clicking a button in the
     * portal. If no PDF has been generated for this template yet, this
     * returns available = false with a plain explanation instead of
     * throwing a Google authentication error.
     */
    @AuraEnabled
    public static ReviewTarget getExistingPdfOnly(Id recordId, String templateName) {
        ReviewTarget target = new ReviewTarget();
        target.templateName = templateName;
        target.available    = false;

        if (String.isBlank(templateName)) {
            target.message = 'No TS Documents template is mapped to this form.';
            return target;
        }

        SObject template;
        try {
            template = findTemplate(templateName);
        } catch (Exception e) {
            target.message =
                'Could not load the TS Documents template "' + templateName + '": '
                + e.getMessage();
            return target;
        }

        Id templateId = (Id) template.get('Id');
        target.templateId = templateId;

        ContentDocumentLink existing = findExistingPdf(recordId, template, templateName);
        if (existing != null) {
            target.mode              = 'file';
            target.contentDocumentId = existing.ContentDocumentId;
            target.fileName          = existing.ContentDocument.Title;
            target.reusedExisting    = true;
            target.available         = true;
            return target;
        }

        target.mode      = null;
        target.available = false;
        target.message   =
            'This form has not been generated yet. Please check back later or contact us.';
        return target;
    }

    private static String pdfTitle(SObject template, String templateName) {
        String defaultName = (String) TSTemplateSelector.safeGet(template, DEFAULT_NAME_FLD);
        String base = String.isNotBlank(defaultName) ? defaultName : templateName;
        return base.endsWithIgnoreCase('.pdf') ? base.removeEndIgnoreCase('.pdf') : base;
    }
    private static ContentDocumentLink findExistingPdf(
        Id recordId, SObject template, String templateName
    ) {
        Set<String> wanted = new Set<String>();
        if (String.isNotBlank(templateName)) {
            wanted.add(normalizeName(templateName));
        }
        if (template != null) {
            String defaultName = (String) TSTemplateSelector.safeGet(template, DEFAULT_NAME_FLD);
            if (String.isNotBlank(defaultName)) {
                wanted.add(normalizeName(defaultName));
            }
            String realName = (String) template.get(NAME_FIELD);
            if (String.isNotBlank(realName)) {
                wanted.add(normalizeName(realName));
            }
        }
        wanted.remove('');
        if (wanted.isEmpty()) {
            return null;
        }
        ContentDocumentLink nonPdfMatch;
        for (ContentDocumentLink link : [
            SELECT ContentDocumentId,
                   ContentDocument.Title,
                   ContentDocument.FileExtension,
                   ContentDocument.CreatedDate
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
            ORDER BY ContentDocument.CreatedDate DESC
        ]) {
            String title = link.ContentDocument.Title;
            if (String.isBlank(title)) {
                continue;
            }
            String key = normalizeName(title);
            Boolean hit = false;
            for (String want : wanted) {
                if (key == want || key.startsWith(want) || want.startsWith(key)) {
                    hit = true;
                    break;
                }
            }
            if (!hit) {
                continue;
            }
            String ext = link.ContentDocument.FileExtension;
            if (ext != null && ext.equalsIgnoreCase('pdf')) {
                return link;
            }
            if (nonPdfMatch == null) {
                nonPdfMatch = link;
            }
        }
        return nonPdfMatch;
    }
    private static Id findFileByTitle(Id recordId, String title) {
        for (ContentDocumentLink link : [
            SELECT ContentDocumentId, ContentDocument.Title
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
            ORDER BY ContentDocument.CreatedDate DESC
        ]) {
            if (title.equalsIgnoreCase(link.ContentDocument.Title)) {
                return link.ContentDocumentId;
            }
        }
        return null;
    }
    /**
     * v5: authenticated export via the Drive API v3, using a service
     * account (GoogleServiceAccountAuth) that impersonates a Workspace
     * user with access to the doc. Replaces the old anonymous
     * docs.google.com/export request, which required the doc to be
     * publicly link-shared. Templates can now stay Restricted/private.
     */
    private static final String DRIVE_API_EXPORT_BASE = 'https://www.googleapis.com/drive/v3/files/';

    private static Blob exportGoogleDocAsPdf(String gdocId) {
        String endpoint = DRIVE_API_EXPORT_BASE + gdocId
            + '/export?mimeType=' + EncodingUtil.urlEncode('application/pdf', 'UTF-8');

        String accessToken;
        try {
            accessToken = GoogleServiceAccountAuth.getAccessToken();
        } catch (Exception e) {
            throw new TSDocumentException(
                'Could not authenticate with Google: ' + e.getMessage()
            );
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setTimeout(CALLOUT_TIMEOUT);
        req.setHeader('Authorization', 'Bearer ' + accessToken);

        HttpResponse res = new Http().send(req);
        Integer code = res.getStatusCode();

        if (code == 401 || code == 403) {
            throw new TSDocumentException(
                'Google returned HTTP ' + code + '. The impersonated Workspace user ('
                + 'see GoogleServiceAccountAuth.IMPERSONATE_EMAIL) does not have access '
                + 'to this document, or domain-wide delegation is not authorized for the '
                + 'drive.readonly scope.'
            );
        }
        if (code == 404) {
            throw new TSDocumentException(
                'Google returned HTTP 404 - the document Id on this template is wrong '
                + 'or the file was deleted/moved.'
            );
        }
        if (code != 200) {
            throw new TSDocumentException(
                'Google returned HTTP ' + code + ': ' + res.getBody()
            );
        }

        Blob body = res.getBodyAsBlob();
        if (body == null || body.size() == 0) {
            throw new TSDocumentException('Google returned an empty file.');
        }
        return body;
    }
    private static Id saveFileToRecord(Id recordId, String title, Blob fileBody, String extension) {
        Id existingDocId = findFileByTitle(recordId, title);
        ContentVersion cv = new ContentVersion();
        cv.Title          = title;
        cv.PathOnClient   = title + '.' + extension;
        cv.VersionData    = fileBody;
        cv.IsMajorVersion = true;
        if (existingDocId != null) {
            cv.ContentDocumentId = existingDocId;
        }
        insert cv;
        Id contentDocId = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id
        ].ContentDocumentId;
        if (existingDocId == null) {
            insert new ContentDocumentLink(
                ContentDocumentId = contentDocId,
                LinkedEntityId    = recordId,
                ShareType         = 'V',
                Visibility        = 'AllUsers'
            );
        }
        return contentDocId;
    }
    @AuraEnabled(cacheable=true)
    public static Map<String, String> matchTemplates(List<String> labels, String baseObject) {
        Map<String, String> matched = new Map<String, String>();
        if (labels == null || labels.isEmpty()) {
            return matched;
        }
        Map<String, String> index = new Map<String, String>();
        for (SObject row : TSTemplateSelector.listAll()) {
            if (row.get(ACTIVE_FIELD) != true) {
                continue;
            }
            if (String.isBlank((String) row.get(GDOC_ID_FIELD))) {
                continue;
            }
            String base = (String) row.get(BASE_OBJECT_FIELD);
            if (String.isNotBlank(baseObject)
                && String.isNotBlank(base)
                && !base.equalsIgnoreCase(baseObject)) {
                continue;
            }
            String realName = (String) row.get(NAME_FIELD);
            if (String.isBlank(realName)) {
                continue;
            }
            for (String candidate : new List<String>{
                    realName, (String) TSTemplateSelector.safeGet(row, ALT_NAME_FIELD) }) {
                if (String.isNotBlank(candidate)) {
                    index.put(normalizeName(candidate), realName);
                }
            }
        }
        for (String label : labels) {
            if (String.isBlank(label)) {
                continue;
            }
            String key = normalizeName(label);
            if (index.containsKey(key)) {
                matched.put(label, index.get(key));
                continue;
            }
            for (String indexed : index.keySet()) {
                if (indexed.startsWith(key) || key.startsWith(indexed)) {
                    matched.put(label, index.get(indexed));
                    break;
                }
            }
        }
        return matched;
    }
    private static String normalizeName(String value) {
        if (String.isBlank(value)) {
            return '';
        }
        String key = value.toLowerCase().trim();
        key = key.replace('&', ' and ');
        key = key.replaceAll('\\s*[-]\\s*(english|spanish|espanol)\\s*$', '');
        key = key.replaceAll('[^a-z0-9]', '');
        return key;
    }
    @AuraEnabled
    public static String explainMatching(List<String> labels, String baseObject) {
        Map<String, String> matched = matchTemplates(labels, baseObject);
        List<String> lines = new List<String>();
        lines.add('MATCHED (' + matched.size() + ' of ' + labels.size() + '):');
        for (String label : labels) {
            if (matched.containsKey(label)) {
                lines.add('  OK   "' + label + '"  ->  "' + matched.get(label) + '"');
            }
        }
        lines.add('UNMATCHED:');
        for (String label : labels) {
            if (!matched.containsKey(label)) {
                lines.add('  --   "' + label + '"');
            }
        }
        lines.add('TEMPLATES AVAILABLE:');
        for (TemplateInfo t : listTemplates()) {
            lines.add('  "' + t.name + '"'
                    + ' | base=' + t.baseObject
                    + ' | active=' + t.isActive
                    + ' | gdoc=' + (t.hasGDocId ? 'ok' : 'MISSING'));
        }
        return String.join(lines, '\n');
    }
    @AuraEnabled(cacheable=true)
    public static List<String> listTemplateNames() {
        return TSTemplateSelector.listNames();
    }
    @AuraEnabled(cacheable=true)
    public static List<TemplateInfo> listTemplates() {
        List<TemplateInfo> out = new List<TemplateInfo>();
        for (SObject row : TSTemplateSelector.listAll()) {
            TemplateInfo info = new TemplateInfo();
            info.templateId   = String.valueOf(row.get('Id'));
            info.name         = (String)  row.get(NAME_FIELD);
            info.baseObject   = (String)  row.get(BASE_OBJECT_FIELD);
            info.outputFormat = (String)  row.get(OUTPUT_FIELD);
            info.isActive     = (Boolean) row.get(ACTIVE_FIELD);
            info.hasGDocId    = String.isNotBlank((String) row.get(GDOC_ID_FIELD));
            out.add(info);
        }
        return out;
    }
}