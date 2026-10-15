/**
 * PhaseDocumentViewerController
 *
 * Backs the PhaseDocumentViewer Visualforce page. Exposes the PDF's raw bytes
 * as a Blob property; the VF page itself is declared with
 * contentType="application/pdf" and has its body bound to that Blob, which
 * is the standard Visualforce pattern for streaming an existing binary file
 * (rather than rendering page markup as a PDF via renderAs="pdf").
 *
 * Access is re-validated here (WITH SECURITY_ENFORCED... actually WITH USER_MODE)
 * rather than trusted purely from the calling LWC, since this VF page is
 * reachable directly by URL.
 */
public with sharing class PhaseDocumentViewerController {

    public Blob fileBody { get; private set; }
    public String fileName { get; private set; }
    public Boolean hasError { get; private set; }

    public PhaseDocumentViewerController() {
        hasError = true;
        fileBody = Blob.valueOf('Document not found.');
        fileName = 'error.txt';

        String param = ApexPages.currentPage().getParameters().get('cdId');
        if (String.isBlank(param)) {
            return;
        }

        Id cdId;
        try {
            cdId = (Id) param;
        } catch (Exception e) {
            return;
        }

        List<ContentVersion> versions = [
            SELECT VersionData, Title, FileExtension
            FROM ContentVersion
            WHERE ContentDocumentId = :cdId
            AND IsLatest = true
            WITH USER_MODE
            LIMIT 1
        ];

        if (versions.isEmpty()) {
            return;
        }

        ContentVersion cv = versions[0];
        fileBody = cv.VersionData;
        fileName = String.isNotBlank(cv.FileExtension)
            ? cv.Title + '.' + cv.FileExtension
            : cv.Title + '.pdf';
        hasError = false;
    }
}