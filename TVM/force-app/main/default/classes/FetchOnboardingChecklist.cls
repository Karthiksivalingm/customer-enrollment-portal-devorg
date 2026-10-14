public class FetchOnboardingChecklist {
    @AuraEnabled
    public static List<Foundation_Onboarding__c> fetchOnboarding(String searchMonth, String searchYear, String searchDate) {
        System.debug('==== searchMonth == $$$$ ' + searchMonth);
        System.debug('==== searchYear == $$$$ ' + searchYear);
        System.debug('==== searchDate == $$$$ ' + searchDate);

        // Get all fields dynamically from Foundation_Onboarding__c
        String sObjectApiName = 'Foundation_Onboarding__c';      
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(sObjectApiName).getDescribe().fields.getMap();

        // Build comma-separated list of fields
        String commaSeparatedFields = '';
        for (String fieldName : fieldMap.keySet()) {
            if (String.isBlank(commaSeparatedFields)) {
                commaSeparatedFields = fieldName;
            } else {
                commaSeparatedFields += ', ' + fieldName;
            }
        }

        // Start building query
        String query = 'SELECT ' +
                       'Account__r.Name, ' +
                       'Account__r.Account_Technician__r.Name, ' +
                       'Account__r.Regional_Performance_Manager__r.Name, ' +
                       'Opportunity__r.Name, ' +
                       commaSeparatedFields +
                       ' FROM ' + sObjectApiName +
                       ' WHERE Opportunity__r.StageName = \'Onboarding\' ' +
                       'AND Opportunity__r.Type__c = \'Digital Advertising\' ';

        // Add filters dynamically
        List<String> whereClauses = new List<String>();

        if (!String.isBlank(searchMonth)) {
            whereClauses.add('CALENDAR_MONTH(Planned_Launch_Date__c) = ' + Integer.valueOf(searchMonth));
        }
        if (!String.isBlank(searchYear)) {
            whereClauses.add('CALENDAR_YEAR(Planned_Launch_Date__c) = ' + Integer.valueOf(searchYear));
        }
       if (!String.isBlank(searchDate)) {
    try {
        Date sDate = Date.valueOf(searchDate);
        whereClauses.add('Planned_Launch_Date__c = ' + '\'' + sDate.format() + '\'');
    } catch (Exception e) {
        System.debug('Invalid Date: ' + searchDate + ' → ' + e.getMessage());
    }
}


        if (!whereClauses.isEmpty()) {
            query += ' AND ' + String.join(whereClauses, ' AND ');
        }

        System.debug('Final Query: ' + query);

        // Execute dynamic SOQL
        List<Foundation_Onboarding__c> onboardingList = Database.query(query);
        System.debug('=== Results === ' + onboardingList.size());
        return onboardingList;
    }

    @AuraEnabled 
    public static Map<String, String> getMonthFieldValue() {
        Map<String, String> options = new Map<String, String>();
        options.put('1', 'January');
        options.put('2', 'February');
        options.put('3', 'March');
        options.put('4', 'April');
        options.put('5', 'May');
        options.put('6', 'June');
        options.put('7', 'July');
        options.put('8', 'August');
        options.put('9', 'September');
        options.put('10', 'October');
        options.put('11', 'November');
        options.put('12', 'December');
        return options;
    }
}