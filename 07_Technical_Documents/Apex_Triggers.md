# Apex Triggers

_Generated 2026-10-13._ Watch for objects that have more than one trigger, because Salesforce doesn't guarantee the order they run in.

| Trigger | Object | Events | Calls |
|---|---|---|---|
| `AccountClusterTrigger` | Account | before insert, before update, after insert, after update | AccountCascadeHandler, ClusterRuleEngine |
| `AccountContactRelationTrigger` | AccountContactRelation | after insert, after update | AccountContactRelationHandler |
| `AccountTrigger` | Account | after insert, after update, after delete, before insert, before update | AccountTriggerHandler |
| `ApiLogTrigger` | API_Log__c | after insert | ApiLogTriggerHandler |
| `AutomatedTaskTrigger` | Task | after insert | AutomatedTaskTriggerHandler |
| `CaseEmailResponseTrigger` | EmailMessage | after insert |  |
| `CaseQueueTeamTrigger` | Case | after insert, after update |  |
| `CaseReopenOnCustomerReply` | EmailMessage | after insert | CaseReopenHandler |
| `CaseSLAPauseResume` | Case | before insert |  |
| `CaseSurveyTrigger` | Case | after update |  |
| `CaseTrigger` | Case | before insert | CaseTriggerHandler |
| `ContactClusterTrigger` | Contact | after insert |  |
| `ContactTrigger` | Contact | before insert, before update, after insert, after update | ContactTriggerHandler |
| `ContentDocumentLinkTrigger` | ContentDocumentLink | after insert | ContentDocumentLinkHandler |
| `ContentVersionTrigger` | ContentVersion | after update | ContentVersionHandler |
| `EmailMessageTrigger` | EmailMessage | after insert | EmailMessageTriggerHandler |
| `LeadClusterTrigger` | Lead | before insert, before update, after insert, after update | ClusterRuleEngine, ClusterTeamEngine, LeadConversionHandler |
| `LeadTrigger` | Lead | before insert, before update, after insert, after update | LeadTriggerHandler |
| `OpportunityClusterTrigger` | Opportunity | before insert, before update, after insert, after update | ClusterRuleEngine, ClusterTeamEngine |
| `SurveyResponseTrigger` | SurveyResponse | after insert |  |
