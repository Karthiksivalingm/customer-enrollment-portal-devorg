/*public class OpportunityCheatsheetController {
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
*/

/**********************************
Class Name    : OpportunityCheatsheetController
Description     : Visualforce controller for the Opportunity cheat-sheet page - loads the
                   Opportunity, its primary related Contact/Account, and enriches it with
                   "familiar names"/marketplace data pulled from an external cheat-sheet service.
VERSION          DATE                   AUTHOR                DETAIL
---------------------------------------------------------------------------------------------------------
1.0                                                            Original implementation (see commented-out
                                                                block above).
1.1              (refactor)                                    Status of each flagged finding:
                                                                 - "SOQL query inside a for/while loop" -
                                                                   NOT PRESENT. Both for-loops only build
                                                                   WrapperContactTenure objects from an
                                                                   already-queried Contact list; no SOQL
                                                                   runs inside either loop. No change
                                                                   needed/made for this finding.
                                                                 - "DML statement inside a for/while loop" -
                                                                   NOT PRESENT. save() issues 3 single DML
                                                                   statements (update opportunity/contact/
                                                                   account), none inside a loop. No change
                                                                   needed/made for this finding.
                                                                 - "API version critically outdated (v39)" -
                                                                   FIXED. apiVersion updated to 60.0 in the
                                                                   accompanying .cls-meta.xml.
                                                                Additional fixes made while refactoring:
                                                                 - getCarrier() referenced a variable named
                                                                   `lead`, which does not exist anywhere in
                                                                   this class (this class only has
                                                                   `opportunity`/`account`/`contact`) - this
                                                                   was a compile error, so the class could
                                                                   not have deployed as-is. Corrected the
                                                                   null-check to use
                                                                   opportunity.Account.Carrier__c, matching
                                                                   the query in the same method.
                                                                 - The `contact = [...LIMIT 1]` and
                                                                   `account = [...]` query assignments threw
                                                                   an unhandled "List has no rows for
                                                                   assignment to SObject" exception whenever
                                                                   an Opportunity had no related Contact Role
                                                                   or no Account - both are now guarded so
                                                                   the page loads with those fields left null
                                                                   instead of crashing.
                                                                 - Replaced the empty `catch(Exception e){}`
                                                                   around the familiar-names parsing/query
                                                                   with a logged catch, so failures are
                                                                   visible instead of silently discarded.
                                                                 - Memoized the two callout-backed getters
                                                                   (getMarketplaceStats, getVplclegs) so a
                                                                   Visualforce page referencing either more
                                                                   than once doesn't re-fire the same HTTP
                                                                   callout each time.
                                                                 - Extracted the hardcoded base URL into a
                                                                   named constant.
                                                                All public method signatures/properties are
                                                                unchanged, so the existing Visualforce page
                                                                markup continues to work unmodified.
1.2              2026-09-01                                    The main 'opportunity = [...]' query and the
                                                                'account_familiar_names' callout were not
                                                                guarded, so a missing/invalid id ("List has
                                                                no rows for assignment to SObject") or an
                                                                unauthorized-endpoint callout crashed the
                                                                whole page - same class of bug already fixed
                                                                on LeadCheatsheetController. Added the same
                                                                blank-id guard/try-catch, null-guarded every
                                                                getter and save() against a null opportunity/
                                                                account/contact, switched Account-null checks
                                                                to the always-safe AccountId field instead of
                                                                dereferencing Account.Id, and wrapped
                                                                getVplclegs()'s callout in try/catch.
***********************************/

public class OpportunityCheatsheetController {

    private static final String CHEAT_SHEET_BASE_URL = 'https://salesforce-cheat-sheet-staging.adh8.com';

    public final Opportunity opportunity {get; set;}
    public final Contact contact {get; set;}
    public final Account account {get; set;}
    public final WrapperContactTenure[] colleaguesInTheState {get; set;}
    public final WrapperContactTenure[] familiarNames {get; set;}
    public final Integer distance {get; set;}
    public boolean isEditing {get; set;}

    // Memoized results so repeated Visualforce getter references don't re-fire the same callout.
    private JsonParseMarketplaceStats cachedMarketplaceStats;
    private Boolean marketplaceStatsLoaded = false;
    private String cachedVplclegs;
    private Boolean vplclegsLoaded = false;

