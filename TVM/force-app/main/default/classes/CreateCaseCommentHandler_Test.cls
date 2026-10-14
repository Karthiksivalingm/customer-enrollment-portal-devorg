@isTest
public class CreateCaseCommentHandler_Test {

    private static String uniqueSuffix() {        
        Integer rnd = Math.abs(Math.mod(Math.abs(Crypto.getRandomInteger()), 1000000));
        return String.valueOf(rnd);
    }

    private static User createFoundationUser() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'fuser', // fixed short alias
            Email = 'foundation' + uniqueSuffix() + '@example.com',
            Username = 'foundation' + uniqueSuffix() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'Foundation',
            LastName = 'Tester',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            ProfileId = profile.Id,
            IsActive = true
        );
        insert u;
        return u;
    }

    private static User createAdminUser() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User u = new User(
            Alias = 'adm' + String.valueOf(Math.mod(Crypto.getRandomInteger(), 1000)), // max 8 chars
            Email = 'admin' + uniqueSuffix() + '@example.com',
            Username = 'admin' + uniqueSuffix() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'Admin',
            LastName = 'User',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            ProfileId = profile.Id,
            IsActive = true
        );
        insert u;
        return u;
    }

    @isTest
    public static void testFoundationCaseCommentCreation() {
        String suf = uniqueSuffix();
        User foundationUser = createFoundationUser();
        User adminUser = createAdminUser();

        // Insert Account as Admin to bypass validation
        Account acc;
        System.runAs(adminUser) {
            acc = new Account(
                Name='Demo Account ' + suf,
                Quickbase_Record_ID__c = suf
            );
            insert acc;
        }

        // Insert Case + FeedItem as Foundation user
        System.runAs(foundationUser) {
            Case testCase = new Case(
                AccountId = acc.Id,
                Priority='High',
                Status='New',
                Origin='Web',
                Subject='Foundation Case ' + suf,
                Creator_Override__c = foundationUser.Id,
                Case_Category__c = 'Foundation Digital Support'
            );
            insert testCase;

            FeedItem fi = new FeedItem(
                ParentId = testCase.Id,
                Body='<b>Hello Foundation</b> Comment'
            );

            Test.startTest();
            insert fi; // triggers your handler
            Test.stopTest();

            List<CaseComment> comments = [SELECT Id, CommentBody FROM CaseComment WHERE ParentId = :testCase.Id];
            System.assertEquals(1, comments.size(), 'Expected 1 CaseComment');
            System.assert(comments[0].CommentBody.contains('Hello Foundation'), 'HTML stripped properly');
        }
    }
}