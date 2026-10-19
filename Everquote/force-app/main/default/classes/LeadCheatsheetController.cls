public class LeadCheatsheetController {
    public final Lead lead {get; set;}
    public final WrapperContactTenure[] colleaguesInTheState {get; set;}
    public final WrapperContactTenure[] familiarNames {get; set;}
    public final Integer distance {get; set;}
    public boolean isEditing {get; set;}

    public LeadCheatsheetController() {
        lead = [SELECT Id, OwnerId, Name, Company, Carrier__c,
                Phone, MobilePhone, Alt_Phone_2__c, Email,
                Sales_Leader__c, Partner_Contact__c,
                Status, Lost_Reason__c, Unqualified_Reason__c,
                PostalCode, State, City, Street, nickname__c, 	Secretary_s_Name__c, 	Additional_DM__c, Additional_DM_Email__c
                FROM Lead
                WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
        isEditing = false;
        
        String raw_body = pullRequest('/lead_familiar_names/' + lead.Id);
        System.debug(raw_body);
        try {
            JsonParseFamiliarNames familiar_names = JsonParseFamiliarNames.parse(raw_body);
            
            Contact[] contacts = [SELECT Account.Id, Id, Name, Account.Name, Account.BillingCity, 
                                  Account.Wizard_Complete_Date__c 
                                  FROM Contact 
                                  WHERE AccountID IN :familiar_names.colleagues];
            Set<String> temp = new Set<String>();
            WrapperContactTenure[] wc = new List<WrapperContactTenure>();
            for(Contact c: contacts) {
                if(!temp.contains(c.AccountId)){
                    wc.add(new WrapperContactTenure(c, c.Account));
                    temp.add(c.AccountId);
                }
            }
            colleaguesInTheState = wc;
            
            contacts = [SELECT AccountId, Id, Name, Account.Name, Account.BillingCity, 
                        Account.Wizard_Complete_Date__c, Account.Carrier__c
                        FROM Contact 
                        WHERE AccountID IN :familiar_names.familiar_names];
            temp = new Set<String>();
            wc = new List<WrapperContactTenure>();
            for(Contact c: contacts) {
                if(!temp.contains(c.AccountId)){
                	wc.add(new WrapperContactTenure(c, c.Account));
                    temp.add(c.AccountId);
                }
            }
            familiarNames = wc;
            
            distance = familiar_names.distance;
        }
        catch(Exception e) {}
    }
    
    public PageReference save() {
        update lead;
        PageReference pageRef = ApexPages.currentPage();
        pageRef.setRedirect(true);
        return pageRef;
    }
	
    public PageReference edit() {
        isEditing = true;
        return null;
    }
    
    public PageReference cancel() {
        isEditing = false;
        return null;
    }
    
    public String pullRequest(String url) {
        Http h = new Http();
		HttpRequest req = new HttpRequest();
        
        String base_url = 'https://salesforce-cheat-sheet-staging.adh8.com';
        req.setEndpoint(base_url + url + '?format=json');
	    req.setMethod('GET');
        
        Blob headerValue = Blob.valueOf('api_user:everquote');
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
		req.setHeader('Authorization', authorizationHeader);
        
        HttpResponse res = h.send(req);
        if(res.getStatusCode() == 200){
            return res.getBody();            
        }
        return '';
    }
    
    public JsonParseMarketplaceStats getMarketplaceStats() {
        String raw_body = pullRequest('/state_marketplace_stats/' + lead.State);
        try {
        	return JsonParseMarketplaceStats.parse(raw_body);
        }
        catch (Exception e) {
            return null;
        }
    }
    
    public Lead getActivityHistories() {
        return [SELECT (SELECT Id, ActivityDate, Subject, OwnerId, Description, CallDisposition 
                        FROM ActivityHistories
                        ORDER BY ActivityDate DESC)
                FROM Lead
                WHERE Id = :lead.Id
                LIMIT 1];
    }
    
    public Lead getOpenActivities() {
        return [SELECT (SELECT Id, ActivityDate, Subject, OwnerId, Description 
                        FROM OpenActivities
                        ORDER BY ActivityDate DESC)
                FROM Lead
                WHERE Id = :lead.Id
                LIMIT 1];
    }
    
    public Note[] getNoteList() {
        return [SELECT Id, Title, Body, OwnerId, CreatedDate 
                FROM Note
                WHERE ParentId = :lead.Id
                ORDER BY CreatedDate DESC];
    }
    
    public CampaignMember[] getCampaignHistories() {
        return [SELECT CampaignId, Campaign.Name, Campaign.Type, Status, CreatedDate, LastModifiedDate
                FROM CampaignMember
                WHERE LeadId = :lead.Id
                ORDER BY CreatedDate DESC];
    }
    
    public Carrier__c getCarrier() {
        if(lead.Carrier__c == null)
            return null;
        return [SELECT Id, Current_Promos__c
                FROM Carrier__c
                WHERE Id = :lead.Carrier__c
                LIMIT 1];
    }
    
    public String getVplclegs() {
        return pullRequest('/metric/vpl_clegs');
    }
}