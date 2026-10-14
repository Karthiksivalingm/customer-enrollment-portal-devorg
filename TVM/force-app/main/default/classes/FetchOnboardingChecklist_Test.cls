//Apex from FND
@isTest
public class FetchOnboardingChecklist_Test {
@isTest
    public static void test(){
        Foundation_Onboarding__c obj = new Foundation_Onboarding__c();
        //obj.Add_CC_to_Bing__c = 'Completed';
        insert obj;
        FetchOnboardingChecklist.fetchOnboarding('4', '2022', null);
        FetchOnboardingChecklist.getMonthFieldValue();
        RecentlyLaunchedAccountController.fetchOnboarding('4', '2022', null);
        RecentlyLaunchedAccountController.getMonthFieldValue();
    }
}