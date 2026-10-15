public class ScheduledBatchableNiprpDbalertsHelper  implements Schedulable{

  public void execute(SchedulableContext sc) {
     system.enqueueJob(new NiprpDbalertsQueueable()); 
      
  }
    
}