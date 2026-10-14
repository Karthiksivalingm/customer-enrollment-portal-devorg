public inherited sharing class LeadMergeService {

    public static void mergeLeadsWithNote(List<MergeRequest> mergeRequests) {
        if (mergeRequests.isEmpty()) {
            return;
        }

        List<ContentNote> notesToInsert = new List<ContentNote>();
        List<Lead> masters = new List<Lead>();
        List<Lead> olds = new List<Lead>();

        for (MergeRequest mr : mergeRequests) {
            try {
                Lead master = copyLeadForMerge(mr.newLead, mr.oldLead);
                
                masters.add(master);
                olds.add(mr.oldLead);

                String oldFirstName = (String)mr.oldLead.get('FirstName');
                String oldLastName  = (String)mr.oldLead.get('LastName');

                ContentNote cn = new ContentNote();
                cn.Title = 'Lead Merge';
                cn.Content = Blob.valueOf(
                    'Lead ' + mr.oldLead.Id + '(' + mr.oldLead.FirstName + ' ' + mr.oldLead.LastName + ') was merged into lead ' + master.Id
                );
                notesToInsert.add(cn);

            } catch (Exception e) {
                System.debug('Error merging leads: ' + e.getMessage());
            }
        }

        if (!masters.isEmpty()) {
            for (Integer i = 0; i < masters.size(); i++) {
                try {
                    Database.merge(masters[i], olds[i], false);
                } catch (Exception e) {
                    System.debug('Error merging leads: ' + e.getMessage());
                }
            }
        }

        if (!notesToInsert.isEmpty()) {
            insert notesToInsert;

            List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
            for (Integer i = 0; i < notesToInsert.size(); i++) {
                ContentNote cn = notesToInsert[i];
                Lead master = masters[i];

                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = cn.Id;
                cdl.LinkedEntityId = master.Id;
                cdl.ShareType = 'V';
                cdl.Visibility = 'AllUsers';
                linksToInsert.add(cdl);
            }
            insert linksToInsert;
        }
    }
    
    private static final List<String> FIELDS_TO_COPY = new List<String>{
        'FirstName',
        'LastName',
        'Email',
        'Phone',
        'Company',
        'Tax_Id__c',
        'Status',
        'Is_Franchise__c',
        'Resale_Number__c',
        'LeadSource',
        'Website',
        'Facebook__c',
        'Instagram__c',
        'Twitter__c',
        'Has_Physical_Store__c',
        'Is_Tax_Exempt__c',
        'Title',
        'Store_Square_Footage__c',
        'Affinity_Brands__c',
        'Goodr_Visual_Merchandising__c',
        'Retailer_Communication_Opt_In__c',
        'Terms_of_Service_Agreement__c',
        'Final_Comments__c'
    };
    
    private static Lead copyLeadForMerge(Lead newLead, Lead oldLead) {
        Lead master = new Lead(Id = newLead.Id);
        
        for (String fieldName : FIELDS_TO_COPY) {
            Object newValue = newLead.get(fieldName);
            Object oldValue = oldLead.get(fieldName);
    
            if (newValue != null) {
                master.put(fieldName, newValue);
            } else if (oldValue != null) {
                master.put(fieldName, oldValue);
            }
        }

        return master;
    }
    
    public class MergeRequest {
        public Lead newLead;
        public Lead oldLead;
        public MergeRequest(Lead n, Lead o) {
            newLead = n;
            oldLead = o;
        }
    }
}