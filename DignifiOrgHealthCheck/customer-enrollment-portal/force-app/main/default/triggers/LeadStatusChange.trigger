trigger LeadStatusChange on Lead (before update) {
    if (Trigger.isUpdate){
        for (Lead L : Trigger.new){
            // Enrollment Leads manage Status through the enrollment Lead path
            // (enrollmentLeadPath); all other Leads keep the existing behavior.
            if (String.isNotBlank(L.Enrollment_Submission_Key__c)) {
                continue;
            }
            System.debug('Record updated successfully');
            L.Status = 'Working-Contacted';
        }
    }

}
