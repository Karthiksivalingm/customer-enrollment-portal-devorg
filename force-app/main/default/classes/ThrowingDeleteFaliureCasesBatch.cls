/**********************************
Class Name    : ThrowingDeleteFaliureCasesBatch
Description     : Test-support subclass of DeleteFaliureCasesBatch that overrides performDelete() to throw a
                   DmlException, exercising the catch(DmlException) branch in
                   DeleteFaliureCasesBatch.execute() for DeleteFaliureCasesBatchTest.
                   Must be a top-level class, not nested inside DeleteFaliureCasesBatchTest: Salesforce's
                   batch dispatcher cannot resolve a Database.Batchable implementation that is an inner
                   class of an @isTest class, even when public - Database.executeBatch fails immediately
                   with a generic System.UnexpectedException("Error processing messages") before start()
                   or execute() ever runs.
***********************************/
@isTest
public class ThrowingDeleteFaliureCasesBatch extends DeleteFaliureCasesBatch {

    public ThrowingDeleteFaliureCasesBatch(String query) {
        super(query);
    }

    protected override void performDelete(List<SObject> scope) {
        throw new DmlException('Simulated delete failure to exercise DeleteFaliureCasesBatch catch block.');
    }
}