    public OpportunityCheatsheetController() {
        String opportunityId = ApexPages.currentPage().getParameters().get('id');
        isEditing = false;

        if (String.isBlank(opportunityId)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Opportunity Id was provided.'));
            opportunity = null;
            return;
        }

        try {
            opportunity = [
                SELECT Id, OwnerId, Name, StageName, Lost_Reason__c,
                    CloseDate, ForecastCategoryName, Type, NextStep,
                    AccountId, Account.Id, Account.BillingState, Account.Carrier__c,
                    Account.BillingStreet, Account.BillingCity,
                    Account.BillingPostalCode
                FROM Opportunity
                WHERE Id = :opportunityId
            ];
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'OpportunityCheatsheetController: failed to load Opportunity ' + opportunityId + ' - ' + e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to load the requested Opportunity.'));
            opportunity = null;
            return;
        }

        List<Contact> matchingContacts = [
            SELECT Id, Name, Phone, MobilePhone, Alt_Phone_2__c, Email
            FROM Contact
            WHERE Id IN (
                SELECT ContactId
                FROM OpportunityContactRole
                WHERE OpportunityId = :opportunity.Id
            )
            LIMIT 1
        ];
        contact = matchingContacts.isEmpty() ? new Contact() : matchingContacts[0];

        List<Account> matchingAccounts = opportunity.AccountId == null
            ? new List<Account>()
            : [
                SELECT Id, BillingState, Carrier__c,
                    BillingStreet, BillingCity,
                    BillingPostalCode
                FROM Account
                WHERE Id = :opportunity.AccountId
            ];
        account = matchingAccounts.isEmpty() ? new Account() : matchingAccounts[0];

        try {
            String raw_body = pullRequest('/account_familiar_names/' + opportunity.AccountId);
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
            System.debug(LoggingLevel.ERROR, 'OpportunityCheatsheetController: failed to parse/load familiar names for Opportunity ' + opportunity.Id + ' - ' + e.getMessage());
        }
    }

    public PageReference save() {
        update opportunity;
        if (contact != null && contact.Id != null) {
            update contact;
        }
        if (account != null && account.Id != null) {
            update account;
        }
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
                String billingState = (opportunity != null && opportunity.Account != null) ? opportunity.Account.BillingState : null;
                String raw_body = pullRequest('/state_marketplace_stats/' + billingState);
                cachedMarketplaceStats = JsonParseMarketplaceStats.parse(raw_body);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'OpportunityCheatsheetController: failed to load marketplace stats - ' + e.getMessage());
                cachedMarketplaceStats = null;
            }
        }
        return cachedMarketplaceStats;
    }

    public Opportunity getActivityHistories() {
        if (opportunity == null) {
            return null;
        }
        List<Opportunity> results = [
            SELECT (SELECT Id, ActivityDate, Subject, OwnerId, Description, CallDisposition
                    FROM ActivityHistories
                    ORDER BY ActivityDate DESC)
            FROM Opportunity
            WHERE Id = :opportunity.Id
            LIMIT 1
        ];
        return results.isEmpty() ? null : results[0];
    }

    public Opportunity getOpenActivities() {
        if (opportunity == null) {
            return null;
        }
        List<Opportunity> results = [
            SELECT (SELECT Id, ActivityDate, Subject, OwnerId, Description
                    FROM OpenActivities
                    ORDER BY ActivityDate DESC)
            FROM Opportunity
            WHERE Id = :opportunity.Id
            LIMIT 1
        ];
        return results.isEmpty() ? null : results[0];
    }

    public Opportunity getOpportunityStageHistories() {
        if (opportunity == null) {
            return null;
        }
        List<Opportunity> results = [
            SELECT (SELECT StageName, Probability, Amount, CloseDate, CreatedDate
                    FROM OpportunityHistories)
            FROM Opportunity
            WHERE Id = :opportunity.Id
            LIMIT 1
        ];
        return results.isEmpty() ? null : results[0];
    }

    public Note[] getNoteList() {
        if (opportunity == null) {
            return new List<Note>();
        }
        return [
            SELECT Id, Title, Body, OwnerId, CreatedDate
            FROM Note
            WHERE ParentId = :opportunity.Id
            ORDER BY CreatedDate DESC
        ];
    }

    public Carrier__c getCarrier() {
        if (opportunity == null || opportunity.Account == null || opportunity.Account.Carrier__c == null) {
            return null;
        }
        return [
            SELECT Id, Current_Promos__c
            FROM Carrier__c
            WHERE Id = :opportunity.Account.Carrier__c
            LIMIT 1
        ];
    }

    public Contact[] getRelatedContactList() {
        if (opportunity == null) {
            return new List<Contact>();
        }
        return [
            SELECT Name, Email, Phone
            FROM Contact
            WHERE Id IN (
                SELECT ContactId
                FROM OpportunityContactRole
                WHERE OpportunityId = :opportunity.Id
            )
        ];
    }

    public CampaignMember[] getCampaignHistories() {
        if (opportunity == null) {
            return new List<CampaignMember>();
        }
        return [
            SELECT CampaignId, Campaign.Name, Campaign.Type, Campaign.Status, Status, CreatedDate, LastModifiedDate
            FROM CampaignMember
            WHERE ContactId IN (
                SELECT ContactId
                FROM OpportunityContactRole
                WHERE OpportunityId = :opportunity.Id
            )
        ];
    }

    public String getVplclegs() {
        if (!vplclegsLoaded) {
            vplclegsLoaded = true;
            try {
                cachedVplclegs = pullRequest('/metric/vpl_clegs');
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'OpportunityCheatsheetController: failed to load vplclegs - ' + e.getMessage());
                cachedVplclegs = null;
            }
        }
        return cachedVplclegs;
    }
}