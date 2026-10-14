// Line 1 - UPDATED: Added inherited sharing to enforce record-level security
public inherited sharing class ApiLogTriggerHandler {

    // ── CHANGED: Case creation deactivated per client request — "Api_Log__c records ──
    // ── creating Cases doesn't seem like best practice, we don't want machine errors ──
    // ── to be tickets." API_Log__c itself is untouched and continues to be created   ──
    // ── normally by every calling class — only the downstream Case creation stops.   ──
    // ── All original logic (including the four helper methods below) is preserved,   ──
    // ── commented out, so it can be restored by simply un-commenting this block and  ──
    // ── removing the early return, if ever needed in the future.                     ──
    public static void handleAfterInsert(List<API_Log__c> newLogs) {
        return; // ── Case creation disabled ──

        /* ORIGINAL LOGIC — PRESERVED BUT UNREACHABLE. Everything below, including the  ──
           four helper methods, is commented out together so that NONE of it counts     ──
           against code coverage (uncallable/dead code that isn't inside a comment      ──
           still shows as 0% covered and drags the class average down).                 ──

        List<Case> casesToInsert = new List<Case>();
        Map<String, Case> existingCasesMap = new Map<String, Case>();
        Set<String> subjects = new Set<String>();

        // Build subject keys first
        for (API_Log__c log : newLogs) {
            String readableMessage = getReadableMessage(log.Stack_Trace__c);
            String subject = 'Shopify Integration Failure – ' + readableMessage;
            subjects.add(subject);
        }

        // Fetch existing open cases with same subject
        for (Case c : [
            SELECT Id, Subject
            FROM Case
            WHERE Status != 'Closed'
            AND Subject IN :subjects
        ]) {
            existingCasesMap.put(c.Subject, c);
        }

        for (API_Log__c log : newLogs) {

            String readableMessage = getReadableMessage(log.Stack_Trace__c);
            String subject = 'Shopify Integration Failure – ' + readableMessage;

            String statusCode = log.Status_Code__c != null
                ? String.valueOf(log.Status_Code__c)
                : 'Not Available';

            String relatedRecord = log.Related_Record_Id__c != null
                ? String.valueOf(log.Related_Record_Id__c)
                : 'Not Available';

            String severity = getSeverity(log.Status_Code__c, log.Stack_Trace__c);

            Case c = new Case();
            c.Subject = subject;

            c.Description =
                '🚨 Shopify Integration Error\n\n' +
                'The system attempted to sync data with Shopify, but an issue occurred.\n\n' +
                'What Happened:\n' +
                readableMessage + '\n\n' +
                'Impact:\n' +
                'The related record could not be processed successfully.\n\n' +
                'Recommended Action:\n' +
                getRecommendedAction(log.Stack_Trace__c, log.Status_Code__c) + '\n\n' +
                '--------------------------------------------------\n\n' +
                'Integration Details:\n' +
                'Context: ' + log.Context__c + '\n' +
                'Status Code: ' + statusCode + '\n' +
                'Severity Level: ' + severity + '\n\n' +
                'Technical Reference:\n' +
                'Stack Trace: ' + log.Stack_Trace__c + '\n' +
                'Related Record Id: ' + relatedRecord;

            c.Status = 'New';
            c.Origin = 'System';
            c.Type = log.Log_Type__c;
            c.Priority = severity;

            // Duplicate handling → make child case
            if (existingCasesMap.containsKey(subject)) {
                c.ParentId = existingCasesMap.get(subject).Id;
            }

            casesToInsert.add(c);
        }

        // NEW: Moved DML to separate method to ensure execution outside loops
        insertCases(casesToInsert);

        */
    }

    /* ── The four helper methods below are commented out together with the block   ──
       above for the same reason — as real, uncalled private methods they would      ──
       show as 0% covered and drag class coverage back down, even though they're     ──
       never invoked by anything once handleAfterInsert() returns early.             ──

    // NEW METHOD (Fix for DML inside loop scanner warning)
    private static void insertCases(List<Case> casesToInsert) {
        if (!casesToInsert.isEmpty()) {
            insert casesToInsert;
        }
    }

    // ===============================
    // USER FRIENDLY MESSAGE
    // ===============================
    private static String getReadableMessage(String stackTrace) {

        if (stackTrace == null) return 'Unknown integration error';

        if (stackTrace.contains('companyLocation')) {
            return 'Location not found in Shopify response';
        }

        if (stackTrace.contains('timeout')) {
            return 'Shopify API timeout occurred';
        }

        if (stackTrace.contains('Unauthorized')) {
            return 'Unauthorized access to Shopify API';
        }

        return stackTrace.length() > 100
            ? stackTrace.substring(0, 100)
            : stackTrace;
    }

    // ===============================
    // SEVERITY LOGIC
    // ===============================
    private static String getSeverity(Decimal statusCode, String stackTrace) {

        if (statusCode == 401 || statusCode == 403 || statusCode == 500) {
            return 'High';
        }

        if (statusCode == 400) {
            return 'Medium';
        }

        if (stackTrace != null && stackTrace.contains('validation')) {
            return 'Medium';
        }

        return 'Low';
    }

    // ===============================
    // RECOMMENDED ACTION
    // ===============================
    private static String getRecommendedAction(String stackTrace, Decimal statusCode) {

        if (statusCode == 401) {
            return 'Verify Shopify API credentials (Access Token / Permissions).';
        }

        if (statusCode == 403) {
            return 'Check API permissions in Shopify Admin.';
        }

        if (statusCode == 500) {
            return 'Shopify server error. Retry after some time.';
        }

        if (stackTrace != null && stackTrace.contains('companyLocation')) {
            return 'Ensure the company location is properly configured in Shopify.';
        }

        if (stackTrace != null && stackTrace.contains('timeout')) {
            return 'Check network connectivity and retry the integration.';
        }

        return 'Review the technical details and retry the process.';
    }
    */
}