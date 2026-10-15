public with sharing class ContactTriggerHandler {

    public void run() {
        if (Trigger.isBefore && Trigger.isInsert) {
            validateCaptiveAgent(Trigger.new);
        }
        if (Trigger.isBefore && Trigger.isUpdate) {
            validateCaptiveAgent(Trigger.new);
        }

        // --- SSN tracking (new) ---
        if (Trigger.isAfter && Trigger.isInsert) {
            trackSSNCreated((List<Contact>) Trigger.new);
        }
        if (Trigger.isAfter && Trigger.isUpdate) {
            trackSSNModified((List<Contact>) Trigger.new, (Map<Id, Contact>) Trigger.oldMap);
        }
    }

    private void validateCaptiveAgent(List<Contact> newList) {
        Set<Id> contactIds = new Set<Id>();
        for (Contact con : newList) {
            if (con.Agent_Sub_Type__c == 'Captive') {
                contactIds.add(con.Id);
            }
        }
        if (contactIds.isEmpty()) return;
        // Count active appointments
        Map<Id, Integer> contactToCount = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Agent__c agentId, COUNT(Id) cnt
            FROM Appointment__c
            WHERE Agent__c IN :contactIds
            AND Status__c NOT IN ('Rejected', 'Terminated', 'Missing Agent Info')
            GROUP BY Agent__c
        ]) {
            contactToCount.put(
                (Id) ar.get('agentId'),
                (Integer) ar.get('cnt')
            );
        }
        // Apply warning (NON-BLOCKING)
        for (Contact con : newList) {
            if (con.Agent_Sub_Type__c != 'Captive') {
                con.Agent_Warning__c = null;
                continue;
            }
            Integer count = contactToCount.get(con.Id);
            if (count != null && count > 1) {
                con.Agent_Warning__c =
                    'Advisory: This Captive agent has ' + count +
                    ' active appointments. Please review allocation.';
            } else {
                con.Agent_Warning__c = null;
            }
        }
    }

    private void trackSSNCreated(List<Contact> newList) {
        List<Security_Incident__c> incidents = new List<Security_Incident__c>();

        for (Contact newCon : newList) {
            if (String.isNotBlank(newCon.SSN__c)) {
                incidents.add(buildSSNIncident(newCon.Id, 'SSN was set'));
            }
        }

        if (!incidents.isEmpty()) {
            insert incidents;
        }
    }

    private void trackSSNModified(List<Contact> newList, Map<Id, Contact> oldMap) {
        List<Security_Incident__c> incidents = new List<Security_Incident__c>();

        for (Contact newCon : newList) {
            Contact oldCon = oldMap.get(newCon.Id);

            if (newCon.SSN__c != oldCon.SSN__c) {
                incidents.add(buildSSNIncident(newCon.Id, 'SSN was modified'));
            }
        }

        if (!incidents.isEmpty()) {
            insert incidents;
        }
    }

    private Security_Incident__c buildSSNIncident(Id contactId, String actionSummary) {
        return new Security_Incident__c(
            Incident_Type__c      = 'PII Exposure',
            Severity__c            = 'Medium',
            Status__c               = 'Open',
            Detected_Date__c        = System.now(),
            Detected_By__c           = UserInfo.getUserId(),
            Detection_Method__c      = 'SSN_Access_Trigger',
            Affected_Object__c        = 'Contact',
            Affected_Records__c        = 1,
            Description__c              = actionSummary + ' on Contact record ' + contactId
                                            + ' by user ' + UserInfo.getUserId() + '.'
        );
    }
}