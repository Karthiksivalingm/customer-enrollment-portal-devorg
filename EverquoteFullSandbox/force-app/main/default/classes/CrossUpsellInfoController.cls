public class CrossUpsellInfoController {
	public final Opportunity opportunity {get; set;}
    private final Map<String, Id> upsellRecordTypeIdsByName {get; set;}

    public CrossUpsellInfoController(ApexPages.StandardController stdController) {
        opportunity = (Opportunity)stdController.getRecord();
        upsellRecordTypeIdsByName = new Map<String, Id>();
        for(RecordType rt : [
            SELECT Id, Name
            FROM RecordType
            WHERE SobjectType = 'Upsell__c'
            AND Name IN ('Auto', 'Home', 'Life')
        ]){
            upsellRecordTypeIdsByName.put(rt.Name, rt.Id);
        }
    }
    
    public Upsell__c getAutoUpsell() {
        List<Upsell__c> upsells = [
            SELECT Id, Premium_Lift__c, Preferred_Lift__c, 
            Standard_Lift__c, Non_Standard_Lift__c, X10_mi_Radius_Lift__c, X25_mi_Radius_Lift__c,
            X50_mi_Radius_Lift__c, Whole_State_Lift__c,X10_mi_Radius_Zip__c, X25_mi_Radius_Zip__c,
            X50_mi_Radius_Zip__c, Whole_State_Zip__c, Weekday_Cap_Expansion_Lift__c, 
            Cap_Filled_Rate_Monday__c, Hour_Hit_Cap_By_Mon__c, Cap_Filled_Rate_Tuesday__c,
            Hour_Hit_Cap_By_Tues__c, Cap_Filled_Rate_Wed__c, Hour_Hit_Cap_By_Wed__c,
            Cap_Filled_Rate_Thurs__c, Hour_Hit_Cap_By_Thurs__c, Cap_Filled_Rate_Fri__c, 
            Hour_Hit_Cap_By_Fri__c, Cap_Filled_Rate_Sat__c, Hour_Hit_Cap_By_Sat__c,
            Sat_Cap_Expansion_Lift__c, Cap_Filled_Rate_Sun__c, Hour_Hit_Cap_By_Sun__c,
            Sun_Cap_Expansion_Lift__c, Active_Hour_Rate_Mon__c, Monday_Biz_Hour_Expansion__c, 
            Monday_Off_Hour_Expansion__c, Active_Hour_Rate_Tues__c, Tuesday_Biz_Hour_Expansion__c, 
            Tuesday_Off_Hour_Expansion__c, Active_Hour_Rate_Wed__c, Wednesday_Biz_Hour_Expansion__c, 
            Wednesday_Off_Hour_Expansion__c, Active_Hour_Rate_Thurs__c, Thursday_Biz_Hour_Expansion__c, 
            Thursday_Off_Hour_Expansion__c, Active_Hour_Rate_Fri__c, Friday_Biz_Hour_Expansion__c, 
            Friday_Off_Hour_Expansion__c, Active_Hour_Rate_Sat__c, Saturday_Hour_Expansion__c, 
            Active_Hour_Rate_Sun__c, Sunday_Hour_Expansion__c, Home_Premium_Lift__c, Home_Basic_Lift__c,
            Taking_Premium__c, Premium_Exclusive_Available__c, Taking_Preferred__c, Preferred_Exclusive_Available__c,
            Taking_Standard__c, Standard_Exclusive_Available__c, Taking_Non_Standard__c, Non_standard_Exclusive_Available__c,
            Add_Day_Fri__c, Add_Day_Mon__c, Add_Day_Sat__c, Add_Day_Sun__c, Add_Day_Thurs__c, Add_Day_Tues__c,
            Add_Day_Wed__c, Monday_Hours__c, Tuesday_Hours__c, Wednesday_Hours__c,
            Thursday_Hours__c, Friday_Hours__c, Saturday_Hours__c, Sunday_Hours__c, Number_of_Campaigns__c,
            Paused_At__c, Resume_At__c, Weekday_Cap_Filled_Rate__c
            FROM Upsell__c
            WHERE Master_Opportunity__c = :opportunity.Id
            AND RecordTypeId = :upsellRecordTypeIdsByName.get('Auto')
            LIMIT 1];
        if(upsells.size() > 0){
            return upsells[0];
        }
        return null;
    }
    
    public Upsell__c getHomeUpsell() {
        List<Upsell__c> upsells = [
            SELECT Id, Premium_Lift__c, Preferred_Lift__c, 
            Standard_Lift__c, Non_Standard_Lift__c, X10_mi_Radius_Lift__c, X25_mi_Radius_Lift__c,
            X50_mi_Radius_Lift__c, Whole_State_Lift__c,X10_mi_Radius_Zip__c, X25_mi_Radius_Zip__c,
            X50_mi_Radius_Zip__c, Whole_State_Zip__c, Weekday_Cap_Expansion_Lift__c, 
            Cap_Filled_Rate_Monday__c, Hour_Hit_Cap_By_Mon__c, Cap_Filled_Rate_Tuesday__c,
            Hour_Hit_Cap_By_Tues__c, Cap_Filled_Rate_Wed__c, Hour_Hit_Cap_By_Wed__c,
            Cap_Filled_Rate_Thurs__c, Hour_Hit_Cap_By_Thurs__c, Cap_Filled_Rate_Fri__c, 
            Hour_Hit_Cap_By_Fri__c, Cap_Filled_Rate_Sat__c, Hour_Hit_Cap_By_Sat__c,
            Sat_Cap_Expansion_Lift__c, Cap_Filled_Rate_Sun__c, Hour_Hit_Cap_By_Sun__c,
            Sun_Cap_Expansion_Lift__c, Active_Hour_Rate_Mon__c, Monday_Biz_Hour_Expansion__c, 
            Monday_Off_Hour_Expansion__c, Active_Hour_Rate_Tues__c, Tuesday_Biz_Hour_Expansion__c, 
            Tuesday_Off_Hour_Expansion__c, Active_Hour_Rate_Wed__c, Wednesday_Biz_Hour_Expansion__c, 
            Wednesday_Off_Hour_Expansion__c, Active_Hour_Rate_Thurs__c, Thursday_Biz_Hour_Expansion__c, 
            Thursday_Off_Hour_Expansion__c, Active_Hour_Rate_Fri__c, Friday_Biz_Hour_Expansion__c, 
            Friday_Off_Hour_Expansion__c, Active_Hour_Rate_Sat__c, Saturday_Hour_Expansion__c, 
            Active_Hour_Rate_Sun__c, Sunday_Hour_Expansion__c, Home_Premium_Lift__c, Home_Basic_Lift__c,
            Taking_Premium__c, Premium_Exclusive_Available__c, Taking_Basic__c, Basic_Exclusive_Available__c,
            Add_Day_Fri__c, Add_Day_Mon__c, Add_Day_Sat__c, Add_Day_Sun__c, Add_Day_Thurs__c, Add_Day_Tues__c,
            Add_Day_Wed__c, Monday_Hours__c, Tuesday_Hours__c, Wednesday_Hours__c,
            Thursday_Hours__c, Friday_Hours__c, Saturday_Hours__c, Sunday_Hours__c, Number_of_Campaigns__c,
             Paused_At__c, Resume_At__c, Weekday_Cap_Filled_Rate__c, Home_Exclusive_Available__c, Taking_Home__c
            
            FROM Upsell__c
            WHERE Master_Opportunity__c = :opportunity.Id
            AND RecordTypeId = :upsellRecordTypeIdsByName.get('Home')
            LIMIT 1];
        if(upsells.size() > 0){
            return upsells[0];
        }
        return null;
    } 
    public Upsell__c getLifeUpsell() {
        List<Upsell__c> upsells = [
            SELECT Id, Premium_Lift__c, Preferred_Lift__c, 
            Standard_Lift__c, Non_Standard_Lift__c, X10_mi_Radius_Lift__c, X25_mi_Radius_Lift__c,
            X50_mi_Radius_Lift__c, Whole_State_Lift__c,X10_mi_Radius_Zip__c, X25_mi_Radius_Zip__c,
            X50_mi_Radius_Zip__c, Whole_State_Zip__c, Weekday_Cap_Expansion_Lift__c, 
            Cap_Filled_Rate_Monday__c, Hour_Hit_Cap_By_Mon__c, Cap_Filled_Rate_Tuesday__c,
            Hour_Hit_Cap_By_Tues__c, Cap_Filled_Rate_Wed__c, Hour_Hit_Cap_By_Wed__c,
            Cap_Filled_Rate_Thurs__c, Hour_Hit_Cap_By_Thurs__c, Cap_Filled_Rate_Fri__c, 
            Hour_Hit_Cap_By_Fri__c, Cap_Filled_Rate_Sat__c, Hour_Hit_Cap_By_Sat__c,
            Sat_Cap_Expansion_Lift__c, Cap_Filled_Rate_Sun__c, Hour_Hit_Cap_By_Sun__c,
            Sun_Cap_Expansion_Lift__c, Active_Hour_Rate_Mon__c, Monday_Biz_Hour_Expansion__c, 
            Monday_Off_Hour_Expansion__c, Active_Hour_Rate_Tues__c, Tuesday_Biz_Hour_Expansion__c, 
            Tuesday_Off_Hour_Expansion__c, Active_Hour_Rate_Wed__c, Wednesday_Biz_Hour_Expansion__c, 
            Wednesday_Off_Hour_Expansion__c, Active_Hour_Rate_Thurs__c, Thursday_Biz_Hour_Expansion__c, 
            Thursday_Off_Hour_Expansion__c, Active_Hour_Rate_Fri__c, Friday_Biz_Hour_Expansion__c, 
            Friday_Off_Hour_Expansion__c, Active_Hour_Rate_Sat__c, Saturday_Hour_Expansion__c, 
            Active_Hour_Rate_Sun__c, Sunday_Hour_Expansion__c, Home_Premium_Lift__c, Home_Basic_Lift__c,
            Taking_Premium__c, Premium_Exclusive_Available__c, Taking_Basic__c, Basic_Exclusive_Available__c,
            Add_Day_Fri__c, Add_Day_Mon__c, Add_Day_Sat__c, Add_Day_Sun__c, Add_Day_Thurs__c, Add_Day_Tues__c,
            Add_Day_Wed__c, Monday_Hours__c, Tuesday_Hours__c, Wednesday_Hours__c,
            Thursday_Hours__c, Friday_Hours__c, Saturday_Hours__c, Sunday_Hours__c, Number_of_Campaigns__c,
            Paused_At__c, Resume_At__c, Weekday_Cap_Filled_Rate__c, Preferred_Exclusive_Available__c,Taking_Preferred__c,
            Taking_Standard__c, Standard_Exclusive_Available__c
            
            FROM Upsell__c
            WHERE Master_Opportunity__c = :opportunity.Id
            AND RecordTypeId = :upsellRecordTypeIdsByName.get('Life')
            LIMIT 1];
        if(upsells.size() > 0){
            return upsells[0];
        }
        return null;
    } 
}