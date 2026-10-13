public class LeadTriggerHelper {
    public static void CheckLeadScore(List<Lead> leadCollection){
    	for (Lead LeadInstance : leadCollection) {
            if (LeadInstance.mkto71_Lead_Score__c==null && 
                LeadInstance.LeadSource != null &&
                LeadInstance.LeadSource == 'Web Scrape') {
                LeadInstance.mkto71_Lead_Score__c=90;  
            }
        }
    }
}