public with sharing class EventChangePublishHandler {

    public static void handleAfter(
        List<Event> newList,
        Map<Id, Event> oldMap,
        List<Event> oldList,
        Boolean isUpdate,
        Boolean isDelete
    ) {
        List<Event_Update__e> evList = new List<Event_Update__e>();
        Set<Id> eventsToDelete = new Set<Id>();

        Set<String> trackedFields = new Set<String>{ 'Subject', 'StartDateTime', 'EndDateTime', 'Location' };

        /*    
        //Handle the deletion for Canceled event
        if (isUpdate && newList != null && oldMap != null) {
            for (Event newRec : newList) {
                Event oldRec = oldMap.get(newRec.Id);
                String newSubject = newRec.Subject;
                if (newSubject != null && newSubject.trim().toLowerCase().startsWith('canceled')) {
                    // Mark for deletion
                    eventsToDelete.add(newRec.Id);
                }
            }
        }
		*/

        //Handle the event publishing logic (update & delete)
        if (isUpdate && newList != null && oldMap != null) {
            for (Event newRec : newList) {
                Event oldRec = oldMap.get(newRec.Id);

                Map<String, Object> oldMapVals = new Map<String, Object>();
                Map<String, Object> newMapVals = new Map<String, Object>();
                Boolean anyChange = false;

                for (String fld : trackedFields) {
                    Object oldVal = oldRec.get(fld);
                    Object newVal = newRec.get(fld);
                    if ((oldVal == null && newVal != null)
                        || (oldVal != null && newVal == null)
                        || (oldVal != null && newVal != null && !oldVal.equals(newVal))) {
                        anyChange = true;
                    }
                    oldMapVals.put(fld, oldVal);
                    newMapVals.put(fld, newVal);
                }

                if (!anyChange) {
                    continue;
                }

                String oldJson = JSON.serializePretty(oldMapVals);
                String newJson = JSON.serializePretty(newMapVals);

                evList.add(new Event_Update__e(
                    RecordId__c        = newRec.Id,
                    ChangedByUserId__c = UserInfo.getUserId(),
                    ChangeDateTime__c  = System.now(),
                    ObjectApiName__c   = 'Event',
                    OldValuesJSON__c   = oldJson,
                    NewValuesJSON__c   = newJson,
                    ChangeType__c      = 'UPDATE'
                ));
            }
        }

        if (isDelete && oldList != null) {
            for (Event oldRec : oldList) {
                Map<String, Object> oldMapVals = new Map<String, Object>();
                Map<String, Object> newMapVals = new Map<String, Object>();

                for (String fld : trackedFields) {
                    oldMapVals.put(fld, oldRec.get(fld));
                    newMapVals.put(fld, null);
                }

                String oldJson = JSON.serializePretty(oldMapVals);
                String newJson = JSON.serializePretty(newMapVals);

                evList.add(new Event_Update__e(
                    RecordId__c        = oldRec.Id,
                    ChangedByUserId__c = UserInfo.getUserId(),
                    ChangeDateTime__c  = System.now(),
                    ObjectApiName__c   = 'Event',
                    OldValuesJSON__c   = oldJson,
                    NewValuesJSON__c   = newJson,
                    ChangeType__c      = 'DELETE'
                ));
            }
        }

        // Publish platform events if any
        if (!evList.isEmpty()) {
            EventBus.publish(evList);
        }
		
        /*
        // Perform deletion of the Event records if needed
        if (!eventsToDelete.isEmpty()) {
            List<Event> toDelete = [SELECT Id FROM Event WHERE Id IN :eventsToDelete];
            try {
                delete toDelete;
            } catch (DmlException e) {
                System.debug('Error deleting Events with Canceled subject: ' + e.getMessage());               
            }
        }
		*/
    }
}