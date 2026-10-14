global class AutoQACaseScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {

        List<Case> casesToInsert = new List<Case>();

        // Weekly QA Case (unchanged - original production logic)
        casesToInsert.add(new Case(
           AccountId = '001Vb00000aCIHfIAO', // Hybrid Account
          //  AccountId = '001WA00000QSxsbYAD',
            Foundation_Request_Type__c = 'Performance Alert Review',
            Origin = 'System',
            Status = 'New',
            RecordTypeId = '012Vb000007oEJtIAM',
       //   RecordTypeId = '012WA000000j58PYAQ',
            Subject = 'Performance Alert Review'
        ));

        // ================================================================
        // NEW: Foundation Digital Support - additive only, block above is
        // completely untouched.
        //
        // Setting Case_Category__c = 'New Digital Support' is what makes
        // Foundation_Record__c evaluate true on this new Case (verified
        // empirically against this org - Foundation_Record__c is a formula
        // field, so there is no existing record to check it on before insert,
        // it's driven directly at creation time instead). No RecordTypeId is
        // set here - Foundation_Record__c = TRUE is the only thing downstream
        // Foundation logic should ever depend on, not a specific RecordType.
        //
        // Field substitutions applied exactly as requested:
        //   Foundation_Request_Type__c -> Case_Request__c
        //   Status                     -> Status_Filtered__c
        // ================================================================
        casesToInsert.add(new Case(
           AccountId = '001Vb00000aCIHfIAO', // Hybrid Account
            Case_Category__c = 'New Digital Support',
            Case_Request__c = 'Performance Alert Review',
            Origin = 'System',
            Status_Filtered__c = 'New',
            Subject = 'Performance Alert Review (Foundation)'
        ));

        if (!casesToInsert.isEmpty()) {
            insert casesToInsert;
        }

        System.debug('AUTO QA CASES CREATED ==> ' + casesToInsert);
    }
}