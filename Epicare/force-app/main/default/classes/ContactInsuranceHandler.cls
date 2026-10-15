public class ContactInsuranceHandler {

    public static void syncInsurance(
        List<Contact> contacts,
        Map<Id, Contact> oldMap
    ) {

        Set<Id> contactIds = new Set<Id>();

        for(Contact c : contacts){
            contactIds.add(c.Id);
        }

        Map<Id, Set<String>> existingCerts = new Map<Id, Set<String>>();
        Map<Id, Set<String>> existingChecks = new Map<Id, Set<String>>();

        for(Certification__c cert : [
            SELECT Id,
                   Agent__c,
                   Insurance_Type__c
            FROM Certification__c
            WHERE Agent__c IN :contactIds
        ]){

            if(!existingCerts.containsKey(cert.Agent__c)){
                existingCerts.put(cert.Agent__c,new Set<String>());
            }

            existingCerts.get(cert.Agent__c).add(cert.Insurance_Type__c);
        }

        Map<String,Certification__c> certMap =
            new Map<String,Certification__c>();

        for(Certification__c cert : [
            SELECT Id,
                   Agent__c,
                   Insurance_Type__c
            FROM Certification__c
            WHERE Agent__c IN :contactIds
        ]){

            certMap.put(
                cert.Agent__c+'-'+cert.Insurance_Type__c,
                cert
            );
        }

        Map<String,Onboarding_Checklist__c> checkMap =
            new Map<String,Onboarding_Checklist__c>();

        for(Onboarding_Checklist__c chk : [
            SELECT Id,
                   Agent__c,
                   Insurance_Type__c
            FROM Onboarding_Checklist__c
            WHERE Agent__c IN :contactIds
        ]){

            checkMap.put(
                chk.Agent__c+'-'+chk.Insurance_Type__c,
                chk
            );
        }

        List<Certification__c> certInsert = new List<Certification__c>();
        List<Onboarding_Checklist__c> checkInsert = new List<Onboarding_Checklist__c>();

        List<Certification__c> certDelete = new List<Certification__c>();
        List<Onboarding_Checklist__c> checkDelete = new List<Onboarding_Checklist__c>();

        for(Contact c : contacts){

            Set<String> newValues = new Set<String>();

            if(String.isNotBlank(c.Insurance_Types__c)){
                newValues.addAll(c.Insurance_Types__c.split(';'));
            }

            Set<String> oldValues = new Set<String>();

            if(oldMap != null){

                Contact oldCon = oldMap.get(c.Id);

                if(String.isNotBlank(oldCon.Insurance_Types__c)){
                    oldValues.addAll(oldCon.Insurance_Types__c.split(';'));
                }
            }

            // CREATE MISSING RECORDS
            for(String type : newValues){

                if(!certMap.containsKey(c.Id+'-'+type)){

                    certInsert.add(new Certification__c(
                        Agent__c = c.Id,
                        Insurance_Type__c = type
                    ));
                }

                if(!checkMap.containsKey(c.Id+'-'+type)){

                    checkInsert.add(new Onboarding_Checklist__c(
                        Agent__c = c.Id,
                        Insurance_Type__c = type
                    ));
                }
            }

            // DELETE REMOVED RECORDS
            for(String type : oldValues){

                if(!newValues.contains(type)){

                    if(certMap.containsKey(c.Id+'-'+type)){
                        certDelete.add(certMap.get(c.Id+'-'+type));
                    }

                    if(checkMap.containsKey(c.Id+'-'+type)){
                        checkDelete.add(checkMap.get(c.Id+'-'+type));
                    }
                }
            }
        }

        if(!certInsert.isEmpty()){
            insert certInsert;
        }

        if(!checkInsert.isEmpty()){
            insert checkInsert;
        }

        if(!certDelete.isEmpty()){
            delete certDelete;
        }

        if(!checkDelete.isEmpty()){
            delete checkDelete;
        }
    }
}