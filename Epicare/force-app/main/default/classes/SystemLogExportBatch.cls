public with sharing class SystemLogExportBatch implements Database.Batchable<SObject>, Database.Stateful {

    private String logType; // 'LoginHistory' or 'SetupAuditTrail'
    private Integer recordCount = 0;
    private List<String> csvRows = new List<String>();

    public SystemLogExportBatch(String logType) {
        this.logType = logType;
        csvRows.add(getHeaderRow());
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime lastExport = getLastExportDate();

        String query;
        if (logType == 'LoginHistory') {
            query = 'SELECT Id, UserId, LoginTime, SourceIp, Status, Application, Browser, Platform ' +
                    'FROM LoginHistory WHERE LoginTime > :lastExport ORDER BY LoginTime';
        } else {
            query = 'SELECT Id, Action, Section, CreatedDate, CreatedById, Display ' +
                    'FROM SetupAuditTrail WHERE CreatedDate > :lastExport ORDER BY CreatedDate';
        }
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        for (SObject rec : scope) {
            csvRows.add(toCsvRow(rec));
            recordCount++;
        }
    }

    public void finish(Database.BatchableContext bc) {
        if (recordCount > 0) {
            String csvBody = String.join(csvRows, '\n');

            ContentVersion cv = new ContentVersion(
                Title = logType + '_Export_' + Date.today().format(),
                PathOnClient = logType + '_Export_' + Date.today().format() + '.csv',
                VersionData = Blob.valueOf(csvBody),
                Description = 'NY DFS 500 compliance export - ' + logType
            );
            insert cv;

            updateLastExportDate();
        }

        Data_Retention_Log__c log = new Data_Retention_Log__c(
            Rule_Name__c = logType + ' Export',
            Object_API_Name__c = logType,
            Records_Deleted__c = recordCount,
            Status__c = 'Success',
            Batch_Job_Id__c = bc.getJobId()
        );
        insert log;
    }

    private String getHeaderRow() {
        return logType == 'LoginHistory'
            ? 'Id,UserId,LoginTime,SourceIp,Status,Application,Browser,Platform'
            : 'Id,Action,Section,CreatedDate,CreatedById,Display';
    }

    private String toCsvRow(SObject rec) {
        if (logType == 'LoginHistory') {
            return String.join(new List<String>{
                (String) rec.get('Id'), (String) rec.get('UserId'),
                String.valueOf(rec.get('LoginTime')), (String) rec.get('SourceIp'),
                (String) rec.get('Status'), (String) rec.get('Application'),
                (String) rec.get('Browser'), (String) rec.get('Platform')
            }, ',');
        }
        String display = rec.get('Display') != null ? ((String) rec.get('Display')).replace(',', ';') : '';
        return String.join(new List<String>{
            (String) rec.get('Id'), (String) rec.get('Action'), (String) rec.get('Section'),
            String.valueOf(rec.get('CreatedDate')), (String) rec.get('CreatedById'), display
        }, ',');
    }

    private DateTime getLastExportDate() {
        Retention_Export_Tracker__c tracker = Retention_Export_Tracker__c.getValues(logType);
        return (tracker != null && tracker.Last_Export_Date__c != null)
            ? tracker.Last_Export_Date__c
            : DateTime.now().addYears(-1);
    }

    private void updateLastExportDate() {
        Retention_Export_Tracker__c tracker = Retention_Export_Tracker__c.getValues(logType);
        if (tracker == null) {
            tracker = new Retention_Export_Tracker__c(Name = logType);
        }
        tracker.Last_Export_Date__c = DateTime.now();
        upsert tracker;
    }
}