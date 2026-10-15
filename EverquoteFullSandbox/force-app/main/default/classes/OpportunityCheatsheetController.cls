public class OpportunityCheatsheetController {
    public final Opportunity opportunity {get; set;}
    public final Contact contact {get; set;}
    public final Account account {get; set;}
    public final WrapperContactTenure[] colleaguesInTheState {get; set;}
    public final WrapperContactTenure[] familiarNames {get; set;}
    public final Integer distance {get; set;}
    public boolean isEditing {get; set;}

    public OpportunityCheatsheetController() {
        opportunity = [SELECT Id, OwnerId, Name, StageName, Lost_Reason__c,
                              CloseDate, ForecastCategoryName, Type, NextStep,
                       		  Account.Id, Account.BillingState, Account.Carrier__c, 
                              Account.BillingStreet, Account.BillingCity, 
                       		  Account.BillingPostalCode                             
                       FROM Opportunity
                       WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
        contact = [SELECT Id, Name, Phone, MobilePhone, Alt_Phone_2__c, Email
                   FROM Contact 
                   WHERE Id in (SELECT ContactId 
                                FROM OpportunityContactRole
                                Where OpportunityId = :opportunity.Id)
                   LIMIT 1];
        
        account = [SELECT Id, Account.BillingState, Account.Carrier__c, 
                          Account.BillingStreet, Account.BillingCity, 
                          Account.BillingPostalCode
                   FROM Account
                   WHERE Id = :opportunity.Account.Id];
        
        isEditing = false;
        
        String raw_body = pullRequest('/account_familiar_names/' + opportunity.Account.Id);
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
        update opportunity;
        update contact;
        update account;
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
        String raw_body = pullRequest('/state_marketplace_stats/' + opportunity.Account.BillingState);
        try {
        	return JsonParseMarketplaceStats.parse(raw_body);
        }
        catch (Exception e) {
            return null;
        }
    }
    
    public Opportunity getActivityHistories() {
        return [SELECT (SELECT Id, ActivityDate, Subject, OwnerId, Description, CallDisposition 
                        FROM ActivityHistories
                        ORDER BY ActivityDate DESC)
                FROM Opportunity
                WHERE Id = :opportunity.Id
                LIMIT 1];
    }
    
    public Opportunity getOpenActivities() {
        return [SELECT (SELECT Id, ActivityDate, Subject, OwnerId, Description 
                        FROM OpenActivities
                        ORDER BY ActivityDate DESC)
                FROM Opportunity
                WHERE Id = :opportunity.Id
                LIMIT 1];
    }
    
    
    public Opportunity getOpportunityStageHistories() {
        return [SELECT (SELECT StageName, Probability, Amount, CloseDate, CreatedDate
                        FROM OpportunityHistories) 
                From Opportunity 
                WHERE Id = :opportunity.Id
			   ];
    }
    
    public Note[] getNoteList() {
        return [SELECT Id, Title, Body, OwnerId, CreatedDate 
                FROM Note
                WHERE ParentId = :opportunity.Id
                ORDER BY CreatedDate DESC];
    }
        
    public Carrier__c getCarrier() {
        if(lead.Carrier__c == null)
            return null;
        return [SELECT Id, Current_Promos__c
                FROM Carrier__c
                WHERE Id = :opportunity.Account.Carrier__c
                LIMIT 1];
    }
    
    public Contact[] getRelatedContactList() {
        return [SELECT Name, Email, Phone
                FROM Contact
                WHERE id in 
                (SELECT ContactId 
                 FROM OpportunityContactRole 
                 where OpportunityId = :opportunity.id)       
        ];
    }
    
    public CampaignMember[] getCampaignHistories() {
        return [SELECT CampaignId, Campaign.Name, Campaign.Type, Campaign.Status, Status, CreatedDate, LastModifiedDate
                FROM CampaignMember
                WHERE ContactId in (SELECT ContactId 
                                    FROM OpportunityContactRole 
                                    WHERE OpportunityId = :opportunity.id)
               ];
    }
    
    public String getVplclegs() {
        return pullRequest('/metric/vpl_clegs');
    }   
}