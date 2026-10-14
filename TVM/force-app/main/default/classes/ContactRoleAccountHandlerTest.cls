@IsTest
public class ContactRoleAccountHandlerTest {

    // =====================================================
    // Test 1: Insert, Update, Move, Delete, Undelete
    // =====================================================
    @IsTest
    static void testInsertUpdateMoveDeleteUndelete() {

        Test.setMock(HttpCalloutMock.class, new GenericHttpCalloutMock());

        // Create Accounts
        Account acc1 = new Account(Name = 'Account One');
        Account acc2 = new Account(Name = 'Account Two');
        insert new List<Account>{ acc1, acc2 };

        // Create Contacts
        Contact primaryCon = new Contact(
            LastName = 'Primary',
            AccountId = acc1.Id,
            Contact_Role__c = 'Foundation Primary'
        );

        Contact secondaryCon = new Contact(
            LastName = 'Secondary',
            AccountId = acc1.Id,
            Contact_Role__c = 'Foundation Secondary'
        );

        Test.startTest();

        // INSERT
        insert new List<Contact>{ primaryCon, secondaryCon };

        // UPDATE to both roles
        primaryCon.Contact_Role__c = 'Foundation Primary;Foundation Secondary';
        update primaryCon;

        // MOVE to another account
        primaryCon.AccountId = acc2.Id;
        update primaryCon;

        // DELETE
        delete secondaryCon;

        // UNDELETE
        undelete secondaryCon;

        Test.stopTest();

        // Reload Accounts
        acc1 = [
            SELECT Primary_Contact__c, Secondary_Contact__c
            FROM Account WHERE Id = :acc1.Id
        ];

        acc2 = [
            SELECT Primary_Contact__c, Secondary_Contact__c
            FROM Account WHERE Id = :acc2.Id
        ];

        // ---------------- Assertions ----------------

        // Account 2 should have both roles because contact has both
        System.assertEquals(primaryCon.Id, acc2.Primary_Contact__c,
            'Account 2 primary should be moved contact');

        System.assertEquals(primaryCon.Id, acc2.Secondary_Contact__c,
            'Account 2 secondary should also be moved contact');

        // Account 1 should still have secondary after undelete
        System.assertNotEquals(null, acc1.Secondary_Contact__c,
            'Account 1 secondary should be restored');

    }


    // =====================================================
    // Test 2: Only Primary
    // =====================================================
    @IsTest
    static void testOnlyPrimaryScenario() {

        Test.setMock(HttpCalloutMock.class, new GenericHttpCalloutMock());

        Account acc = new Account(Name = 'Primary Only');
        insert acc;

        Contact con = new Contact(
            LastName = 'OnlyPrimary',
            AccountId = acc.Id,
            Contact_Role__c = 'Foundation Primary'
        );

        Test.startTest();
        insert con;
        Test.stopTest();

        acc = [
            SELECT Primary_Contact__c, Secondary_Contact__c
            FROM Account WHERE Id = :acc.Id
        ];

        System.assertEquals(con.Id, acc.Primary_Contact__c);
        System.assertEquals(null, acc.Secondary_Contact__c);
    }


    // =====================================================
    // Test 3: Only Secondary
    // =====================================================
    @IsTest
    static void testOnlySecondaryScenario() {

        Test.setMock(HttpCalloutMock.class, new GenericHttpCalloutMock());

        Account acc = new Account(Name = 'Secondary Only');
        insert acc;

        Contact con = new Contact(
            LastName = 'OnlySecondary',
            AccountId = acc.Id,
            Contact_Role__c = 'Foundation Secondary'
        );

        Test.startTest();
        insert con;
        Test.stopTest();

        acc = [
            SELECT Primary_Contact__c, Secondary_Contact__c
            FROM Account WHERE Id = :acc.Id
        ];

        System.assertEquals(null, acc.Primary_Contact__c);
        System.assertEquals(con.Id, acc.Secondary_Contact__c);
    }


    // =====================================================
    // Test 4: Bulk Test (Stress)
    // =====================================================
    @IsTest
    static void testBulkScenario() {

        Test.setMock(HttpCalloutMock.class, new GenericHttpCalloutMock());

        Account acc = new Account(Name = 'Bulk Account');
        insert acc;

       List<Contact> contacts = new List<Contact>();

for (Integer i = 0; i < 200; i++) {

    String role;

    if (Math.mod(i, 2) == 0) {
        role = 'Foundation Primary';
    } else {
        role = 'Foundation Secondary';
    }

    contacts.add(new Contact(
        LastName = 'Bulk ' + i,
        AccountId = acc.Id,
        Contact_Role__c = role
    ));
}
       

        Test.startTest();
        insert contacts;
        Test.stopTest();

        acc = [
            SELECT Primary_Contact__c, Secondary_Contact__c
            FROM Account WHERE Id = :acc.Id
        ];

        System.assertNotEquals(null, acc.Primary_Contact__c);
        System.assertNotEquals(null, acc.Secondary_Contact__c);
    }
}