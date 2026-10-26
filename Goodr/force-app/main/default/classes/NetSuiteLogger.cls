/**
 * NetSuiteLogger
 * Collects NetSuite callout errors and saves them to API_Log__c with Integration__c = 'NetSuite',
 * so they can be told apart from Shopify logs. APILogger (used by Shopify) is not changed.
 *
 * Logs are kept in memory by add() and saved by flush(). Callers flush after their last NetSuite
 * callout, because Salesforce does not allow a callout after a DML statement in the same transaction.
 */
public inherited sharing class NetSuiteLogger {

    public static final String INTEGRATION = 'NetSuite';
    public static final String LOG_TYPE = 'API Errors';

    private static final Integer SHORT_TEXT = 255;
    private static final Integer LONG_TEXT = 32768;

    private static List<API_Log__c> pending = new List<API_Log__c>();

    public static void add(
        String context,
        Integer statusCode,
        String requestMessage,
        String responseMessage,
        String errorMessage,
        Id relatedRecordId
    ) {
        pending.add(new API_Log__c(
            Integration__c = INTEGRATION,
            Log_Type__c = LOG_TYPE,
            Context__c = left(context, SHORT_TEXT),
            Status_Code__c = statusCode,
            Request_Message__c = left(requestMessage, LONG_TEXT),
            Response_Message__c = left(responseMessage, LONG_TEXT),
            Stack_Trace__c = left(errorMessage, LONG_TEXT),
            Related_Record_Id__c = relatedRecordId == null ? null : String.valueOf(relatedRecordId)
        ));
    }

    public static Integer pendingCount() {
        return pending.size();
    }

    public static void flush() {
        if (pending.isEmpty()) {
            return;
        }
        List<API_Log__c> toInsert = pending;
        pending = new List<API_Log__c>();
        for (Database.SaveResult sr : Database.insert(toInsert, false)) {
            if (!sr.isSuccess()) {
                System.debug(LoggingLevel.ERROR, 'NetSuiteLogger: failed to save log: ' + sr.getErrors()[0].getMessage());
            }
        }
    }

    private static String left(String value, Integer maxLength) {
        return value == null ? null : value.left(maxLength);
    }
}
