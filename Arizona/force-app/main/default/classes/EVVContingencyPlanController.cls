/**
 * EVVContingencyPlanController
 *
 * Backs the EVVContingencyPlan Visualforce page, which renders the AHCCCS
 * Policy 540 Attachment D "EVV Member Contingency/Back-Up Plan" form as a
 * downloadable PDF (renderAs="pdf"), replicating the original form's layout
 * and exact field wording.
 *
 * Member Name / AHCCCS ID / Date of Plan are pulled from the Contact record
 * when a recordId is supplied via the URL (?recordId=...), falling back to
 * blank lines (matching the original fillable form) if no record is supplied.
 */
public with sharing class EVVContingencyPlanController {

    public Contact memberContact { get; private set; }

    public String memberName { get; private set; }
    public String ahcccsId { get; private set; }
    public String dateOfPlan { get; private set; }

    // Back-up plan contact details (Step 1 row). Defaulted to match the
    // sample values on the source form; override via URL params if needed.
    public String backupAgencyName { get; private set; }
    public String backupAgencyPhone { get; private set; }

    public EVVContingencyPlanController() {
        Map<String, String> params = ApexPages.currentPage().getParameters();

        String recordId = params.get('recordId');
        if (String.isNotBlank(recordId)) {
            loadContact(recordId);
        }

        // AHCCCS ID and Date of Plan are not standard Contact fields in every
        // org, so they're accepted as explicit URL params and/or custom
        // fields on Contact -- adjust the field API names below to match
        // your org's actual schema if different.
        if (String.isBlank(ahcccsId)) {
            ahcccsId = params.get('ahcccsId');
        }
        dateOfPlan = String.isNotBlank(params.get('dateOfPlan'))
            ? params.get('dateOfPlan')
            : Date.today().format();

        backupAgencyName = String.isNotBlank(params.get('agencyName'))
            ? params.get('agencyName')
            : 'Arizona Lionhearts';
        backupAgencyPhone = String.isNotBlank(params.get('agencyPhone'))
            ? params.get('agencyPhone')
            : '480-253-9360';
    }

    private void loadContact(String recordId) {
        try {
            Id cId = (Id) recordId;
            List<Contact> matches = [
                SELECT Id, Name, FirstName, LastName
                FROM Contact
                WHERE Id = :cId
                WITH USER_MODE
                LIMIT 1
            ];
            if (!matches.isEmpty()) {
                memberContact = matches[0];
                memberName = memberContact.Name;
            }
        } catch (Exception e) {
            memberContact = null;
        }
    }
}