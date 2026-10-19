/**********************************
Class Name    : AutoPopulateContactOnVoiceCall
Description     :Populate Contact Name On Voice Call.
Test Class      : TestAutoPopulateContactOnVoiceCall
Created Date    : 13-June-2024
Reviewd By      :

VERSION          DATE                   AUTHOR                DETAIL
--------------------------------------------------------------------------------------------------------- 
1.0              13-June-2024                                   
***********************************/
public class AutoPopulateContactOnVoiceCall {
    public static void comparePhoneNumber(List<VoiceCall>newListOfVC){
        Map<String,VoiceCall>mapPhoneNumberVsVoiceCall= New Map<String,VoiceCall>();
        For(VoiceCall voiceCallRec :newListOfVC){
            if(!String.isBlank(voiceCallRec.ToPhoneNumber)){
                String phoneNumbres =  (voiceCallRec.ToPhoneNumber).substring(2);
                mapPhoneNumberVsVoiceCall.put(phoneNumbres,voiceCallRec);
                 String mobileNumbres =  (voiceCallRec.FromPhoneNumber).substring(2);
                mapPhoneNumberVsVoiceCall.put(mobileNumbres,voiceCallRec);
            }
          
        }  
        if(!mapPhoneNumberVsVoiceCall.isEmpty()){
            For(Contact conMatching :[SELECT Id,Phone,Name,AccountId , MobilePhone FROM Contact WHERE (Phone IN :mapPhoneNumberVsVoiceCall.keySet() Or MobilePhone IN :mapPhoneNumberVsVoiceCall.keySet())]){
                if(!String.isBlank(conMatching.Phone)){
                   mapPhoneNumberVsVoiceCall.get(conMatching.Phone).Contact__c = conMatching.Id;
                 mapPhoneNumberVsVoiceCall.get(conMatching.Phone).Account__c = conMatching.AccountId; 
                }
                else {
                     mapPhoneNumberVsVoiceCall.get(conMatching.MobilePhone).Contact__c = conMatching.Id;
                 mapPhoneNumberVsVoiceCall.get(conMatching.MobilePhone).Account__c = conMatching.AccountId; 
                }
            }
        }
    }
    public static void searchContactThroughRecipientNumber(List<VoiceCall>newListOfVC){
        comparePhoneNumber(newListOfVC);
    }
    public static void searchContactThroughRecipientNumberAfterUpdate(List<VoiceCall>newListOfVC,Map<Id,VoiceCall>oldMapVC){
        
        List<VoiceCall>VoiceCallid =New List<VoiceCall>();        
        For(VoiceCall voiceCallRec :newListOfVC){
            if((!String.isBlank(voiceCallRec.ToPhoneNumber)&& voiceCallRec.ToPhoneNumber != oldMapVC.get(voiceCallRec.Id).ToPhoneNumber) || ( !String.isBlank(voiceCallRec.FromPhoneNumber)&& voiceCallRec.FromPhoneNumber != oldMapVC.get(voiceCallRec.Id).FromPhoneNumber)){
                VoiceCallid.add(voiceCallRec);
            }
        }
        comparePhoneNumber(VoiceCallid);
    }
}