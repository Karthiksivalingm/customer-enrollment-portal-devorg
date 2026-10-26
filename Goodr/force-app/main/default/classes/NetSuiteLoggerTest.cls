@IsTest
private class NetSuiteLoggerTest {

    @IsTest
    static void flushSavesNetSuiteLogs() {
        Test.startTest();
        NetSuiteLogger.add('NetSuite Customer Create', 400, '{"a":1}', '{"b":2}', 'Bad request', null);
        NetSuiteLogger.add('NetSuite Contact Create', 500, null, null, 'x'.repeat(40000), null);
        Assert.areEqual(2, NetSuiteLogger.pendingCount(), 'both logs are held until flush');
        NetSuiteLogger.flush();
        Test.stopTest();

        Assert.areEqual(0, NetSuiteLogger.pendingCount(), 'flush clears the pending list');
        List<API_Log__c> logs = [
            SELECT Integration__c, Log_Type__c, Context__c, Status_Code__c, Request_Message__c, Stack_Trace__c
            FROM API_Log__c ORDER BY Status_Code__c
        ];
        Assert.areEqual(2, logs.size());
        Assert.areEqual('NetSuite', logs[0].Integration__c);
        Assert.areEqual('API Errors', logs[0].Log_Type__c);
        Assert.areEqual('NetSuite Customer Create', logs[0].Context__c);
        Assert.areEqual('{"a":1}', logs[0].Request_Message__c);
        Assert.areEqual(32768, logs[1].Stack_Trace__c.length(), 'long messages are cut to the field size');
    }

    @IsTest
    static void flushWithNothingPendingDoesNothing() {
        NetSuiteLogger.flush();
        Assert.areEqual(0, [SELECT COUNT() FROM API_Log__c]);
    }

    @IsTest
    static void relatedRecordIdIsStored() {
        Id relatedId = '001000000000000AAA';
        NetSuiteLogger.add('ctx', 400, null, null, 'err', relatedId);
        NetSuiteLogger.flush();
        Assert.areEqual(String.valueOf(relatedId), [SELECT Related_Record_Id__c FROM API_Log__c LIMIT 1].Related_Record_Id__c);
    }
}
