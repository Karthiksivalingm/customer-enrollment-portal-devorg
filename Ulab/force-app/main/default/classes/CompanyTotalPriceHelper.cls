public class CompanyTotalPriceHelper implements Schedulable{
@AuraEnabled
    public static void callBatch(String companyId){
         ID BatchId = Database.executeBatch(new CompanyTotalPriceBatch(companyId));
    }
    public void execute(SchedulableContext sc) {
        ID BatchId = Database.executeBatch(new CompanyTotalPriceBatch(null), 100);
    }
}