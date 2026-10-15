public class ContactBioController {
    public Contact contact { get; set; }
    public Attachment attach { get; set; }

    public ContactBioController() {
        
        List<Contact> contacts = [SELECT Id, Name, Title, Birthdate, Phone, Email, OtherPhone, Email_Office__c,CreatedDate, Salutation, Company__c FROM Contact LIMIT 1];
        if (!contacts.isEmpty()) {
            contact = contacts[0];
            List<Attachment> attachments = [SELECT Id FROM Attachment WHERE ParentId = :contact.Id LIMIT 1];
            if (!attachments.isEmpty()) {
                attach = attachments[0];
            }
        } else {
            
            contact = new Contact();
            attach = new Attachment();
        }
    }
}