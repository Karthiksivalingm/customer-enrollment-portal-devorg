// Line 1 - UPDATED: Added inherited sharing to enforce record-level security
public inherited sharing class APILogger {
    // NEW: List to collect logs for bulk insert (prevents DML inside loops)
    private static List<API_Log__c> logsToInsert = new List<API_Log__c>();

    public static void logCalloutError(
        String context,
        Integer statusCode,
        String requestMessage,
        String responseMessage,
        String stackTrace,
        String relatedRecordId,
        String type
    ) {
        try {
            API_Log__c log = new API_Log__c();
            log.Context__c = context;
            log.Status_Code__c = statusCode;
            log.Request_Message__c = requestMessage;
            log.Response_Message__c = responseMessage;
            log.Log_Type__c = type;
            if (String.isNotBlank(stackTrace)) {
                log.Stack_Trace__c = stackTrace;
            }
            if (relatedRecordId != null) {
                log.Related_Record_Id__c = relatedRecordId;
            }
            // ── CHANGED: insert immediately instead of only buffering into            ──
            // ── logsToInsert. Previously this method only added the log to a static    ──
            // ── list, and nothing in the org ever called insertLogs() to flush it —     ──
            // ── meaning every call to logCalloutError() silently lost its log record.   ──
            // ── Confirmed by APILoggerTest.testLogCalloutError() and                    ──
            // ── testLogCalloutError_NullValues() both failing with "List has no rows    ──
            // ── for assignment to SObject" when querying immediately after calling      ──
            // ── this method.                                                           ──
            insert log;
        } catch (Exception e) {
            System.debug('Failed to log API error: ' + e.getMessage());
        }
    }

    // NEW: Method to insert logs in bulk (DML outside loops)
    // ── Kept as-is for backward compatibility, in case any other class still       ──
    // ── uses the logsToInsert/insertLogs() buffering pattern directly.             ──
    public static void insertLogs() {
        if (!logsToInsert.isEmpty()) {
            try {
                insert logsToInsert;
                logsToInsert.clear();
            } catch (Exception e) {
                System.debug('Failed to insert API logs: ' + e.getMessage());
            }
        }
    }

    public static API_Log__c createLog(
        String context,
        Integer statusCode,
        String requestMessage,
        String responseMessage,
        String stackTrace,
        String relatedRecordId,
        String type
    ) {
        API_Log__c log = new API_Log__c();
        log.Context__c = context;
        log.Status_Code__c = statusCode;
        log.Request_Message__c = requestMessage;
        log.Response_Message__c = responseMessage;
        log.Log_Type__c = type;
        if (String.isNotBlank(stackTrace)) {
            log.Stack_Trace__c = stackTrace;
        }
        if (relatedRecordId != null) {
            log.Related_Record_Id__c = relatedRecordId;
        }
        return log;
    }
}