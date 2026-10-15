public class DocumentController {
    public String selectedFormat { get; set; }
    public Id contactId { get; set; }
    
    public DocumentController() {
        contactId = ApexPages.currentPage().getParameters().get('id');
    }

    public PageReference generateDocument() {
        if (selectedFormat == 'PDF') {
            return Page.ContactBio; // Name of your PDF Visualforce page
        } else if (selectedFormat == 'Word') {
            return Page.WordDocument; // Name of your Word Visualforce page
        }
        return null;
    }
}