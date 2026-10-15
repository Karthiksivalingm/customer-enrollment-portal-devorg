public with sharing class EVVPdfService {

    @AuraEnabled
    public static Id generatePdfFile(Id contactId, String language) {

        PageReference pdfPage;

        if(language == 'english'){
            pdfPage = Page.EVVMemberContingencyPlanPDF;
        }else{
            pdfPage = Page.DDDEVVMemberContingencySpanish;
        }

        pdfPage.getParameters().put('recordId', contactId);

        Blob pdfBlob;

        if(Test.isRunningTest()){
            pdfBlob = Blob.valueOf('Test PDF');
        }else{
            pdfBlob = pdfPage.getContentAsPDF();
        }

        ContentVersion cv = new ContentVersion();
        cv.Title = language == 'english'
            ? 'DDD-EVV Member Contingency Back-Up Plan - English'
            : 'DDD-EVV Member Contingency Back-Up Plan - Spanish';

        cv.PathOnClient = cv.Title + '.pdf';
        cv.VersionData = pdfBlob;

        insert cv;

        cv = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];

        return cv.ContentDocumentId;
    }
}