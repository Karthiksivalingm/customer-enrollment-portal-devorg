public with sharing class ATCMonitoringDatesController {
    
    /**
     * Fetches related accounts with ATC Monitoring data for a contact
     * Queries Account objects directly
     * 
     * @param contactId The Contact ID to fetch related accounts
     * @return List of Account data wrapper objects
     */
    @AuraEnabled(cacheable=true)
    public static List<AccountATCDataWrapper> getRelatedAccountsWithATCData(String contactId) {
        List<AccountATCDataWrapper> result = new List<AccountATCDataWrapper>();
        
        try {
            // Validate input
            if (String.isBlank(contactId)) {
                throw new IllegalArgumentException('Contact ID cannot be null or empty');
            }
            
            // Get contact and its primary account
            Contact contact = [
                SELECT Id, AccountId 
                FROM Contact 
                WHERE Id = :contactId 
                LIMIT 1
            ];
            
            // Get all account IDs related to this contact via AccountContactRelation
            Set<Id> accountIds = new Set<Id>();
            
            // Add contact's primary account if exists
            if (contact.AccountId != null) {
                accountIds.add(contact.AccountId);
            }
            
            // Get accounts from AccountContactRelation (Related Accounts)
            List<AccountContactRelation> accountRelations = [
                SELECT AccountId 
                FROM AccountContactRelation 
                WHERE ContactId = :contactId
            ];
            
            for (AccountContactRelation acr : accountRelations) {
                accountIds.add(acr.AccountId);
            }
            
            if (accountIds.isEmpty()) {
                return result;
            }
            
            // Query related accounts with ALL their fields
            List<Account> relatedAccounts = [
                SELECT 
                    Id,
                    Name,
                    ATC_Monitoring_Dates__c,
                    Serviced_By__c,
                    Initial_Service_Date__c,
                    First_ATC_Monitoring_Meeting__c,
                    First_ATC_Monitoring_Meeting_Date__c,
                    First_ATC_Monitoring_Meeting_Type__c,
                    X30_day_ATC_Monitoring_Meeting_Check__c,
                    X30_day_ATC_Monitoring_Meeting_Date__c,
                    X60_Day_ATC_Monitoring_Meeting_Check__c,
                    X60_Day_ATC_Monitoring_Meeting_Date__c,
                    First_90_Day_ATC_Monitoring_Meeting__c,
                    First_90_Day_ATC_Monitoring_Meeting_Date__c,
                    Last_90_Day_ATC_Monitoring_Meeting_Date__c,
                    Next_90_Day_ATC_Monitoring_Meeting_Date__c
                FROM Account
                WHERE Id IN :accountIds
                ORDER BY Name ASC
            ];
            
            // Build wrapper objects
            for (Account acc : relatedAccounts) {
                result.add(new AccountATCDataWrapper(acc));
            }
            
        } catch (QueryException e) {
            System.debug('Query Exception: ' + e.getMessage());
            throw new AuraHandledException('Error querying account data: ' + e.getMessage());
        } catch (IllegalArgumentException e) {
            System.debug('Illegal Argument Exception: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        } catch (Exception e) {
            System.debug('Unexpected Exception: ' + e.getMessage());
            throw new AuraHandledException('An unexpected error occurred: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * Wrapper class to hold Account ATC Monitoring data for Lightning Web Component
     */
    public class AccountATCDataWrapper {
        @AuraEnabled
        public String AccountId { get; set; }
        
        @AuraEnabled
        public String AccountName { get; set; }
        
        @AuraEnabled
        public String AccountLink { get; set; }
        
        @AuraEnabled
        public String ATCMonitoringDates { get; set; }
        
        @AuraEnabled
        public String ServicedBy { get; set; }
        
        @AuraEnabled
        public String InitialServiceDate { get; set; }
        
        @AuraEnabled
        public Boolean FirstATCMonitoringMeeting { get; set; }
        
        @AuraEnabled
        public String FirstATCMonitoringMeetingDate { get; set; }
        
        @AuraEnabled
        public String FirstATCMonitoringMeetingType { get; set; }
        
        @AuraEnabled
        public Boolean Day30ATCMonitoringMeetingCheck { get; set; }
        
        @AuraEnabled
        public String Day30ATCMonitoringMeetingDate { get; set; }
        
        @AuraEnabled
        public Boolean Day60ATCMonitoringMeetingCheck { get; set; }
        
        @AuraEnabled
        public String Day60ATCMonitoringMeetingDate { get; set; }
        
        @AuraEnabled
        public Boolean First90DayATCMonitoringMeeting { get; set; }
        
        @AuraEnabled
        public String First90DayATCMonitoringMeetingDate { get; set; }
        
        @AuraEnabled
        public String Last90DayATCMonitoringMeetingDate { get; set; }
        
        @AuraEnabled
        public String Next90DayATCMonitoringMeetingDate { get; set; }
        
        /**
         * Constructor to convert Account to wrapper
         * Maps Account object fields to wrapper properties
         */
        public AccountATCDataWrapper(Account acc) {
            this.AccountId = acc.Id;
            this.AccountName = acc.Name;
            this.AccountLink = '/' + acc.Id;
            // ATC_Monitoring_Dates__c is a Date field - use String.valueOf()
            this.ATCMonitoringDates = String.valueOf(acc.ATC_Monitoring_Dates__c);
            this.ServicedBy = acc.Serviced_By__c;
            // Use String.valueOf() to safely convert Date to String
            this.InitialServiceDate = String.valueOf(acc.Initial_Service_Date__c);
            this.FirstATCMonitoringMeeting = acc.First_ATC_Monitoring_Meeting__c;
            this.FirstATCMonitoringMeetingDate = String.valueOf(acc.First_ATC_Monitoring_Meeting_Date__c);
            this.FirstATCMonitoringMeetingType = acc.First_ATC_Monitoring_Meeting_Type__c;
            this.Day30ATCMonitoringMeetingCheck = acc.X30_day_ATC_Monitoring_Meeting_Check__c;
            this.Day30ATCMonitoringMeetingDate = String.valueOf(acc.X30_day_ATC_Monitoring_Meeting_Date__c);
            this.Day60ATCMonitoringMeetingCheck = acc.X60_Day_ATC_Monitoring_Meeting_Check__c;
            this.Day60ATCMonitoringMeetingDate = String.valueOf(acc.X60_Day_ATC_Monitoring_Meeting_Date__c);
            this.First90DayATCMonitoringMeeting = acc.First_90_Day_ATC_Monitoring_Meeting__c;
            this.First90DayATCMonitoringMeetingDate = String.valueOf(acc.First_90_Day_ATC_Monitoring_Meeting_Date__c);
            this.Last90DayATCMonitoringMeetingDate = String.valueOf(acc.Last_90_Day_ATC_Monitoring_Meeting_Date__c);
            this.Next90DayATCMonitoringMeetingDate = String.valueOf(acc.Next_90_Day_ATC_Monitoring_Meeting_Date__c);
        }
    }
}