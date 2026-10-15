public class NiprSSNsearchFlowInvoker {

    public class RequestWrapper {
        @InvocableVariable(required=true)
        public Id contactId;
    }

    @InvocableMethod(label='Invoke SSN Search' description='Calls future method to initiate SSN search')
    public static void invokeSSNSearch(List<RequestWrapper> requests) {
        for(RequestWrapper req : requests){
            NiprSSNsearch.ssnSearch(req.contactId);
        }
    }
}