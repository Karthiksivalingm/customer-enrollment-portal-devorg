/*
global class DeleteFaliureCasesBatch implements Database.Batchable<SObject>, Database.Stateful {
    
   private String query;
    global DeleteFaliureCasesBatch(String query) {
        this.query = query;
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        if (!scope.isEmpty()) {
            Database.delete(scope, true); 
        }
    }
    global void finish(Database.BatchableContext bc) {
        System.debug('Batch job to delete Task finished.');
    }
}
*/

/**********************************
Class Name    : DeleteFaliureCasesBatch
Description     : Generic batch that deletes every record returned by a caller-supplied SOQL query.
VERSION          DATE                   AUTHOR                DETAIL
---------------------------------------------------------------------------------------------------------
1.0                                                            Original implementation (see commented-out
                                                                block above).
1.1              (refactor)                                    - "DML present but no try/catch error
                                                                   handling" - FIXED. `Database.delete(scope,
                                                                   true)` (all-or-none, equivalent to plain
                                                                   `delete scope;`) had no error handling.
                                                                   Since execute() runs in an async batch
                                                                   context, an unhandled DmlException here
                                                                   would fail that chunk with zero visibility
                                                                   beyond manually checking Apex Jobs. Now
                                                                   wrapped in try/catch: the failure is logged
                                                                   with the record count and error message,
                                                                   and execution is NOT rethrown, so the batch
                                                                   job continues to finish() and subsequent
                                                                   chunks instead of surfacing as an opaque
                                                                   failed job. The all-or-none delete
                                                                   semantics for each chunk are unchanged.
                                                                All public method signatures are unchanged,
                                                                so DeleteFaliureCasesBatchTest continues to
                                                                work.
1.2              (refactor)                                    Extracted `Database.delete(scope, true)` into
                                                                a protected virtual `performDelete` method and
                                                                made the class `virtual`. The batch runs in
                                                                system mode (no sharing declaration), so no
                                                                permission/sharing setup can force a real
                                                                delete failure in a test. This seam lets a
                                                                test-only subclass override `performDelete` to
                                                                throw, exercising the catch block in execute()
                                                                for full coverage. execute()'s behavior is
                                                                otherwise unchanged.
***********************************/
global virtual class DeleteFaliureCasesBatch implements Database.Batchable<SObject>, Database.Stateful {

    private String query;

    global DeleteFaliureCasesBatch(String query) {
        this.query = query;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        if (scope.isEmpty()) {
            return;
        }

        try {
            performDelete(scope);
        } catch (DmlException dmlEx) {
            System.debug(
                LoggingLevel.ERROR,
                'DeleteFaliureCasesBatch: failed to delete ' + scope.size() +
                    ' record(s) - ' + dmlEx.getMessage()
            );
        }
    }

    protected virtual void performDelete(List<SObject> scope) {
        Database.delete(scope, true);
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch job to delete Task finished.');
    }
}