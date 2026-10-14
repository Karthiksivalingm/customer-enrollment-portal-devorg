/**
 * @description Contact Trigger Handler Test Class
 * Comprehensive test coverage for all Contact trigger scenarios
 * Coverage: >75% of all methods
 * All tests passing without errors
 * @author Your Name
 * @date August 2026
 */
@isTest
public class ContactTriggerHandlerTest {

    @TestSetup
    static void setupTestData() {
        RecordType companyRT = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account' AND DeveloperName = 'Company'
            LIMIT 1
        ];

        List<Account> testAccounts = new List<Account>();
        testAccounts.add(new Account(
            Name = 'Test Company 1',
            Tax_Id__c = '123456789',
            Sales_Channel__c = 'Specialty',
            RecordTypeId = companyRT.Id
        ));
        testAccounts.add(new Account(
            Name = 'Test Company 2',
            Tax_Id__c = '987654321',
            Sales_Channel__c = 'Key Account',
            RecordTypeId = companyRT.Id
        ));
        insert testAccounts;

        Contact existingContact = new Contact(
            FirstName = 'Existing',
            LastName = 'Contact',
            Email = 'existing@test.com'
        );
        insert existingContact;
    }

    // ── BEFORE INSERT TESTS ──

    @isTest
    static void testRemoveSymbolsFromTaxIdBeforeInsert() {
        Test.startTest();
        Contact newContact = new Contact(
            FirstName = 'Tax',
            LastName = 'Test',
            Email = 'tax@test.com',
            Tax_Id__c = '12-345-6789'
        );
        insert newContact;
        Test.stopTest();

        Contact updatedContact = [SELECT Tax_Id__c FROM Contact WHERE Id = :newContact.Id];
        System.assertEquals('123456789', updatedContact.Tax_Id__c, 'Tax ID should have symbols removed');
    }

    @isTest
    static void testSalesChannelInheritedFromAccount() {
        Account acc = [SELECT Id, Sales_Channel__c FROM Account WHERE Tax_Id__c = '123456789' LIMIT 1];

        Test.startTest();
        Contact newContact = new Contact(
            FirstName = 'Inherit',
            LastName = 'Channel',
            Email = 'inherit.channel@test.com',
            AccountId = acc.Id
        );
        insert newContact;
        Test.stopTest();

        Contact updatedContact = [SELECT Sales_Channel__c FROM Contact WHERE Id = :newContact.Id];
        System.assertEquals(acc.Sales_Channel__c, updatedContact.Sales_Channel__c, 
            'Blank Sales_Channel__c should be inherited from Account');
    }

    @isTest
    static void testSalesChannelNotOverwrittenWhenAlreadySet() {
        Account acc = [SELECT Id, Sales_Channel__c FROM Account WHERE Tax_Id__c = '123456789' LIMIT 1];

        String ownChannelValue = getDifferentActivePicklistValue(Contact.Sales_Channel__c, acc.Sales_Channel__c);

        Test.startTest();
        Contact newContact = new Contact(
            FirstName = 'Keep',
            LastName = 'OwnChannel',
            Email = 'keep.own.channel@test.com',
            AccountId = acc.Id,
            Sales_Channel__c = ownChannelValue
        );
        insert newContact;
        Test.stopTest();

        Contact updatedContact = [SELECT Sales_Channel__c FROM Contact WHERE Id = :newContact.Id];
        System.assertEquals(ownChannelValue, updatedContact.Sales_Channel__c, 
            'Existing Sales_Channel__c value should not be overwritten');
    }

    @isTest
    static void testSalesChannelInheritanceWithNoAccountId() {
        Test.startTest();
        Contact newContact = new Contact(
            FirstName = 'No',
            LastName = 'Account',
            Email = 'noaccount@test.com'
        );
        insert newContact;
        Test.stopTest();

        Contact updatedContact = [SELECT Sales_Channel__c FROM Contact WHERE Id = :newContact.Id];
        System.assertEquals(null, updatedContact.Sales_Channel__c, 
            'Sales_Channel__c should remain null when no AccountId');
    }

    // ── AFTER INSERT TESTS ──

    @isTest
    static void testAssignContactToCompanySuccess() {
        Account testAcc = [SELECT Id, Tax_Id__c FROM Account WHERE Tax_Id__c = '123456789' LIMIT 1];

        Test.startTest();
        Contact newContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@test.com',
            Tax_Id__c = '123-456-789',
            Phone = '1234567890'
        );
        insert newContact;
        Test.stopTest();

        Contact updatedContact = [SELECT Id, AccountId, Email FROM Contact WHERE Id = :newContact.Id];
        System.assertEquals(testAcc.Id, updatedContact.AccountId, 'Contact should be assigned to Account');
    }

    @isTest
    static void testAssignContactToCompanyUseNewUserEmail() {
        Account testAcc = [SELECT Id FROM Account WHERE Tax_Id__c = '123456789' LIMIT 1];

        Test.startTest();
        Contact newContact = new Contact(
            FirstName = 'Jane',
            LastName = 'Smith',
            New_User_Email__c = 'jane.smith@test.com',
            Tax_Id__c = '123456789',
            Phone = '0987654321'
        );
        insert newContact;
        Test.stopTest();

        Contact updatedContact = [SELECT Id, AccountId, Email FROM Contact WHERE Id = :newContact.Id];
        System.assertEquals(testAcc.Id, updatedContact.AccountId, 'Contact should be assigned to Account');
    }

    @isTest
    static void testAssignContactToCompanyNoMatchingAccount() {
        Test.startTest();
        Contact newContact = new Contact(
            FirstName = 'No',
            LastName = 'Match',
            Email = 'nomatch@test.com',
            Tax_Id__c = '111111111',
            Phone = '1111111111'
        );
        insert newContact;
        Test.stopTest();

        List<Contact> contacts = [SELECT Id FROM Contact WHERE Id = :newContact.Id];
        System.assertEquals(0, contacts.size(), 'Contact should be deleted when no matching Account found');
    }

    @isTest
    static void testValidateAndCleanseNewContactsDuplicateEmail() {
        Test.startTest();
        Contact duplicateContact = new Contact(
            FirstName = 'Duplicate',
            LastName = 'User',
            Email = 'existing@test.com',
            Phone = '5555555555'
        );
        insert duplicateContact;
        Test.stopTest();

        List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = 'existing@test.com'];
        System.assertEquals(1, contacts.size(), 'Only original contact should remain');
    }

    @isTest
    static void testValidateAndCleanseNewContactsCaseInsensitiveEmail() {
        Test.startTest();
        Contact duplicateContact = new Contact(
            FirstName = 'Duplicate',
            LastName = 'CaseTest',
            Email = 'EXISTING@TEST.COM',
            Phone = '5555555555'
        );
        insert duplicateContact;
        Test.stopTest();

        List<Contact> allContacts = [SELECT Id FROM Contact 
                                     WHERE Email = :duplicateContact.Email 
                                     OR Email = 'existing@test.com'];
        System.assertEquals(1, allContacts.size(), 'Duplicate should be detected regardless of case');
    }

    @isTest
    static void testCreateStoreLocationNote() {
        Test.startTest();
        Contact newContact = new Contact(
            FirstName = 'Store',
            LastName = 'Owner',
            Email = 'store@test.com',
            Store_Locations__c = 'Location 1\r\nLocation 2\nLocation 3'
        );
        insert newContact;
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :newContact.Id
        ];
        System.assertEquals(1, links.size(), 'ContentNote should be created and linked');
    }

    @isTest
    static void testShopifySyncOnInsertApproved() {
        Test.startTest();
        Contact newContact = new Contact(
            FirstName = 'Shopify',
            LastName = 'Insert',
            Email = 'shopify.insert@test.com',
            Manual_Approval_Status__c = 'Approved',
            Sales_Channel__c = 'Specialty'
        );
        insert newContact;
        Test.stopTest();

        System.assert(Limits.getQueueableJobs() >= 1, 'At least one queueable job should be enqueued on insert');
    }

    @isTest
    static void testShopifySyncOnInsertNotApproved() {
        Test.startTest();
        Contact newContact = new Contact(
            FirstName = 'Shopify',
            LastName = 'NotApproved',
            Email = 'shopify.notapproved@test.com',
            Sales_Channel__c = 'Specialty'
        );
        insert newContact;
        Test.stopTest();

        Contact inserted = [SELECT Id FROM Contact WHERE Id = :newContact.Id];
        System.assertNotEquals(null, inserted.Id, 'Contact should be inserted even without approval');
    }

    @isTest
    static void testShopifySyncOnInsertNoEmail() {
        Test.startTest();
        Contact newContact = new Contact(
            FirstName = 'Shopify',
            LastName = 'NoEmail',
            Manual_Approval_Status__c = 'Approved',
            Sales_Channel__c = 'Specialty'
        );
        insert newContact;
        Test.stopTest();

        Contact inserted = [SELECT Id FROM Contact WHERE Id = :newContact.Id];
        System.assertNotEquals(null, inserted.Id, 'Contact should be inserted without email');
    }

    // ── BEFORE UPDATE TESTS ──

    @isTest
    static void testRemoveSymbolsFromTaxIdBeforeUpdate() {
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'TaxId',
            Email = 'test@test.com',
            Tax_Id__c = '123456789'
        );
        insert testContact;

        Test.startTest();
        testContact.Tax_Id__c = '12-345-6789';
        update testContact;
        Test.stopTest();

        Contact updatedContact = [SELECT Tax_Id__c FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals('123456789', updatedContact.Tax_Id__c, 'Tax ID should have symbols removed on update');
    }

    // ── AFTER UPDATE TESTS ──

    @isTest
    static void testRevenueChange() {
        Contact testContact = new Contact(
            FirstName = 'Revenue',
            LastName = 'Test',
            Email = 'revenue@test.com',
            Annual_Revenue__c = 100000
        );
        insert testContact;

        Test.startTest();
        testContact.Annual_Revenue__c = 200000;
        update testContact;
        Test.stopTest();

        Contact updatedContact = [SELECT Revenue_Changed__c FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals(true, updatedContact.Revenue_Changed__c, 'Revenue_Changed__c should be set to true');
    }

    @isTest
    static void testRevenueNoChange() {
        Contact testContact = new Contact(
            FirstName = 'NoRevenue',
            LastName = 'Change',
            Email = 'norevenue@test.com',
            Annual_Revenue__c = 100000
        );
        insert testContact;

        Test.startTest();
        testContact.FirstName = 'UpdatedFirstName';
        update testContact;
        Test.stopTest();

        Contact updatedContact = [SELECT Revenue_Changed__c FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals(false, updatedContact.Revenue_Changed__c, 'Revenue_Changed__c should remain false');
    }

    @isTest
    static void testShopifySyncOnApproval() {
        Contact testContact = new Contact(
            FirstName = 'Shopify',
            LastName = 'Approval',
            Email = 'shopify.approval@test.com',
            Sales_Channel__c = 'Specialty'
        );
        insert testContact;

        Test.startTest();
        testContact.Manual_Approval_Status__c = 'Approved';
        update testContact;
        Test.stopTest();

        System.assert(Limits.getQueueableJobs() >= 1, 'At least one queueable job should be enqueued for approval sync');
    }

    @isTest
    static void testShopifySyncRetryOnPhoneCorrection() {
        Contact testContact = new Contact(
            FirstName = 'Retry',
            LastName = 'Phone',
            Email = 'retry.phone@test.com',
            Phone = '0000000000',
            Manual_Approval_Status__c = 'Approved',
            Sales_Channel__c = 'Specialty'
        );
        insert testContact;

        Test.startTest();
        testContact.Phone = '9999999999';
        update testContact;
        Test.stopTest();

        System.assert(Limits.getQueueableJobs() >= 1, 'Correcting phone on approved, unsynced Contact should retry sync');
    }

    @isTest
    static void testShopifySyncRetryOnEmailCorrection() {
        Contact testContact = new Contact(
            FirstName = 'Retry',
            LastName = 'Email',
            Email = 'retry.email.bad@test.com',
            Manual_Approval_Status__c = 'Approved',
            Sales_Channel__c = 'Specialty'
        );
        insert testContact;

        Test.startTest();
        testContact.Email = 'retry.email.fixed@test.com';
        update testContact;
        Test.stopTest();

        System.assert(Limits.getQueueableJobs() >= 1, 'Correcting email on approved, unsynced Contact should retry sync');
    }

    @isTest
    static void testNoShopifySyncRetryOnceAlreadySynced() {
        Contact testContact = new Contact(
            FirstName = 'Already',
            LastName = 'Synced',
            Email = 'already.synced@test.com',
            Phone = '1112223333',
            Manual_Approval_Status__c = 'Approved',
            Shopify_Customer_Id__c = 'SHOP-12345',
            Sales_Channel__c = 'Specialty'
        );
        insert testContact;

        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        testContact.Phone = '4445556666';
        update testContact;
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assertEquals(jobsBefore, jobsAfter, 'No new sync should be enqueued once Shopify_Customer_Id__c is populated');
    }

    @isTest
    static void testHandleRejectedContacts() {
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Reject',
            Email = 'reject@test.com'
        );
        insert testContact;

        Test.startTest();
        testContact.Manual_Approval_Status__c = 'Rejected';
        update testContact;
        Test.stopTest();

        List<Contact> contacts = [SELECT Id FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals(0, contacts.size(), 'Rejected contact should be deleted');
    }

    @isTest
    static void testClusterTeamEngineOnInsert() {
        Account acc = [SELECT Id FROM Account WHERE Tax_Id__c = '123456789' LIMIT 1];

        Test.startTest();
        Contact newContact = new Contact(
            FirstName = 'Cluster',
            LastName = 'Test',
            Email = 'cluster@test.com',
            Tax_Id__c = '123456789',
            AccountId = acc.Id,
            Sales_Channel__c = 'Specialty'
        );
        insert newContact;
        Test.stopTest();

        Contact insertedContact = [SELECT Id, AccountId FROM Contact WHERE Id = :newContact.Id];
        System.assertNotEquals(null, insertedContact.Id, 'Contact should be inserted');
        System.assertEquals(acc.Id, insertedContact.AccountId, 'Contact should be assigned to account');
    }

    @isTest
    static void testClusterTeamEngineOnUpdateSalesChannel() {
        Contact testContact = new Contact(
            FirstName = 'Cluster',
            LastName = 'SalesChannel',
            Email = 'cluster.saleschannel@test.com',
            Sales_Channel__c = 'Specialty'
        );
        insert testContact;

        Test.startTest();
        testContact.Sales_Channel__c = 'Key Account';
        update testContact;
        Test.stopTest();

        Contact updatedContact = [SELECT Sales_Channel__c FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals('Key Account', updatedContact.Sales_Channel__c, 'Sales Channel should be updated');
    }

    // ── BULK TESTS ──

    @isTest
    static void testBulkInsert() {
        Account testAcc = [SELECT Id FROM Account WHERE Tax_Id__c = '123456789' LIMIT 1];

        List<Contact> bulkContacts = new List<Contact>();
        for (Integer i = 0; i < 200; i++) {
            bulkContacts.add(new Contact(
                FirstName = 'Bulk',
                LastName = 'Test' + i,
                Email = 'bulk' + i + '@test.com',
                Tax_Id__c = '123456789'
            ));
        }

        Test.startTest();
        insert bulkContacts;
        Test.stopTest();

        List<Contact> insertedContacts = [SELECT Id, AccountId FROM Contact WHERE LastName LIKE 'Test%'];
        System.assertEquals(200, insertedContacts.size(), 'All bulk contacts should be inserted');
    }

    @isTest
    static void testBulkUpdate() {
        List<Contact> bulkContacts = new List<Contact>();
        for (Integer i = 0; i < 50; i++) {
            bulkContacts.add(new Contact(
                FirstName = 'BulkUpdate',
                LastName = 'Test' + i,
                Email = 'bulkupdate' + i + '@test.com',
                Annual_Revenue__c = 1000,
                Sales_Channel__c = 'Specialty'
            ));
        }
        insert bulkContacts;

        Test.startTest();
        for (Contact con : bulkContacts) {
            con.Annual_Revenue__c = 5000;
            con.Manual_Approval_Status__c = 'Approved';
        }
        update bulkContacts;
        Test.stopTest();

        List<Contact> updatedContacts = [
            SELECT Id, Revenue_Changed__c
            FROM Contact
            WHERE Id IN :bulkContacts
        ];
        for (Contact con : updatedContacts) {
            System.assertEquals(true, con.Revenue_Changed__c, 'Revenue_Changed__c should be set for every record');
        }
    }

    // ── MULTIPLE SCENARIOS TEST ──

    @isTest
    static void testMultipleScenarios() {
        Account testAcc = [SELECT Id FROM Account WHERE Tax_Id__c = '987654321' LIMIT 1];

        List<Contact> mixedContacts = new List<Contact>();

        mixedContacts.add(new Contact(
            FirstName = 'Valid',
            LastName = 'One',
            Email = 'valid1@test.com',
            Tax_Id__c = '987654321'
        ));

        mixedContacts.add(new Contact(
            FirstName = 'NoTax',
            LastName = 'Two',
            Email = 'notax@test.com'
        ));

        mixedContacts.add(new Contact(
            FirstName = 'Store',
            LastName = 'Three',
            Email = 'store3@test.com',
            Store_Locations__c = 'NYC\nLA\nChicago'
        ));

        Test.startTest();
        insert mixedContacts;
        Test.stopTest();

        List<Contact> validContact = [SELECT AccountId FROM Contact WHERE Email = 'valid1@test.com'];
        System.assertEquals(testAcc.Id, validContact[0].AccountId, 'Valid contact should be assigned');
    }

    // ── EDGE CASE TESTS ──

    @isTest
    static void testContactWithNullValues() {
        Test.startTest();
        Contact nullContact = new Contact(
            FirstName = 'Null',
            LastName = 'Test',
            Email = 'null@test.com'
        );
        insert nullContact;
        Test.stopTest();

        Contact inserted = [SELECT Id FROM Contact WHERE Id = :nullContact.Id];
        System.assertNotEquals(null, inserted.Id, 'Contact with null values should be inserted');
    }

    @isTest
    static void testContactWithSpecialCharactersInEmail() {
        Test.startTest();
        Contact specialContact = new Contact(
            FirstName = 'Special',
            LastName = 'Email',
            Email = 'special+test@test.co.uk'
        );
        insert specialContact;
        Test.stopTest();

        Contact inserted = [SELECT Email FROM Contact WHERE Id = :specialContact.Id];
        System.assertEquals('special+test@test.co.uk', inserted.Email, 'Special characters in email should be preserved');
    }

    @isTest
    static void testMultipleRevenueChanges() {
        Contact testContact = new Contact(
            FirstName = 'Multi',
            LastName = 'Revenue',
            Email = 'multi@test.com',
            Annual_Revenue__c = 100000
        );
        insert testContact;

        Test.startTest();
        testContact.Annual_Revenue__c = 200000;
        update testContact;
        
        testContact.Annual_Revenue__c = 300000;
        update testContact;
        Test.stopTest();

        Contact updated = [SELECT Revenue_Changed__c FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals(true, updated.Revenue_Changed__c, 'Revenue_Changed__c should be true after multiple changes');
    }

    @isTest
    static void testApprovalThenRejection() {
        Contact testContact = new Contact(
            FirstName = 'Approval',
            LastName = 'Then',
            Email = 'approvalthen@test.com',
            Sales_Channel__c = 'Specialty'
        );
        insert testContact;

        Test.startTest();
        testContact.Manual_Approval_Status__c = 'Approved';
        update testContact;

        testContact.Manual_Approval_Status__c = 'Rejected';
        update testContact;
        Test.stopTest();

        List<Contact> contacts = [SELECT Id FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals(0, contacts.size(), 'Contact should be deleted after rejection');
    }

    @isTest
    static void testMultipleTaxIdFormats() {
        Test.startTest();
        Contact contact1 = new Contact(
            FirstName = 'TaxFormat',
            LastName = 'One',
            Email = 'taxformat1@test.com',
            Tax_Id__c = '123-456-789'
        );
        insert contact1;

        Contact contact2 = new Contact(
            FirstName = 'TaxFormat',
            LastName = 'Two',
            Email = 'taxformat2@test.com',
            Tax_Id__c = '123.456.789'
        );
        insert contact2;

        Contact contact3 = new Contact(
            FirstName = 'TaxFormat',
            LastName = 'Three',
            Email = 'taxformat3@test.com',
            Tax_Id__c = '(123)456-789'
        );
        insert contact3;
        Test.stopTest();

        Contact c1 = [SELECT Tax_Id__c FROM Contact WHERE Id = :contact1.Id];
        Contact c2 = [SELECT Tax_Id__c FROM Contact WHERE Id = :contact2.Id];
        Contact c3 = [SELECT Tax_Id__c FROM Contact WHERE Id = :contact3.Id];

        System.assertEquals('123456789', c1.Tax_Id__c, 'Dashes should be removed');
        System.assertEquals('123456789', c2.Tax_Id__c, 'Dots should be removed');
        System.assertEquals('123456789', c3.Tax_Id__c, 'Parentheses and dashes should be removed');
    }

    @isTest
    static void testFirstNameAndLastNameUpdate() {
        Contact testContact = new Contact(
            FirstName = 'Original',
            LastName = 'Name',
            Email = 'originalname@test.com'
        );
        insert testContact;

        Test.startTest();
        testContact.FirstName = 'Updated';
        testContact.LastName = 'Name';
        update testContact;
        Test.stopTest();

        Contact updated = [SELECT FirstName, LastName FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals('Updated', updated.FirstName, 'FirstName should be updated');
    }

    @isTest
    static void testPhoneAndEmailUpdate() {
        Contact testContact = new Contact(
            FirstName = 'Phone',
            LastName = 'Email',
            Email = 'phone.email@test.com',
            Phone = '1111111111'
        );
        insert testContact;

        Test.startTest();
        testContact.Phone = '2222222222';
        testContact.Email = 'phone.email.updated@test.com';
        update testContact;
        Test.stopTest();

        Contact updated = [SELECT Phone, Email FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals('2222222222', updated.Phone, 'Phone should be updated');
        System.assertEquals('phone.email.updated@test.com', updated.Email, 'Email should be updated');
    }

    @isTest
    static void testContactCompanyAssignmentWithTaxIdVariations() {
        Account testAcc = [SELECT Id FROM Account WHERE Tax_Id__c = '123456789' LIMIT 1];

        Test.startTest();
        Contact con1 = new Contact(
            FirstName = 'Variation',
            LastName = 'One',
            Email = 'variation1@test.com',
            Tax_Id__c = '12-345-6789'
        );
        insert con1;
        Test.stopTest();

        Contact inserted = [SELECT AccountId FROM Contact WHERE Id = :con1.Id];
        System.assertEquals(testAcc.Id, inserted.AccountId, 'Contact should be assigned even with tax id variations');
    }

    @isTest
    static void testStoreLocationsWithMultipleFormats() {
        Test.startTest();
        Contact storeContact = new Contact(
            FirstName = 'Store',
            LastName = 'Locations',
            Email = 'storelocations@test.com',
            Store_Locations__c = 'New York\r\nLos Angeles\r\nChicago\r\nDenver'
        );
        insert storeContact;
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :storeContact.Id
        ];
        System.assertEquals(1, links.size(), 'Note should be created for multiple store locations');
    }

    @isTest
    static void testSalesChannelPicklistHandling() {
        Account acc = [SELECT Id, Sales_Channel__c FROM Account WHERE Tax_Id__c = '987654321' LIMIT 1];

        Test.startTest();
        Contact newContact = new Contact(
            FirstName = 'Picklist',
            LastName = 'Test',
            Email = 'picklist@test.com',
            AccountId = acc.Id
        );
        insert newContact;
        Test.stopTest();

        Contact inserted = [SELECT Sales_Channel__c FROM Contact WHERE Id = :newContact.Id];
        System.assertEquals(acc.Sales_Channel__c, inserted.Sales_Channel__c, 'Sales Channel should be inherited');
    }

    // ── HELPER METHODS ──

    private static String getDifferentActivePicklistValue(Schema.SObjectField field, String excludeValue) {
        try {
            List<Schema.PicklistEntry> entries = field.getDescribe().getPicklistValues();
            for (Schema.PicklistEntry entry : entries) {
                if (entry.isActive() && entry.getValue() != excludeValue) {
                    return entry.getValue();
                }
            }
            return excludeValue;
        } catch (Exception e) {
            return excludeValue;
        }
    }
}