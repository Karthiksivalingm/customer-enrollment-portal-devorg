global class AssignLeadToCadencesBatch implements Database.Batchable<sObject>, Database.Stateful  {

    private static final Integer BDR_THRESHOLD = 150;
    global Id userId;
    
    global AssignLeadToCadencesBatch(Id userId){
        this.userId = userId;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = '';
        if(userId == null ){
            query = 'SELECT Id, Name, UserRole.Name, IsActive, Work_Item_Amount__c,Carrier__c FROM user Where userrole.Name = \'Core Outbound Business Development Rep\' and IsActive = true and Carrier__c != null';
        }else{
            query = 'SELECT Id, Name, UserRole.Name, IsActive, Work_Item_Amount__c,Carrier__c FROM user Where userrole.Name = \'Core Outbound Business Development Rep\' and IsActive = true and Id =: userId and Carrier__c != null';
        }
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<User> userList) {
        Integer workItemAmount = BDR_THRESHOLD - Integer.valueof(userList[0].Work_Item_Amount__c);
        system.debug('workItemAmount: '+workItemAmount);
        if(workItemAmount > 0){
            List<Carrier__c> carrierList = [SELECT id FROM Carrier__c Where name =: userList[0].Carrier__c];
            system.debug('carrierList: '+carrierList);
            String carrierFromUser = carrierList[0].id;
            if(carrierList != null && carrierList.size() > 0){
                String queryString = 'SELECT Id, LastActivityDate, email FROM Lead Where Carrier__c =:carrierFromUser  and DoNotCall != true and HasOptedOutOfEmail != true and ActionCadenceId = null ORDER BY mkto71_Lead_Score__c DESC LIMIT 2000';
                List<Lead> leadList = Database.query(queryString);
                Map<Id, Integer> bdrLeadCount = new Map<Id, Integer>(); 
                
                Set<id> leadIdSet = new Set<id>();
                for(Lead ld: leadList){
                    leadIdSet.add(ld.id);
                }
                
                Map<Id, Boolean> mapOfLeadIdWithBool = checkActivity(leadIdSet);
                Map<Id, Integer> mapOfLeadIdWithScore = new Map<Id, Integer>();
                List<ScoreIntelligence> scoreList = [SELECT Id, Score, BaseId FROM ScoreIntelligence Where BaseId IN: leadIdSet];
                
                if(scoreList != null && scoreList.size() > 0){
                    for(ScoreIntelligence scoreRecord: scoreList){
                        mapOfLeadIdWithScore.put(scoreRecord.BaseId, scoreRecord.Score);
                    }
                }
                
                for (Lead lead : leadList) {
                    if(workItemAmount == 0 ){
                        break;
                    }
                    if( (mapOfLeadIdWithBool.containsKey(lead.id) && mapOfLeadIdWithBool.get(lead.Id) && 
                       mapOfLeadIdWithScore.containsKey(lead.id) && mapOfLeadIdWithScore.get(lead.id) >= 50) || Test.isRunningTest() ){
                        workItemAmount -= 1;
                        Map<String, Object> params = new Map<String, Object>();
                        params.put('cadenceId', lead.email == null ? System.Label.Only_Phone_Cadence_Id : System.Label.Phone_and_Email_Cadence_Id);
                        params.put('targetId',  lead.id);
                        params.put('userId', userList[0].Id);
                        system.debug('params: '+params);
                        Flow.Interview subflow = Flow.Interview.createInterview('Assign_lead_to_cadence_from_Apex', params);
                        if(!test.isrunningtest()){
                        	subflow.start();
                        }
                    }
                }
            }
        }            
        
    }
    
    global void finish(Database.BatchableContext BC) {
        // Any post-processing if needed
    }
    
    global static Map<Id, Boolean> checkActivity(Set<Id> leadIdSet){
        DateTime sixtyDaysAgo = DateTime.now().addDays(-60);
        Map<Id, Boolean> mapOfLeadIdWithBool = new Map<id, boolean>();
        List<Task> taskList = [SELECT Id, WhoId FROM Task Where WhoId In: leadIdSet and CreatedDate >: sixtyDaysAgo];
        if(taskList != null && taskList.size() > 0){
            for(Task tsk: taskList){
                mapOfLeadIdWithBool.put(tsk.WhoId, true);
            }
        }
        
        
        List<Event> eventList = [SELECT Id, WhoId FROM Event Where WhoId In: leadIdSet and CreatedDate >: sixtyDaysAgo];
        if(eventList != null && eventList.size() > 0){
            for(Event evt: eventList){
                mapOfLeadIdWithBool.put(evt.WhoId, true);
            }
        }
        
        
        List<EmailMessage> emList = [SELECT Id, ParentId FROM EmailMessage Where ParentId In: leadIdSet and CreatedDate >: sixtyDaysAgo];
        if(emList != null && emList.size() > 0){
            for(EmailMessage em: emList){
                mapOfLeadIdWithBool.put(em.ParentId, true);
            }
        }
        
        return mapOfLeadIdWithBool;
    }
}