public with sharing class DirectoryController {
    @AuraEnabled(cacheable=true)
    public static List<Contact> getDirectoryContacts() {
        return [
            SELECT Id, Name, Title, Company__c , Phone, Birthdate, Email
            FROM Contact
        ];
    }
}