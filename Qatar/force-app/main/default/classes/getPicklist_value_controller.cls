public class getPicklist_value_controller {
    
    @AuraEnabled
    public static MAP<String,list<string>> getpicklistMapApex(){
        MAP<String,list<string>> picklistMap = new MAP<String,list<string>>();
        List<String> picklistAPIs = new List<String>{'MUSEUMS__c','BUSINESS__c','EDUCATION__c','POLITICS__c',
                                                        'PRIVATE_FAMILY__c','MEDIA_MARKETING__c'};
        Schema.DescribeSObjectResult objSchema = Contact.sObjectType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objSchema.fields.getmap();
        
        //System.debug('Museum >> '+Museum);
        for(String str: picklistAPIs){
            
            for(Schema.Picklistentry pl : fieldmap.get(str).getDescribe().getpicklistValues())
            {
                if(picklistMap.containsKey(str)){
                    List<String> pickList = picklistMap.get(str);
                    pickList.add(pl.getValue());
                    pickList.sort();
                    picklistMap.put(str,pickList);
                }else{
                    picklistMap.put(str,new List<String>{pl.getValue()});
                }
            }
        }
        
        System.debug('picklistMap >>> '+picklistMap);
        
        return picklistMap;
    }
    
    @AuraEnabled
    public static string savePicklistValues(ID conid,String musumTxt,String businessTxt,String eduTxt,String poltcTxt,String pvtFamTxt,String MediaMrktTxt){
        system.debug('Contact values >>> '+ conid +' '+musumTxt );
        String msg = '';
        Contact cont = new Contact();
        cont.id = conid;
        cont.MUSEUMS__c = musumTxt;
        cont.BUSINESS__c = businessTxt;
        cont.EDUCATION__c = eduTxt;
        cont.POLITICS__c = poltcTxt;
        cont.PRIVATE_FAMILY__c = pvtFamTxt;
        cont.MEDIA_MARKETING__c = MediaMrktTxt;
        system.debug('Contact update call >>> '+ cont);
        try{
            update cont;
            return 'success';
        }catch(DmlException e){
            //Any type of Validation Rule error message, Required field missing error message, Trigger error message etc..
            //we can get from DmlException
             
            //Get All DML Messages
            for (Integer i = 0; i < e.getNumDml(); i++) {
                //Get Validation Rule & Trigger Error Messages
                msg =+ e.getDmlMessage(i) +  '\n' ;
            }
            //throw DML exception message
            throw new AuraHandledException(msg);
        }catch(Exception e){
            throw new AuraHandledException('Error Exception happend'+e.getMessage());      
        }finally {
        }
    }
    
    
   @AuraEnabled
    public static List<sobject> getSelectedPLValues(ID conid){
     
        if(conid != null){
            return [Select ID,MUSEUMS__c,BUSINESS__c,EDUCATION__c,POLITICS__c,PRIVATE_FAMILY__c,MEDIA_MARKETING__c FROM Contact Where ID=:conid];
        }else{
            return null;
        }
    }
    
    @AuraEnabled
    public static list<string> getpicklistMethodApex(){
        
        Schema.DescribeSObjectResult objSchema = Contact.sObjectType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objSchema.fields.getmap();
        List<Schema.Picklistentry>fld =fieldmap.get('MUSEUMS__c').getDescribe().getpicklistValues();
        System.debug('fld'+fld);
        List<String> pickList = new List<String>();
        
        for(Schema.Picklistentry pl : fld)
        {
            pickList.add(pl.getValue());
        }
        System.debug('pickList'+pickList);
        pickList.sort();
        return pickList;
    }
    
    
    @AuraEnabled
    public static Boolean getProfileInfo(){
        try{
            system.debug('>>> getProfileInfo >>> ');
            String profileId = UserInfo.getProfileId();
            Profile profileus = [SELECT Id, Name FROM Profile WHERE Id =:profileId];
            
            if(profileus.Name == 'System Administrator' || profileus.Name == 'L3 - Admin Edit - No Private'){
                system.debug('>>> True >>> '+ profileus.Name);
                return true;
            }else{
                system.debug('>>> false >>> ');
                return false;
            }
            
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage()); 
        }
    }
}