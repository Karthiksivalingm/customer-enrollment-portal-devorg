@isTest
public class deleteOldConversationBatchAndSchedular {

     @isTest
    static void deleteConversationEntryData(){
        List<Sobject > recordToDelete = new List<Sobject >();
        for (Integer i = 0; i < 200; i++) {
            Account entrys = new Account();
            entrys.Name  = 'Test Entry1';
            recordToDelete.add(entrys);            
        }
        insert recordToDelete;
        Integer recordCount = [SELECT COUNT() FROM ConversationEntry WHERE CreatedDate < :Date.today().addDays(-90)];
        System.assertEquals(0, recordCount, 'All test records should be inserted.');
        Datetime now = Datetime.now().addMinutes(5);
        String cornString=now.format('s m H d M ? yyyy');
        
        Test.startTest();
        System.schedule('OneTimeJob', cornString, new ConversationEntryBatchScheduler ());/// change your Schedule class name
        
        Test.stopTest();
        
        Integer remainingRecords = [SELECT COUNT() FROM ConversationEntry WHERE CreatedDate < :Date.today().addDays(-90)];
        System.assertEquals(0, remainingRecords, 'All old records should be deleted.');
    }
}