public with sharing class GeneratePDFController {
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts() {
        try {
            return [SELECT Id, Name, Industry, AnnualRevenue 
                    FROM Account 
                    WHERE Name != NULL 
                    LIMIT 5];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving accounts: ' + e.getMessage());
        }
    }
}