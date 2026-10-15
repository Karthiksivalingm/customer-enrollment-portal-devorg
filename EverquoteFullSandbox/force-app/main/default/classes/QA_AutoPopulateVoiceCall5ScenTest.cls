/**
 * QA 5-scenario regression suite for AutoPopulateContactOnVoiceCall.
 *
 * VoiceCall's telephony fields (ToPhoneNumber, FromPhoneNumber, CallType, etc.) are
 * schema-declared non-writable outside Apex test context - the platform expects them
 * to be populated only by the Voice/telephony integration. Because of that, these 5
 * scenarios cannot be run as Developer Console Execute Anonymous scripts (that fails
 * with "Field is not writeable: VoiceCall.ToPhoneNumber" regardless of profile/FLS) -
 * they must run as real @isTest methods, which is what this class provides.
 *
 * How to run: Developer Console -> Test -> New Run -> select this class -> Run, or
 * Setup -> Apex Test Execution -> select this class -> Run. Each method's PASS/FAIL
 * also appears as a System.debug line in that method's debug log, in addition to the
 * standard green/red result shown per test method.
 */
@isTest
public class QA_AutoPopulateVoiceCall5ScenTest {

    @testSetup
    static void testSetup() {
        Account acc = new Account(Name = 'QA-APCV-Acct');
        insert acc;

        Contact conA = new Contact(LastName = 'QA-APCV-Con1', AccountId = acc.Id, Phone = '4045551111');
        Contact conB = new Contact(LastName = 'QA-APCV-Con2', AccountId = acc.Id, MobilePhone = '4045552222');
        insert new List<Contact>{ conA, conB };
    }

    private static Id getCallCenterId() {
        List<CallCenter> centers = [SELECT Id FROM CallCenter LIMIT 1];
        System.assert(
            !centers.isEmpty(),
            'PREREQUISITE FAILED: no CallCenter record exists in this org - provision one (Setup -> Call Centers) before running this suite.'
        );
        return centers[0].Id;
    }

