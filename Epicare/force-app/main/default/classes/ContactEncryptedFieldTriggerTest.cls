@isTest
public class ContactEncryptedFieldTriggerTest {
    
    @isTest
    static void testInsertContact() {
        // Create new Contact with PlainText__c populated
        Contact c = new Contact(
            LastName = 'Hernandez',
            SSN__c = '768640250'
        );
        insert c;

        // Reload from DB
        Contact insertedContact = [SELECT Id, SSN_Number__c, SSN__c 
                                   FROM Contact 
                                   WHERE Id = :c.Id];
        
        System.assertEquals('768640250', insertedContact.SSN_Number__c, 
                            'Encrypted field should copy from PlainText__c on insert');
    }
    
    @isTest
    static void testUpdateContact() {
        // Insert first
        Contact c = new Contact(
            LastName = 'Hernandez',
            SSN__c = '768640250'
        );
        insert c;

        // Update PlainText__c
        c.SSN__c = '768640250';
        update c;

        // Reload from DB
        Contact updatedContact = [SELECT Id, SSN_Number__c, SSN__c 
                                  FROM Contact 
                                  WHERE Id = :c.Id];
        
        System.assertEquals('768640250', updatedContact.SSN_Number__c, 
                            'Encrypted field should copy from PlainText__c on update');
    }
}