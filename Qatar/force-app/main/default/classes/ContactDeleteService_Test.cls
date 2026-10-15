@IsTest
private class ContactDeleteService_Test {

    @IsTest
    static void testDeleteContact() {
        // Create a contact
        Contact con = new Contact(FirstName = 'Test', LastName = 'User');
        insert con;

        // Call delete method
        Test.startTest();
        ContactDeleteService.deleteContact(con.Id);
        Test.stopTest();

        // Verify the contact is deleted
        Integer countCon = [SELECT count() FROM Contact WHERE Id = :con.Id];
        System.assertEquals(0, countCon, 'Contact should be deleted');
    }

    @IsTest
    static void testDeleteContact_NullId() {
        Test.startTest();
        try {
            ContactDeleteService.deleteContact(null);
            System.assert(false, 'Expected exception for null Id');
        } catch (AuraHandledException e) {
           // System.assert(e.getMessage().contains('Contact Id cannot be null.'));
        }
        Test.stopTest();
    }

    @IsTest
    static void testDeleteContact_InvalidId() {
        Test.startTest();
        try {
            // Non-existent but valid Contact Id format
            ContactDeleteService.deleteContact('003000000000000AAA');
            //System.assert(false, 'Expected exception for non-existent contact');
        } catch (AuraHandledException e) {
//System.assert(e.getMessage().contains('No contact found'));
        }
        Test.stopTest();
    }
}