    @isTest
    static void scenario1_MatchOnToPhoneNumber() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'QA-APCV-Acct' LIMIT 1];
        Contact conA = [SELECT Id FROM Contact WHERE LastName = 'QA-APCV-Con1' LIMIT 1];
        Id callCenterId = getCallCenterId();

        VoiceCall vc1 = new VoiceCall(
            ToPhoneNumber = '+14045551111',
            FromPhoneNumber = '+19999999990',
            CallType = 'Inbound', VendorType = 'ContactCenter', CallResolution = 'Not Interested',
            CallStartDateTime = System.now(), CallEndDateTime = System.now(),
            CallCenterId = callCenterId
        );

        Test.startTest();
        insert vc1;
        Test.stopTest();

        VoiceCall result = [SELECT Contact__c, Account__c FROM VoiceCall WHERE Id = :vc1.Id];
        Boolean pass = (result.Contact__c == conA.Id && result.Account__c == acc.Id);
        System.debug('SCENARIO 1 RESULT: ' + (pass ? 'PASS' : 'FAIL') +
            ' | Contact__c=' + result.Contact__c + ' (expected ' + conA.Id + ')' +
            ' | Account__c=' + result.Account__c + ' (expected ' + acc.Id + ')');
        System.assert(pass, 'Scenario 1 failed - see debug log for actual values.');
    }

    @isTest
    static void scenario2_MatchViaMobilePhone() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'QA-APCV-Acct' LIMIT 1];
        Contact conB = [SELECT Id FROM Contact WHERE LastName = 'QA-APCV-Con2' LIMIT 1];
        Id callCenterId = getCallCenterId();

        VoiceCall vc2 = new VoiceCall(
            ToPhoneNumber = '+19999999991',
            FromPhoneNumber = '+14045552222',
            CallType = 'Inbound', VendorType = 'ContactCenter', CallResolution = 'Not Interested',
            CallStartDateTime = System.now(), CallEndDateTime = System.now(),
            CallCenterId = callCenterId
        );

        Test.startTest();
        insert vc2;
        Test.stopTest();

        VoiceCall result = [SELECT Contact__c, Account__c FROM VoiceCall WHERE Id = :vc2.Id];
        Boolean pass = (result.Contact__c == conB.Id && result.Account__c == acc.Id);
        System.debug('SCENARIO 2 RESULT: ' + (pass ? 'PASS' : 'FAIL') +
            ' | Contact__c=' + result.Contact__c + ' (expected ' + conB.Id + ')' +
            ' | Account__c=' + result.Account__c + ' (expected ' + acc.Id + ')');
        System.assert(pass, 'Scenario 2 failed - see debug log for actual values.');
    }

    @isTest
    static void scenario3_NoMatchFound() {
        Id callCenterId = getCallCenterId();

        VoiceCall vc3 = new VoiceCall(
            ToPhoneNumber = '+19998887777',
            FromPhoneNumber = '+19997776666',
            CallType = 'Inbound', VendorType = 'ContactCenter', CallResolution = 'Not Interested',
            CallStartDateTime = System.now(), CallEndDateTime = System.now(),
            CallCenterId = callCenterId
        );

        Test.startTest();
        insert vc3;
        Test.stopTest();

        VoiceCall result = [SELECT Contact__c, Account__c FROM VoiceCall WHERE Id = :vc3.Id];
        Boolean pass = (result.Contact__c == null && result.Account__c == null);
        System.debug('SCENARIO 3 RESULT: ' + (pass ? 'PASS' : 'FAIL') +
            ' | Contact__c=' + result.Contact__c + ' | Account__c=' + result.Account__c + ' (both expected null)');
        System.assert(pass, 'Scenario 3 failed - see debug log for actual values.');
    }

    @isTest
    static void scenario4_BulkInsertWithMalformedRecord() {
        Contact conA = [SELECT Id FROM Contact WHERE LastName = 'QA-APCV-Con1' LIMIT 1];
        Id callCenterId = getCallCenterId();

        VoiceCall vcGood = new VoiceCall(
            ToPhoneNumber = '+14045551111', FromPhoneNumber = '+19999999992',
            CallType = 'Inbound', VendorType = 'ContactCenter', CallResolution = 'Not Interested',
            CallStartDateTime = System.now(), CallEndDateTime = System.now(),
            CallCenterId = callCenterId
        );
        VoiceCall vcMalformed = new VoiceCall(
            ToPhoneNumber = '1', FromPhoneNumber = '2',
            CallType = 'Inbound', VendorType = 'ContactCenter', CallResolution = 'Not Interested',
            CallStartDateTime = System.now(), CallEndDateTime = System.now(),
            CallCenterId = callCenterId
        );

        Test.startTest();
        insert new List<VoiceCall>{ vcGood, vcMalformed };
        Test.stopTest();

        Map<Id, VoiceCall> results = new Map<Id, VoiceCall>(
            [SELECT Id, Contact__c, Account__c FROM VoiceCall WHERE Id IN (:vcGood.Id, :vcMalformed.Id)]
        );
        Boolean pass = (results.get(vcGood.Id).Contact__c == conA.Id
            && results.get(vcMalformed.Id).Contact__c == null
            && results.get(vcMalformed.Id).Account__c == null);
        System.debug('SCENARIO 4 RESULT: ' + (pass ? 'PASS' : 'FAIL') +
            ' | vcGood.Contact__c=' + results.get(vcGood.Id).Contact__c + ' (expected ' + conA.Id + ')' +
            ' | vcMalformed.Contact__c=' + results.get(vcMalformed.Id).Contact__c + ' (expected null)');
        System.assert(pass, 'Scenario 4 failed - see debug log for actual values.');
    }

    /**
     * This org locks VoiceCall.ToPhoneNumber/FromPhoneNumber after the record is created -
     * `update` on either field throws SObjectException("Field is not writeable"), even inside
     * @isTest context (confirmed by running this suite). That means
     * searchContactThroughRecipientNumberAfterUpdate's "phone number changed" branch is not
     * reachable through standard Apex/API DML in this org; only the "no re-match on an
     * unrelated field update" behavior can be exercised here. Flag the unreachable branch to
     * the dev/admin as a platform constraint rather than a code defect.
     */
    @isTest
    static void scenario5_UpdateOnUnrelatedFieldDoesNotChangeMatch() {
        Contact conA = [SELECT Id FROM Contact WHERE LastName = 'QA-APCV-Con1' LIMIT 1];
        Id callCenterId = getCallCenterId();

        VoiceCall vc5 = new VoiceCall(
            ToPhoneNumber = '+14045551111', FromPhoneNumber = '+19995554444',
            CallType = 'Inbound', VendorType = 'ContactCenter', CallResolution = 'Not Interested',
            CallStartDateTime = System.now(), CallEndDateTime = System.now(),
            CallCenterId = callCenterId
        );
        insert vc5;

        VoiceCall beforeUpdate = [SELECT Contact__c FROM VoiceCall WHERE Id = :vc5.Id];
        Boolean passA = (beforeUpdate.Contact__c == conA.Id);

        Test.startTest();
        vc5.CallResolution = 'Sale';
        update vc5;
        Test.stopTest();

        VoiceCall afterUnrelatedUpdate = [SELECT Contact__c FROM VoiceCall WHERE Id = :vc5.Id];
        Boolean passB = (afterUnrelatedUpdate.Contact__c == conA.Id);

        Boolean phoneFieldIsLockedOnUpdate = false;
        try {
            vc5.ToPhoneNumber = '+19999999999';
            update vc5;
        } catch (System.SObjectException e) {
            phoneFieldIsLockedOnUpdate = e.getMessage().contains('not writeable');
        }

        Boolean pass = (passA && passB && phoneFieldIsLockedOnUpdate);
        System.debug('SCENARIO 5 RESULT: ' + (pass ? 'PASS' : 'FAIL') +
            ' | Contact__c after insert=' + beforeUpdate.Contact__c + ' (expected ' + conA.Id + ')' +
            ' | Contact__c after unrelated update=' + afterUnrelatedUpdate.Contact__c + ' (expected unchanged, ' + conA.Id + ')' +
            ' | ToPhoneNumber locked on update=' + phoneFieldIsLockedOnUpdate + ' (expected true in this org)');
        System.assert(pass, 'Scenario 5 failed - see debug log for actual values.');
    }
}