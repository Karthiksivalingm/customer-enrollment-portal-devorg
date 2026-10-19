@isTest
public class AssignLeadToCadencesBatchTest {
	@isTest
    public static void AssignLeadToCadencesBatchTest(){
        
        Test.setMock(HttpCalloutMock.class, new mockResponse());
        Id userRoleId = [SELECT Id FROM UserRole WHERE Name = 'Core Outbound Business Development Rep'].Id;
        User u1 = new User(
            ProfileId = UserInfo.getProfileId(),
            LastName = 'last7',
            Email = 'puser007+test@everquote.ai',
            Username = 'puser007+test@everquote.ai' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Life_Buyer__c = true,
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            UserRoleId = userRoleId,
            Work_Item_Amount__c = 131,
            Odie_Agent_ID__c = Integer.valueof((Math.random() * 100123)),
            Carrier__c = 'Allstate'
        );
        System.runAs(u1){
            
            
            Carrier__c cr = new Carrier__c();
            cr.Name = 'Allstate';
            insert cr;
            
            Lead testLead1 = new Lead(
                FirstName = 'Test',
                LastName = 'Lead1',
                Company = 'Test Company',
                Status = 'Lost Reason',
                Lost_Reason__c = 'Recycled',
                Unqualified_Reason__c = 'Consumer',
                LeadSource = 'Web Scrape',
                mkto71_Lead_Score__c = 90,
                DoNotCall = false,
                HasOptedOutOfEmail = false,
                Carrier__c = cr.Id
            );
        
        	insert testLead1;
            
            Task tsk = new task();
            tsk.Subject = 'test';
            tsk.ActivityDate = System.today().addDays(10);
            tsk.WhoId = testLead1.Id;
            insert tsk;
            
            Test.startTest();
            AssignLeadToCadencesBatch b = new AssignLeadToCadencesBatch(u1.Id);
            database.executebatch(b);
            Test.stopTest();
        }
    }
    
    
    public class mockResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {    
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setStatusCode(200);
            return res;
        }
    }
}