global class Schedule_Birthday_Event implements Database.Batchable<sObject>,Schedulable {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // collect the batches of records or objects to be passed to execute
         
        String query = 'SELECT Id,Name, Birthdate FROM Contact WHERE Birthdate = NEXT_MONTH';
        return Database.getQueryLocator(query);
    }
     
    global void execute(Database.BatchableContext BC, List<Contact> conList) {
        
        List<Event> lstNewEvents = new List<Event>();
        System.debug('conList >>'+conList);
        // process each batch of records default size is 200
        for(Contact con : conList) {        
            Event e = new Event();
            date bd = con.Birthdate;
            date tdy = date.today();
            e.StartDateTime =  DateTime.newInstance(tdy.year(), bd.month(),bd.day());
            e.EndDateTime =  DateTime.newInstance(tdy.year(), bd.month(),bd.day());
            e.Subject = con.Name + '\'s Birthday';
            e.OwnerId = Label.Public_CalendarID;//'023010000003C41';
            e.IsRecurrence = false;
            e.WhoId = con.Id;
            e.IsAllDayEvent = True;
            e.IsReminderSet = True;
            lstNewEvents.add(e);
        }
        try {
            system.debug('lstNewEvents >> '+lstNewEvents);
            // insert events
             insert lstNewEvents;   
         
        } catch(Exception e) {
            System.debug(e);
        }
         
    }   
     
    global void finish(Database.BatchableContext BC) {
        // execute any post-processing operations like sending email
    }
    
    global void execute(SchedulableContext sc) {
      Schedule_Birthday_Event b = new Schedule_Birthday_Event(); 
      Database.executeBatch(b);
   }
}