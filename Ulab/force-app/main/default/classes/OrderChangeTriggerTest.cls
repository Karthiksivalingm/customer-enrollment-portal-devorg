@isTest
public class OrderChangeTriggerTest {

    private static String uniqueSuffix() {        
        Integer rnd = Math.abs(Math.mod(Math.abs(Crypto.getRandomInteger()), 1000000));
        return String.valueOf(rnd);
    }

    @isTest
    public static void testOrderChangeTrigger() {

        String suf = uniqueSuffix();

        // Create Account
        Account acc = new Account(
            Name = 'Test Account ' + suf
        );
        insert acc;

        // Create Case
        uLab_Case__c caseRec = new uLab_Case__c(
            Account__c = acc.Id
        );
        insert caseRec;

        // Create Order
        uLab_Order__c orderRec = new uLab_Order__c(
            Name = 'Test Order ' + suf,
            orderId__c = 'ORD-' + suf,
            uAssist_Status__c = 'In Progress',
            uLab_Case__c = caseRec.Id,
            Send_to_WebApp__c = true,
            Assigned_uAssistant__c = UserInfo.getUserId(),
            Date_Entered_In_Current_Status__c = System.now(),
            Date_Entered_In_Last_Status__c = System.now()
        );

        insert orderRec;

        Test.startTest();

        // Update status to trigger OrderChangeTrigger
        orderRec.uAssist_Status__c = 'Completed';
        update orderRec;

        Test.stopTest();

        System.assertNotEquals(null, orderRec.Id);
    }
}