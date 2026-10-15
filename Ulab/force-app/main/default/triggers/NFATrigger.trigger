trigger NFATrigger on New_Feature_Association__c (before insert) {
    public set<id> accountIds = new set<id>();
    public set<id> uLabFeatureIds = new set<id>(); 
    for(New_Feature_Association__c nfaVar : trigger.new)
    {
        accountIds.add(nfaVar.Customer__c);
        uLabFeatureIds.add(nfaVar.uLab_Feature__c);
    }
    list<New_Feature_Association__c> nfaList = [select id, name from New_Feature_Association__c where Customer__c IN :accountIds and uLab_Feature__c IN :uLabFeatureIds];
    
    for(New_Feature_Association__c nfaVar : trigger.new)
    {
        if(nfaList.size()>=1)
        	nfaVar.addError('Only one NFA record can be created for each Company and uLab Feature');
    }
}