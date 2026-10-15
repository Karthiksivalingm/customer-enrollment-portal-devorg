/**
 * GoogleDriveService
 * -----------------------------------------------------------------------
 * Thin wrapper over the Google Drive REST API v3, authenticated through
 * the "Google_Drive_API" Named Credential (see PerContactCopy_Setup_Guide.md).
 * Used to give each contact their OWN copy of a TS Documents template,
 * instead of everyone editing the same shared master Google Doc.
 *
 * PREREQUISITE (see the setup guide for the full walkthrough):
 *   1. A Google OAuth Client (Google Cloud Console) with the Drive API
 *      enabled, authorized AS the same Google account that owns the TS
 *      Documents templates - so it already has edit access to them.
 *   2. A Salesforce Auth. Provider (type Google) using that OAuth Client.
 *   3. A Named Credential called exactly "Google_Drive_API", URL
 *      https://www.googleapis.com, OAuth 2.0 via the Auth Provider above,
 *      authenticated once (an admin clicks "Authenticate").
 *
 * Until that's in place, every method here throws GoogleDriveException -
 * callers (PerContactDocumentService, FormWorkflowService) catch that and
 * fall back to the previous shared-document behaviour, so nothing breaks
 * mid-rollout.
 */
public without sharing class GoogleDriveService {
    private static final String NAMED_CREDENTIAL = 'callout:Google_Drive_API';
    private static final Integer CALLOUT_TIMEOUT = 120000;

    public static final String MIME_DOCX =
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    public static final String MIME_PDF = 'application/pdf';

    public class GoogleDriveException extends Exception {}

    /**
     * Creates a copy of `sourceFileId` titled `newTitle`, in the same
     * Drive account the Named Credential authenticated as. Returns the
     * new file's Id.
     */
    public static String copyFile(String sourceFileId, String newTitle) {
        if (String.isBlank(sourceFileId)) {
            throw new GoogleDriveException('No source Google Doc Id was supplied.');
        }
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + '/drive/v3/files/' + sourceFileId + '/copy');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(CALLOUT_TIMEOUT);
        Map<String, Object> body = new Map<String, Object>{ 'name' => newTitle };
        req.setBody(JSON.serialize(body));

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            throw new GoogleDriveException(
                'Could not copy the Google Doc (HTTP ' + res.getStatusCode() + '): '
                + res.getBody()
            );
        }
        Map<String, Object> parsed =
            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        String newId = (String) parsed.get('id');
        if (String.isBlank(newId)) {
            throw new GoogleDriveException('Google did not return a new file Id.');
        }
        return newId;
    }

    /**
     * Grants "anyone with the link" EDIT access to `fileId`, so a contact
     * can type into it without needing a Google login of their own.
     */
    public static void shareAsEditor(String fileId) {
        if (String.isBlank(fileId)) {
            throw new GoogleDriveException('No Google Doc Id was supplied.');
        }
        HttpRequest req = new HttpRequest();
        req.setEndpoint(
            NAMED_CREDENTIAL + '/drive/v3/files/' + fileId
            + '/permissions?sendNotificationEmail=false'
        );
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(CALLOUT_TIMEOUT);
        Map<String, Object> body = new Map<String, Object>{
            'role' => 'writer',
            'type' => 'anyone'
        };
        req.setBody(JSON.serialize(body));

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            throw new GoogleDriveException(
                'Could not share the Google Doc (HTTP ' + res.getStatusCode() + '): '
                + res.getBody()
            );
        }
    }

    /**
     * Exports the CURRENT content of `fileId` in the given mime type
     * (MIME_DOCX or MIME_PDF). Authenticated, so this works even if the
     * file is not publicly link-shared.
     */
    public static Blob exportFile(String fileId, String mimeType) {
        if (String.isBlank(fileId)) {
            throw new GoogleDriveException('No Google Doc Id was supplied.');
        }
        HttpRequest req = new HttpRequest();
        req.setEndpoint(
            NAMED_CREDENTIAL + '/drive/v3/files/' + fileId
            + '/export?mimeType=' + EncodingUtil.urlEncode(mimeType, 'UTF-8')
        );
        req.setMethod('GET');
        req.setTimeout(CALLOUT_TIMEOUT);

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            throw new GoogleDriveException(
                'Could not export the Google Doc (HTTP ' + res.getStatusCode() + '): '
                + res.getBody()
            );
        }
        Blob body = res.getBodyAsBlob();
        if (body == null || body.size() == 0) {
            throw new GoogleDriveException('Google returned an empty file.');
        }
        return body;
    }
}