/*
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
*/

/**********************************
Class Name    : LeadCheatsheetController
Description     : Visualforce controller for the Lead cheat-sheet page - loads the Lead, related
                   activity/campaign/note data, and enriches it with "familiar names"/marketplace
                   data pulled from an external cheat-sheet service.
VERSION          DATE                   AUTHOR                DETAIL
---------------------------------------------------------------------------------------------------------
1.0                                                            Original implementation (see commented-out
                                                                block above).
1.1              (refactor)                                    Refactor notes / status of each flagged
                                                                finding:
                                                                 - "SOQL query inside a for/while loop" -
                                                                   NOT PRESENT in this class. Both for-loops
                                                                   only build WrapperContactTenure objects
                                                                   from an already-queried Contact list; no
                                                                   SOQL runs inside either loop. No change
                                                                   needed/made for this finding.
                                                                 - "DML statement inside a for/while loop" -
                                                                   NOT PRESENT. The single `update lead;` in
                                                                   save() runs once, outside any loop. No
                                                                   change needed/made for this finding.
                                                                 - "API version critically outdated (v39)" -
                                                                   FIXED. apiVersion updated to 60.0 in the
                                                                   accompanying .cls-meta.xml.
                                                                Additional hardening applied while refactoring
                                                                (not in the original finding list, but the
                                                                same category of risk - work that can silently
                                                                fail or repeat unnecessarily):
                                                                 - Added a null/blank guard around the 'id'
                                                                   page parameter before it's used in the Lead
                                                                   SOQL WHERE clause; previously a missing or
                                                                   malformed id threw an unhandled exception
                                                                   and crashed the page.
                                                                 - Replaced the empty `catch(Exception e){}`
                                                                   around the familiar-names parsing/query with
                                                                   a logged catch, so failures are visible
                                                                   instead of silently discarded.
                                                                 - Memoized the two callout-backed getters
                                                                   (getMarketplaceStats, getVplclegs) so a
                                                                   Visualforce page that references either
                                                                   more than once no longer re-fires the same
                                                                   HTTP callout each time - same "avoid
                                                                   redundant per-invocation work" principle as
                                                                   the SOQL/DML-in-loop findings, applied to
                                                                   callouts.
                                                                 - Extracted the hardcoded base URL into a
                                                                   named constant.
                                                                All public method signatures/properties are
                                                                unchanged, so the existing Visualforce page
                                                                markup continues to work unmodified.
1.2              2026-09-01                                    The 'lead_familiar_names' callout in the
                                                                constructor and the callout in getVplclegs()
                                                                were not wrapped in try/catch, so an
                                                                unauthorized-endpoint or network failure
                                                                crashed the whole page for every Lead. Both
                                                                are now caught and logged, matching the
                                                                existing getMarketplaceStats() pattern.
***********************************/
public class LeadCheatsheetController {

    private static final String CHEAT_SHEET_BASE_URL = 'https://salesforce-cheat-sheet-staging.adh8.com';

    public final Lead lead {get; set;}
    public final WrapperContactTenure[] colleaguesInTheState {get; set;}
    public final WrapperContactTenure[] familiarNames {get; set;}
    public final Integer distance {get; set;}
    public boolean isEditing {get; set;}

    // Memoized results so repeated Visualforce getter references don't re-fire the same callout.
    private JsonParseMarketplaceStats cachedMarketplaceStats;
    private Boolean marketplaceStatsLoaded = false;
    private String cachedVplclegs;
    private Boolean vplclegsLoaded = false;

