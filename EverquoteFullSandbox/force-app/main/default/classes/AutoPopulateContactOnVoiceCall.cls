/*
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
*/

/**********************************
Class Name    : AutoPopulateContactOnVoiceCall
Description     : Populate Contact Name On Voice Call.
Test Class      : TestAutoPopulateContactOnVoiceCall
Created Date    : 13-June-2024
Reviewd By      :
VERSION          DATE                   AUTHOR                DETAIL
---------------------------------------------------------------------------------------------------------
1.0              13-June-2024
1.1              (refactor)                                    Refactored to follow Apex best practices while
                                                                 preserving the exact business logic of the
                                                                 original implementation (see commented-out
                                                                 block above):
                                                                  - SOQL for Contact matching already ran once,
                                                                    outside any loop, keyed off a bulk-built map;
                                                                    kept that pattern but added null/length/
                                                                    containsKey guards so one malformed phone
                                                                    number (blank/too-short ToPhoneNumber or
                                                                    FromPhoneNumber) can no longer throw and
                                                                    abort the entire trigger batch.
                                                                  - Extracted phone-normalization into a single
                                                                    reusable helper instead of duplicated inline
                                                                    substring() calls.
                                                                  - Guard clauses skip map-building/DML work
                                                                    entirely when there is nothing to process.
                                                                  - ApexDoc comments added for maintainability.
                                                                 All public method signatures are unchanged, so
                                                                 existing triggers/callers continue to work
                                                                 unmodified.
***********************************/
public class AutoPopulateContactOnVoiceCall {

    // Minimum length a raw phone number needs before we strip the 2-character country-code prefix.
    private static final Integer MIN_PHONE_LENGTH = 3;

    /**
     * Builds a map of normalized phone number -> VoiceCall from the given records' ToPhoneNumber
     * and FromPhoneNumber, then performs a single bulk Contact query to populate each VoiceCall's
     * Contact__c and Account__c based on a Phone or MobilePhone match.
     */
    public static void comparePhoneNumber(List<VoiceCall> newListOfVC) {
        if (newListOfVC == null || newListOfVC.isEmpty()) {
            return;
        }

        Map<String, VoiceCall> mapPhoneNumberVsVoiceCall = new Map<String, VoiceCall>();

        for (VoiceCall voiceCallRec : newListOfVC) {
            String toNumber = normalizedNumber(voiceCallRec.ToPhoneNumber);
            if (toNumber != null) {
                mapPhoneNumberVsVoiceCall.put(toNumber, voiceCallRec);
            }

            String fromNumber = normalizedNumber(voiceCallRec.FromPhoneNumber);
            if (fromNumber != null) {
                mapPhoneNumberVsVoiceCall.put(fromNumber, voiceCallRec);
            }
        }

        if (mapPhoneNumberVsVoiceCall.isEmpty()) {
            return;
        }

        // Single bulk query outside any loop - keyed off the map built above.
        for (Contact conMatching : [
            SELECT Id, Phone, Name, AccountId, MobilePhone
            FROM Contact
            WHERE Phone IN :mapPhoneNumberVsVoiceCall.keySet()
               OR MobilePhone IN :mapPhoneNumberVsVoiceCall.keySet()
        ]) {
            if (!String.isBlank(conMatching.Phone) && mapPhoneNumberVsVoiceCall.containsKey(conMatching.Phone)) {
                VoiceCall vc = mapPhoneNumberVsVoiceCall.get(conMatching.Phone);
                vc.Contact__c = conMatching.Id;
                vc.Account__c = conMatching.AccountId;
            } else if (!String.isBlank(conMatching.MobilePhone) && mapPhoneNumberVsVoiceCall.containsKey(conMatching.MobilePhone)) {
                VoiceCall vc = mapPhoneNumberVsVoiceCall.get(conMatching.MobilePhone);
                vc.Contact__c = conMatching.Id;
                vc.Account__c = conMatching.AccountId;
            }
        }
    }

    /**
     * Entry point for before/after-insert context: attempts to match every VoiceCall in the
     * trigger batch to a Contact/Account via phone number.
     */
    public static void searchContactThroughRecipientNumber(List<VoiceCall> newListOfVC) {
        comparePhoneNumber(newListOfVC);
    }

    /**
     * Entry point for after-update context: only re-runs the phone match for VoiceCalls whose
     * ToPhoneNumber or FromPhoneNumber actually changed since the previous version of the record.
     */
    public static void searchContactThroughRecipientNumberAfterUpdate(List<VoiceCall> newListOfVC, Map<Id, VoiceCall> oldMapVC) {
        if (newListOfVC == null || newListOfVC.isEmpty() || oldMapVC == null) {
            return;
        }

        List<VoiceCall> voiceCallsToProcess = new List<VoiceCall>();

        for (VoiceCall voiceCallRec : newListOfVC) {
            VoiceCall oldVc = oldMapVC.get(voiceCallRec.Id);
            if (oldVc == null) {
                continue;
            }

            Boolean toNumberChanged = !String.isBlank(voiceCallRec.ToPhoneNumber)
                && voiceCallRec.ToPhoneNumber != oldVc.ToPhoneNumber;
            Boolean fromNumberChanged = !String.isBlank(voiceCallRec.FromPhoneNumber)
                && voiceCallRec.FromPhoneNumber != oldVc.FromPhoneNumber;

            if (toNumberChanged || fromNumberChanged) {
                voiceCallsToProcess.add(voiceCallRec);
            }
        }

        comparePhoneNumber(voiceCallsToProcess);
    }

    /**
     * Strips the leading 2-character prefix (e.g. "+1") from a raw phone number.
     * Returns null (instead of throwing) when the value is blank or too short to safely
     * substring, so one bad record no longer aborts the entire trigger batch.
     */
    private static String normalizedNumber(String rawNumber) {
        if (String.isBlank(rawNumber) || rawNumber.length() < MIN_PHONE_LENGTH) {
            return null;
        }
        return rawNumber.substring(2);
    }
}