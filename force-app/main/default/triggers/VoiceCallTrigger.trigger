/**********************************
Class Name    : VoiceCallTrigger
Description     : VoiceCall Autopopulation.
Test Class      : TestAutoPopulateContactOnVoiceCall
Created Date    : 13-June-2024
Reviewd By      :

VERSION          DATE                   AUTHOR                DETAIL
--------------------------------------------------------------------------------------------------------- 
1.0              13-June-2024                                   
***********************************/
trigger VoiceCallTrigger on VoiceCall (before insert,before update) {
    
    if(trigger.isBefore && trigger.isInsert){
        AutoPopulateContactOnVoiceCall.searchContactThroughRecipientNumber(trigger.new);
    }
     if(trigger.isbefore && trigger.isUpdate){
        AutoPopulateContactOnVoiceCall.searchContactThroughRecipientNumberAfterUpdate(trigger.new,trigger.oldMap);
    }
}