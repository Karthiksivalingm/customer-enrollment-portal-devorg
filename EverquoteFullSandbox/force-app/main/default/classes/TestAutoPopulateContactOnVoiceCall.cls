@isTest
public class TestAutoPopulateContactOnVoiceCall{
    @isTest
    public static void testingAutopulation(){
        Account acc = New Account();
        acc.Name = 'Test 1';
        acc.Phone = '23454355';
        Insert acc ;
        Contact con = New Contact();
        con.AccountId  = acc.Id;
        con.LastName='TestingAutoPopulation';
        con.Phone = '';
        con.MobilePhone = '7039672885';
        insert con;
        CallCenter callCenter = new CallCenter(Name = 'CallCenter');
        list<CallCenter>CllCent=[Select id From CallCenter];
        
        List<VoiceCall> vcList = New List<VoiceCall>();
        VoiceCall vCall = New VoiceCall();
        vCall.CallResolution='Not Interested';
        vCall.ToPhoneNumber= '+19123456789';
        vCall.VendorType = 'ContactCenter';
        vCall.CallStartDateTime=System.Now();
        vCall.CallEndDateTime=System.Now();
        vCall.FromPhoneNumber='+17039672885';
        vCall.CallType='Inbound';
        vCall.CallCenterId = CllCent[0].Id;
        vcList.add(vCall);
        Insert vcList;
    }  
   
}