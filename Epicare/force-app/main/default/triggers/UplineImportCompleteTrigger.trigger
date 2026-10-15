trigger UplineImportCompleteTrigger on Commission_Import_Log__c (after insert, after update) {
    Set<String> policyReportTypes = new Set<String>{
        'Carepoint Active Policies',
        'Carepoint Future Policies',
        'Carepoint Disenrollments',
        'Carepoint Future Disenrollments',
        'Carepoint RTS',
        'Carepoint Appointments In Progress',
        'Carepoint Expired Appointments',
        'Claro Book of Business',
        'Claro Policies At Risk'
    };
    List<Upline_Policy_Import_Completed__e> events = new List<Upline_Policy_Import_Completed__e>();
    List<Error_Log__c> errorLogs                   = new List<Error_Log__c>();

    for (Commission_Import_Log__c importLog : Trigger.new) {

        Boolean justCompleted;
        if (Trigger.isInsert) {
            justCompleted = importLog.Processing_Status__c == 'Completed';
        } else {
            Commission_Import_Log__c oldLog = Trigger.oldMap.get(importLog.Id);
            justCompleted = importLog.Processing_Status__c == 'Completed'
                && oldLog.Processing_Status__c != 'Completed';
        }

        if (justCompleted && policyReportTypes.contains(importLog.Source_Type__c)) {

            String source = importLog.Source_Type__c != null
                && importLog.Source_Type__c.startsWith('Claro')
                ? 'Claro' : 'Carepoint';

            String reportType = importLog.Source_Type__c;
            if (reportType != null) {
                if (reportType.startsWith('Carepoint ')) {
                    reportType = reportType.substringAfter('Carepoint ');
                } else if (reportType.startsWith('Claro ')) {
                    reportType = reportType.substringAfter('Claro ');
                }
            }

            events.add(new Upline_Policy_Import_Completed__e(
                Import_Log_ID__c   = String.valueOf(importLog.Id),
                Source__c          = source,
                Report_Type__c     = reportType,
                Records_Created__c = importLog.Records_Created__c,
                Records_Updated__c = importLog.Records_Updated__c
            //    At_Risk_Count__c   = importLog.At_Risk_Count__c
            ));
        }
    }

    if (!events.isEmpty()) {
        try {
            List<Database.SaveResult> results = EventBus.publish(events);
            UplineImportCompleteHelper.logErrors(results, events);
        } catch (Exception e) {
            errorLogs.add(new Error_Log__c(
                Event_Type__c    = 'Upline_Policy_Import_Completed__e',
                Error_Message__c = e.getMessage(),
                Stack_Trace__c   = e.getStackTraceString(),
                Source__c        = 'UplineImportCompleteTrigger',
                Severity__c      = 'High',
                Status__c        = 'New'
            ));
        }
        if (!errorLogs.isEmpty()) {
            insert errorLogs;
        }
    }
}