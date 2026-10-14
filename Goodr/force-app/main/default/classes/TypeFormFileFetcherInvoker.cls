public class TypeFormFileFetcherInvoker {
	
    public class Input {
        @InvocableVariable(required=true)
        public String leadId;

        @InvocableVariable(required=true)
        public String formId;
    }
    
    @InvocableMethod(label='Fetch Typeform Files')
    public static void invoke(List<Input> inputs) {
        if (inputs == null || inputs.isEmpty()) return;
        System.enqueueJob(new TypeFormFileFetcherQueueable(inputs));
    }
}