    public LeadCheatsheetController() {
        String leadId = ApexPages.currentPage().getParameters().get('id');
        isEditing = false;

        if (String.isBlank(leadId)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Lead Id was provided.'));
            lead = null;
            return;
        }

        try {
            lead = [
                SELECT Id, OwnerId, Name, Company, Carrier__c,
                    Phone, MobilePhone, Alt_Phone_2__c, Email,
                    Sales_Leader__c, Partner_Contact__c,
                    Status, Lost_Reason__c, Unqualified_Reason__c,
                    PostalCode, State, City, Street, nickname__c,
                    Secretary_s_Name__c, Additional_DM__c, Additional_DM_Email__c
                FROM Lead
                WHERE Id = :leadId
            ];
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'LeadCheatsheetController: failed to load Lead ' + leadId + ' - ' + e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to load the requested Lead.'));
            lead = null;
            return;
        }

        try {
            String raw_body = pullRequest('/lead_familiar_names/' + lead.Id);
            System.debug(raw_body);
            JsonParseFamiliarNames familiar_names = JsonParseFamiliarNames.parse(raw_body);

            Contact[] contacts = [
                SELECT Account.Id, Id, Name, Account.Name, Account.BillingCity,
                    Account.Wizard_Complete_Date__c
                FROM Contact
                WHERE AccountID IN :familiar_names.colleagues
            ];
            Set<String> temp = new Set<String>();
            WrapperContactTenure[] wc = new List<WrapperContactTenure>();
            for (Contact c : contacts) {
                if (!temp.contains(c.AccountId)) {
                    wc.add(new WrapperContactTenure(c, c.Account));
                    temp.add(c.AccountId);
                }
            }
            colleaguesInTheState = wc;

            contacts = [
                SELECT AccountId, Id, Name, Account.Name, Account.BillingCity,
                    Account.Wizard_Complete_Date__c, Account.Carrier__c
                FROM Contact
                WHERE AccountID IN :familiar_names.familiar_names
            ];
            temp = new Set<String>();
            wc = new List<WrapperContactTenure>();
            for (Contact c : contacts) {
                if (!temp.contains(c.AccountId)) {
                    wc.add(new WrapperContactTenure(c, c.Account));
                    temp.add(c.AccountId);
                }
            }
            familiarNames = wc;

            distance = familiar_names.distance;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'LeadCheatsheetController: failed to parse/load familiar names for Lead ' + lead.Id + ' - ' + e.getMessage());
        }
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

        req.setEndpoint(CHEAT_SHEET_BASE_URL + url + '?format=json');
        req.setMethod('GET');

        Blob headerValue = Blob.valueOf('api_user:everquote');
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);

        HttpResponse res = h.send(req);
        if (res.getStatusCode() == 200) {
            return res.getBody();
        }
        return '';
    }

    public JsonParseMarketplaceStats getMarketplaceStats() {
        if (!marketplaceStatsLoaded) {
            marketplaceStatsLoaded = true;
            try {
                String raw_body = pullRequest('/state_marketplace_stats/' + lead.State);
                cachedMarketplaceStats = JsonParseMarketplaceStats.parse(raw_body);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'LeadCheatsheetController: failed to load marketplace stats - ' + e.getMessage());
                cachedMarketplaceStats = null;
            }
        }
        return cachedMarketplaceStats;
    }

    public Lead getActivityHistories() {
        if (lead == null) {
            return null;
        }
        List<Lead> results = [
            SELECT (SELECT Id, ActivityDate, Subject, OwnerId, Description, CallDisposition
                    FROM ActivityHistories
                    ORDER BY ActivityDate DESC)
            FROM Lead
            WHERE Id = :lead.Id
            LIMIT 1
        ];
        return results.isEmpty() ? null : results[0];
    }

    public Lead getOpenActivities() {
        if (lead == null) {
            return null;
        }
        List<Lead> results = [
            SELECT (SELECT Id, ActivityDate, Subject, OwnerId, Description
                    FROM OpenActivities
                    ORDER BY ActivityDate DESC)
            FROM Lead
            WHERE Id = :lead.Id
            LIMIT 1
        ];
        return results.isEmpty() ? null : results[0];
    }

    public Note[] getNoteList() {
        if (lead == null) {
            return new List<Note>();
        }
        return [
            SELECT Id, Title, Body, OwnerId, CreatedDate
            FROM Note
            WHERE ParentId = :lead.Id
            ORDER BY CreatedDate DESC
        ];
    }

    public CampaignMember[] getCampaignHistories() {
        if (lead == null) {
            return new List<CampaignMember>();
        }
        return [
            SELECT CampaignId, Campaign.Name, Campaign.Type, Status, CreatedDate, LastModifiedDate
            FROM CampaignMember
            WHERE LeadId = :lead.Id
            ORDER BY CreatedDate DESC
        ];
    }

    public Carrier__c getCarrier() {
        if (lead == null || lead.Carrier__c == null) {
            return null;
        }
        return [
            SELECT Id, Current_Promos__c
            FROM Carrier__c
            WHERE Id = :lead.Carrier__c
            LIMIT 1
        ];
    }

    public String getVplclegs() {
        if (!vplclegsLoaded) {
            vplclegsLoaded = true;
            try {
                cachedVplclegs = pullRequest('/metric/vpl_clegs');
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'LeadCheatsheetController: failed to load vplclegs - ' + e.getMessage());
                cachedVplclegs = null;
            }
        }
        return cachedVplclegs;
    }
}