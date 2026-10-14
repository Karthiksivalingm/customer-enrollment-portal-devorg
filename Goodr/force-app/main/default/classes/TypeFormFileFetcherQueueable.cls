public class TypeFormFileFetcherQueueable implements Queueable, Database.AllowsCallouts {

    private final List<TypeFormFileFetcherInvoker.Input> inputs;

    public TypeFormFileFetcherQueueable(List<TypeFormFileFetcherInvoker.Input> inputs) {
        this.inputs = inputs;
    }
	
    public void execute(QueueableContext context) {
        TypeFormFileFetcher.fetchAndSaveFiles(inputs);
    }
}