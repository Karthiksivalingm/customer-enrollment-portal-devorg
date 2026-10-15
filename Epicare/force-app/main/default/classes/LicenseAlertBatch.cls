public class LicenseAlertBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext ctx) {
        Date today = Date.today();
        Date ninetyDaysFromNow = today.addDays(90);

        return Database.getQueryLocator([
            SELECT Id, Contact__c, State__c,
                   Expiration_Date__c, Active__c
            FROM DOI__c
            WHERE Active__c = true
            AND Expiration_Date__c >= :today
            AND Expiration_Date__c <= :ninetyDaysFromNow
            AND Contact__c != null
        ]);
    }

    public void execute(Database.BatchableContext ctx, List<DOI__c> scope) {
        List<License_Alert__e> events = new List<License_Alert__e>();
        List<DOI__c> processedDOIs = new List<DOI__c>();
        Set<String> processed = new Set<String>();

        for (DOI__c doi : scope) {
            Integer daysUntil = Date.today().daysBetween(doi.Expiration_Date__c);
            String alertType = getAlertType(daysUntil);
            if (alertType == null) continue;

            // Dedup key
            String dedupKey = String.valueOf(doi.Contact__c)
                            + '_' + doi.State__c
                            + '_' + alertType;
            if (processed.contains(dedupKey)) continue;
            processed.add(dedupKey);

            events.add(new License_Alert__e(
                Contact_ID__c = String.valueOf(doi.Contact__c),
                State__c      = doi.State__c,
                Alert_Type__c = alertType,
                Alert_Date__c = String.valueOf(doi.Expiration_Date__c)
            ));
            processedDOIs.add(doi);
        }

        if (!events.isEmpty()) {
            try {
                // Publish Platform Events
                List<Database.SaveResult> results = EventBus.publish(events);
                LicenseAlertHelper.logErrors(results, processedDOIs);

                // Send to GO AMS
                LicenseAlertHelper.sendToGoAMS(events);

            } catch (Exception e) {
                insert new Error_Log__c(
                    Event_Type__c    = 'License_Alert__e',
                    Error_Message__c = e.getMessage(),
                    Stack_Trace__c   = e.getStackTraceString(),
                    Source__c        = 'LicenseAlertBatch',
                    Severity__c      = 'High',
                    Status__c        = 'New'
                );
            }
        }
    }

    public void finish(Database.BatchableContext ctx) {
        System.debug('LicenseAlertBatch completed at: ' + DateTime.now());
    }

    private String getAlertType(Integer daysUntil) {
        if (daysUntil <= 7) return '7 Day License Expiry Alert';
        if (daysUntil <= 15) return '15 Day License Expiry Alert';
        if (daysUntil <= 30) return '30 Day License Expiry Alert';
        if (daysUntil <= 60) return '60 Day License Expiry Alert';
        if (daysUntil <= 90) return '90 Day License Expiry Alert';
        return null;
    }
}