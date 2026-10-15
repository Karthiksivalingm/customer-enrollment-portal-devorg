public with sharing class ContactProfilePDFController {

    public Contact contact { get; set; }
    public List<Guest_List__c> guestList { get; set; }
    public List<Visit_to_Doha__c> visitsToDoha { get; set; }
    public List<Gift_and_Donation__c> gifts { get; set; }
    public List<HE_Request__c> herequests { get; set; }
    public List<Children__c> Children { get; set; }
    public List<Meeting_Notes__c> Meetingandnotes { get; set; }
    public List<Session_Attendance__c> sessionAttendances { get; set; }
    public String profilePictureUrl { get; set; }
    public Boolean isLoading { get; set; }
    public String cleanAreaOfInterest { get; set; }

    // ── Safely resolved relationship names (avoids null-dereference) ───────────
    public String adminContactName { get; set; }
    public String companyAffiliatedName { get; set; }
    public String companyAffiliated1Name { get; set; }
    public String companyAffiliated2Name { get; set; }
    public String companyAffiliated3Name { get; set; }
    public String spouseName { get; set; }
    public String connectionName { get; set; }
    public String recordTypeName { get; set; }

    // ── Safe boolean flags ────────────────────────────────────────────────────
    public Boolean hasGifts {
        get { return gifts != null && gifts.size() > 0; }
    }
    public Boolean hasVisits {
        get { return visitsToDoha != null && visitsToDoha.size() > 0; }
    }
    public Boolean hasGuestList {
        get { return guestList != null && guestList.size() > 0; }
    }
    public Boolean hasherequest {
        get { return herequests != null && herequests.size() > 0; }
    }
    public Boolean hasChildren {
        get { return children != null && children.size() > 0; }
    }
    public Boolean hasmeeting {
        get { return Meetingandnotes != null && Meetingandnotes.size() > 0; }
    }
    public Boolean hasSessionAttendance {
        get { return sessionAttendances != null && sessionAttendances.size() > 0; }
    }

    // Deceased Date formatted as a plain date (no time-of-day / timezone
    // string), regardless of whether the underlying field is Date or
    // DateTime. Using TEXT()/DateTime.format() on a DateTime field bakes in
    // "Wed Jun 17 00:00:00 GMT 2026"-style output, which is what we want to
    // avoid here.
    public String deceasedDateFormatted {
        get {
            if (contact == null || contact.Deceased_Date__c == null) {
                return null;
            }
            // Deceased_Date__c is a plain Date field (no time component).
            // Date only exposes the locale-based no-arg format(), not
            // format(String) — that overload exists only on Datetime — so
            // we build the MM/dd/yyyy string manually to get a fixed,
            // predictable format regardless of the running user's locale.
            Date d = contact.Deceased_Date__c;
            String mm = String.valueOf(d.month()).leftPad(2, '0');
            String dd = String.valueOf(d.day()).leftPad(2, '0');
            String yyyy = String.valueOf(d.year());
            return mm + '/' + dd + '/' + yyyy;
        }
    }

    public ContactProfilePDFController() {
        isLoading = false;
        guestList = new List<Guest_List__c>();
        visitsToDoha = new List<Visit_to_Doha__c>();
        gifts = new List<Gift_and_Donation__c>();
        herequests = new List<HE_Request__c>();
        Children = new List<Children__c>();
        Meetingandnotes = new List<Meeting_Notes__c>();
        sessionAttendances = new List<Session_Attendance__c>();

        String contactId = ApexPages.currentPage().getParameters().get('id');
        if (String.isNotBlank(contactId) && contactId.startsWith('003')) {
            fetchContactDetails(contactId);

            // Only continue if the contact actually loaded; otherwise every
            // downstream relationship/lookup access risks a null dereference.
            if (contact != null) {
                resolveSafeRelationshipNames();
                fetchProfilePicture(contactId);
                fetchGuestList(contactId);
                fetchVisitsToDoha(contactId);
                fetchGifts(contactId);
                fetchildren(contactId);
                fetchherequest(contactId);
                fetcmeetingandnotes(contactId);
                fetchSessionAttendances(contactId);
                cleanAreaOfInterest = stripHtmlAndEntities(contact.Area_O_I__c);
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Invalid or missing Contact record ID.'
            ));
        }
    }

    // Resolves every X__r.Name style relationship into a plain String up
    // front, in one guarded place, so the VF page never has to dereference
    // a relationship that may be null (deleted parent, no sharing access,
    // or simply blank lookup).
    //
    // IMPORTANT: we never write `contact.Contact__r` (or any other
    // `contact.X__r`) directly anymore. Accessing a parent relationship that
    // way can throw "List has no rows for assignment to SObject" at the
    // point Salesforce tries to materialize the related record — e.g. when
    // the lookup is populated but the related record was deleted/merged, or
    // the running user doesn't have sharing access to it. Going through
    // SObject.getSObject(...) inside a try/catch absorbs that failure and
    // treats the relationship as simply absent instead of crashing the page.
    private void resolveSafeRelationshipNames() {
        adminContactName        = safeRelationshipName(contact, 'Contact__r');
        companyAffiliatedName   = safeRelationshipName(contact, 'Company_Affiliated__r');
        companyAffiliated1Name  = safeRelationshipName(contact, 'Company_Affiliated_1__r');
        companyAffiliated2Name  = safeRelationshipName(contact, 'Company_Affiliated_2__r');
        companyAffiliated3Name  = safeRelationshipName(contact, 'Company_Affiliated_3__r');
        spouseName              = safeRelationshipName(contact, 'Spouse_Name__r');
        connectionName          = safeRelationshipName(contact, 'Connection__r');
        recordTypeName          = (contact.RecordType != null) ? contact.RecordType.Name : null;
    }

    // Generic null-safe ".Name" getter for any sObject relationship.
    private String safeName(SObject relatedRecord) {
        if (relatedRecord == null) {
            return null;
        }
        Object nameValue = relatedRecord.get('Name');
        return (nameValue != null) ? String.valueOf(nameValue) : null;
    }

    // Generic null-safe relationship-name getter that won't blow up even if the
    // related record is inaccessible (sharing) or the relationship can't be
    // resolved for any other reason (deleted/merged parent record, etc.).
    private String safeRelationshipName(SObject parent, String relationshipField) {
        try {
            SObject related = parent.getSObject(relationshipField);
            return safeName(related);
        } catch (Exception e) {
            // Relationship couldn't be resolved (deleted/merged parent, no
            // sharing access, etc.) — treat as simply absent rather than fatal.
            return null;
        }
    }

    // ── Picklist code -> label resolver ─────────────────────────────────────────
    // Used for compound-address sub-fields (e.g. Office_Address__StateCode__s,
    // Office_Address__CountryCode__s) where only the ISO-code variant of the
    // field exists on the object (no separate ...__State__s / ...__Country__s
    // label field was generated). This walks the field's own picklist metadata
    // — the exact same metadata that renders the dropdown in the edit form —
    // and maps the stored code back to its display label.
    //
    // Cached per (objectName.fieldName) for the lifetime of this controller
    // instance so repeated calls (State + Country, called once each here)
    // don't redo the describe call.
    private Map<String, Map<String, String>> picklistCodeToLabelCache = new Map<String, Map<String, String>>();

    private String getPicklistLabelFromCode(String objectName, String fieldName, String code) {
        if (String.isBlank(code)) return null;

        String cacheKey = objectName + '.' + fieldName;
        Map<String, String> codeToLabel = picklistCodeToLabelCache.get(cacheKey);

        if (codeToLabel == null) {
            codeToLabel = new Map<String, String>();
            try {
                Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe()
                    .get(objectName)
                    .getDescribe()
                    .fields.getMap()
                    .get(fieldName)
                    .getDescribe();

                for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                    codeToLabel.put(entry.getValue(), entry.getLabel());
                }
            } catch (Exception e) {
                // Field/describe not resolvable for some reason — fall back
                // to returning codes as-is rather than failing the page.
            }
            picklistCodeToLabelCache.put(cacheKey, codeToLabel);
        }

        String label = codeToLabel.get(code);
        return (label != null) ? label : code; // fallback: show the raw code if no match found
    }

    public class SocialMediaRow {
        public String label {get;set;}
        public String value {get;set;}

        public SocialMediaRow(String label, String value){
            this.label = label;
            this.value = value;
        }
    }

    public List<SocialMediaRow> getSocialMediaRows() {

        List<SocialMediaRow> rows = new List<SocialMediaRow>();

        if (contact == null) return rows;

        if(String.isNotBlank(contact.Instagram_Handle__c))
            rows.add(new SocialMediaRow('Instagram',
                                        contact.Instagram_Handle__c));

        if(String.isNotBlank(contact.Social_Media_Twitter__c))
            rows.add(new SocialMediaRow('Twitter',
                                        contact.Social_Media_Twitter__c));

        if(String.isNotBlank(contact.LinkedIn__c))
            rows.add(new SocialMediaRow('LinkedIn',
                                        contact.LinkedIn__c));

        if(String.isNotBlank(contact.Tiktok__c))
            rows.add(new SocialMediaRow('TikTok',
                                        contact.Tiktok__c));

        if(String.isNotBlank(contact.Facebook__c))
            rows.add(new SocialMediaRow('Facebook',
                                        contact.Facebook__c));

        if(String.isNotBlank(contact.Snap__c))
            rows.add(new SocialMediaRow('Snapchat',
                                        contact.Snap__c));

        if(String.isNotBlank(contact.Website1__c))
            rows.add(new SocialMediaRow('Website 1',
                                        contact.Website1__c));

        if(String.isNotBlank(contact.Website2__c))
            rows.add(new SocialMediaRow('Website 2',
                                        contact.Website2__c));

        return rows;
    }

    public class ConnectionRow {
        public String label {get;set;}
        public String value {get;set;}

        public ConnectionRow(String label, String value){
            this.label = label;
            this.value = value;
        }
    }

    public List<ConnectionRow> getConnectionRows() {

        List<ConnectionRow> rows = new List<ConnectionRow>();

        if(contact != null){

            if(String.isNotBlank(connectionName))
            {
                rows.add(
                    new ConnectionRow(
                        'Connection',
                        connectionName
                    )
                );
            }

            if(String.isNotBlank(contact.CONNECTION_NOTES__c))
            {
                rows.add(
                    new ConnectionRow(
                        'Connection Notes',
                        contact.CONNECTION_NOTES__c
                    )
                );
            }
        }

        return rows;
    }

    public class AdditionalContactRow {
        public String label {get;set;}
        public String value {get;set;}

        public AdditionalContactRow(String label, String value){
            this.label = label;
            this.value = value;
        }
    }

    public List<AdditionalContactRow> getAdditionalContactRows() {
    List<AdditionalContactRow> rows = new List<AdditionalContactRow>();
    if(contact != null){

        if(String.isNotBlank(companyAffiliated1Name))
        {
            rows.add(
                new AdditionalContactRow(
                    'Company Affiliated - 1',
                    companyAffiliated1Name
                )
            );
        }
        if(String.isNotBlank(contact.Job_Title_1__c))
        {
            rows.add(
                new AdditionalContactRow(
                    'Job Title - 1',
                    contact.Job_Title_1__c
                )
            );
        }

        if(String.isNotBlank(companyAffiliated2Name))
        {
            rows.add(
                new AdditionalContactRow(
                    'Company Affiliated - 2',
                    companyAffiliated2Name
                )
            );
        }
        if(String.isNotBlank(contact.Job_Title_2__c))
        {
            rows.add(
                new AdditionalContactRow(
                    'Job Title - 2',
                    contact.Job_Title_2__c
                )
            );
        }

        if(String.isNotBlank(companyAffiliated3Name))
        {
            rows.add(
                new AdditionalContactRow(
                    'Company Affiliated - 3',
                    companyAffiliated3Name
                )
            );
        }
        if(String.isNotBlank(contact.Job_Title_3__c))
        {
            rows.add(
                new AdditionalContactRow(
                    'Job Title - 3',
                    contact.Job_Title_3__c
                )
            );
        }


    }
    return rows;
}
    public class GuestManagementRow {
        public String label {get;set;}
        public String value {get;set;}

        public GuestManagementRow(String label, String value){
            this.label = label;
            this.value = value;
        }
    }

    public List<GuestManagementRow> getGuestManagementRows() {

        List<GuestManagementRow> rows = new List<GuestManagementRow>();

        if(contact != null){

            if(String.isNotBlank(contact.Dietary_Restrictions__c))
            {
                rows.add(
                    new GuestManagementRow(
                        'Dietary Restrictions',
                        contact.Dietary_Restrictions__c
                    )
                );
            }

            if(String.isNotBlank(contact.Allergies__c))
            {
                rows.add(
                    new GuestManagementRow(
                        'Allergies',
                        contact.Allergies__c
                    )
                );
            }
        }

        return rows;
    }

    public class CurrentAddressRow {
        public String label {get;set;}
        public String value {get;set;}

        public CurrentAddressRow(String label, String value){
            this.label = label;
            this.value = value;
        }
    }

    public List<CurrentAddressRow> getCurrentAddressRows() {

        List<CurrentAddressRow> rows = new List<CurrentAddressRow>();

        if(contact != null){

            if(String.isNotBlank(contact.OtherStreet))
                rows.add(
                    new CurrentAddressRow(
                        'Street',
                        contact.OtherStreet
                    )
                );

            if(String.isNotBlank(contact.OtherCity))
                rows.add(
                    new CurrentAddressRow(
                        'City',
                        contact.OtherCity
                    )
                );

            if(String.isNotBlank(contact.OtherState))
                rows.add(
                    new CurrentAddressRow(
                        'State/Province',
                        contact.OtherState
                    )
                );

            if(String.isNotBlank(contact.OtherPostalCode))
                rows.add(
                    new CurrentAddressRow(
                        'Zip/Postal Code',
                        contact.OtherPostalCode
                    )
                );

            if(String.isNotBlank(contact.OtherCountry))
                rows.add(
                    new CurrentAddressRow(
                        'Country',
                        contact.OtherCountry
                    )
                );

            if(String.isNotBlank(contact.Residing_City__c))
                rows.add(
                    new CurrentAddressRow(
                        'Residing City',
                        contact.Residing_City__c
                    )
                );

            if(String.isNotBlank(contact.Residing_Country__c))
                rows.add(
                    new CurrentAddressRow(
                        'Residing Country',
                        contact.Residing_Country__c
                    )
                );
        }

        return rows;
    }

    public class AdminContactRow {
        public String label {get;set;}
        public String value {get;set;}

        public AdminContactRow(String label, String value){
            this.label = label;
            this.value = value;
        }
    }

    public List<AdminContactRow> getAdminContactRows() {

        List<AdminContactRow> rows = new List<AdminContactRow>();

        // Show Admin Contact section only for Main Contact record type
        if(contact != null && recordTypeName == 'Main Contact'){

            if(String.isNotBlank(adminContactName))
                rows.add(
                    new AdminContactRow(
                        'Admin Contact',
                        adminContactName
                    )
                );

            if(String.isNotBlank(contact.Admin_Email__c))
                rows.add(
                    new AdminContactRow(
                        'Admin Email',
                        contact.Admin_Email__c
                    )
                );

            if(String.isNotBlank(contact.Admin_Phone__c))
                rows.add(
                    new AdminContactRow(
                        'Admin Phone',
                        contact.Admin_Phone__c
                    )
                );
        }

        return rows;
    }

    public class PermanentAddressRow {
        public String label {get;set;}
        public String value {get;set;}

        public PermanentAddressRow(String label, String value){
            this.label = label;
            this.value = value;
        }
    }

    public List<PermanentAddressRow> getPermanentAddressRows() {

        List<PermanentAddressRow> rows = new List<PermanentAddressRow>();

        if(contact != null){

            if(String.isNotBlank(contact.MailingStreet)){
                rows.add(
                    new PermanentAddressRow(
                        'Street',
                        contact.MailingStreet
                    )
                );
            }

            if(String.isNotBlank(contact.MailingCity)){
                rows.add(
                    new PermanentAddressRow(
                        'City',
                        contact.MailingCity
                    )
                );
            }

            if(String.isNotBlank(contact.MailingState)){
                rows.add(
                    new PermanentAddressRow(
                        'State/Province',
                        contact.MailingState
                    )
                );
            }

            if(String.isNotBlank(contact.MailingPostalCode)){
                rows.add(
                    new PermanentAddressRow(
                        'Zip/Postal Code',
                        contact.MailingPostalCode
                    )
                );
            }

            if(String.isNotBlank(contact.MailingCountry)){
                rows.add(
                    new PermanentAddressRow(
                        'Country',
                        contact.MailingCountry
                    )
                );
            }
        }

        return rows;
    }


    public class OfficeAddressRow {
        public String label {get;set;}
        public String value {get;set;}

        public OfficeAddressRow(String label, String value){
            this.label = label;
            this.value = value;
        }
    }

    public List<OfficeAddressRow> getOfficeAddressRows() {

        List<OfficeAddressRow> rows = new List<OfficeAddressRow>();

        if(contact != null){

            if(String.isNotBlank(contact.Office_Address__Street__s)){
                rows.add(
                    new OfficeAddressRow(
                        'Street',
                        contact.Office_Address__Street__s
                    )
                );
            }

            if(String.isNotBlank(contact.Office_Address__City__s)){
                rows.add(
                    new OfficeAddressRow(
                        'City',
                        contact.Office_Address__City__s
                    )
                );
            }

            // Office_Address__State__s does not exist as a queryable field on
            // this org's Contact object — only the ISO-code variant
            // (Office_Address__StateCode__s) was generated. Resolve the code
            // to its display label via picklist metadata instead, so the PDF
            // matches what the edit form's dropdown shows (e.g. "Balkh"
            // instead of "BAL").
            if(String.isNotBlank(contact.Office_Address__StateCode__s)){
                rows.add(
                    new OfficeAddressRow(
                        'State/Province',
                        getPicklistLabelFromCode(
                            'Contact',
                            'Office_Address__StateCode__s',
                            contact.Office_Address__StateCode__s
                        )
                    )
                );
            }

            if(String.isNotBlank(contact.Office_Address__PostalCode__s)){
                rows.add(
                    new OfficeAddressRow(
                        'ZIP/Postal Code',
                        contact.Office_Address__PostalCode__s
                    )
                );
            }

            // Same rationale as State above: resolve the country code
            // (e.g. "AF") to its display label (e.g. "Afghanistan").
            if(String.isNotBlank(contact.Office_Address__CountryCode__s)){
                rows.add(
                    new OfficeAddressRow(
                        'Country',
                        getPicklistLabelFromCode(
                            'Contact',
                            'Office_Address__CountryCode__s',
                            contact.Office_Address__CountryCode__s
                        )
                    )
                );
            }
        }

        return rows;
    }

    public class NotesRow {
        public String label {get;set;}
        public String value {get;set;}

        public NotesRow(String label, String value){
            this.label = label;
            this.value = value;
        }
    }

    public List<NotesRow> getNotesRows() {

        List<NotesRow> rows = new List<NotesRow>();

        if(contact != null){

            if(String.isNotBlank(contact.Notes__c))
                rows.add(
                    new NotesRow(
                        'PA Notes',
                        contact.Notes__c
                    )
                );

            if(String.isNotBlank(contact.CRM_Notes__c))
                rows.add(
                    new NotesRow(
                        'CRM Notes',
                        contact.CRM_Notes__c
                    )
                );
        }

        return rows;
    }

    public class ContactInfoRow {
        public String label {get;set;}
        public String value {get;set;}

        public ContactInfoRow(String label, String value){
            this.label = label;
            this.value = value;
        }
    }

    public List<ContactInfoRow> getContactInfoRows() {

        List<ContactInfoRow> rows = new List<ContactInfoRow>();

        if(contact != null){

            if(String.isNotBlank(contact.MobilePhone))
                rows.add(
                    new ContactInfoRow(
                        'Mobile Phone No',
                        contact.MobilePhone
                    )
                );

            if(String.isNotBlank(contact.Phone))
                rows.add(
                    new ContactInfoRow(
                        'Office Phone No',
                        contact.Phone
                    )
                );

            if(String.isNotBlank(contact.Email))
                rows.add(
                    new ContactInfoRow(
                        'Email 1',
                        contact.Email
                    )
                );

            if(String.isNotBlank(contact.Email_2__c))
                rows.add(
                    new ContactInfoRow(
                        'Email 2',
                        contact.Email_2__c
                    )
                );

            if(String.isNotBlank(contact.Private_Email__c))
                rows.add(
                    new ContactInfoRow(
                        'Email 3',
                        contact.Private_Email__c
                    )
                );

            if(String.isNotBlank(contact.Email_Office__c))
                rows.add(
                    new ContactInfoRow(
                        'Email 4',
                        contact.Email_Office__c
                    )
                );
            if(String.isNotBlank(contact.Email_5__c))
                rows.add(
                    new ContactInfoRow(
                        'Email 5',
                        contact.Email_5__c
                    )
                );

            if(String.isNotBlank(contact.Email_6__c))
                rows.add(
                    new ContactInfoRow(
                        'Email 6',
                        contact.Email_6__c
                    )
                );
        }

        return rows;
    }

    public class DeletionRow {
        public String label {get;set;}
        public String value {get;set;}

        public DeletionRow(String label, String value){
            this.label = label;
            this.value = value;
        }
    }

 

    // ── HE Request rows (Name, Status, Feedback) ───────────────────────────────
    public class HERequestRow {
        public String name {get;set;}
        public String status {get;set;}
        public String feedback {get;set;}

        public HERequestRow(String name, String status, String feedback){
            this.name = name;
            this.status = status;
            this.feedback = feedback;
        }
    }

    public List<HERequestRow> getHERequestRows() {

        List<HERequestRow> rows = new List<HERequestRow>();

        if (herequests == null) return rows;

        for (HE_Request__c hr : herequests) {
            rows.add(
                new HERequestRow(
                    hr.Name,
                    hr.HE_Request_Status__c,
                    hr.Feedback__c
                )
            );
        }

        return rows;
    }

    // ── Session Attendance rows ─────────────────────────────────────────────────
    public class SessionAttendanceRow {
        public String eventName {get;set;}
        public String subEventName {get;set;}
        public String attended {get;set;}
        public String registered {get;set;}

        public SessionAttendanceRow(String eventName, String subEventName, Boolean attended, Boolean registered){
            this.eventName = eventName;
            this.subEventName = subEventName;
            this.attended = boolToYesNo(attended);
            this.registered = boolToYesNo(registered);
        }

        private String boolToYesNo(Boolean value) {
            return (value == true) ? 'Yes' : 'No';
        }
    }

    public List<SessionAttendanceRow> getSessionAttendanceRows() {

        List<SessionAttendanceRow> rows = new List<SessionAttendanceRow>();

        if (sessionAttendances == null) return rows;

        for (Session_Attendance__c sa : sessionAttendances) {
            rows.add(
                new SessionAttendanceRow(
                    sa.Event_Name__c,
                    sa.Sub_Event_Name__c,
                    sa.Attended__c,
                    sa.Registered__c
                )
            );
        }

        return rows;
    }


    private void fetchContactDetails(String contactId) {
        try {
            contact = [
                SELECT Id, Name, Title, Phone, Email, Email_Office__c, MobilePhone, Email_2__c,
                       Company_Affiliated__r.Name, Contact__c, Contact__r.Name, Admin_Phone__c, Admin_Email__c,
                       Professional_Personal_Backgrounds__c, Admin_Name__c,Office_Address__c,
                       Instagram_Handle__c, Social_Media_Insta__c, Social_Media_Twitter__c,
                       LinkedIn__c, Tiktok__c, Facebook__c, Snap__c, Website1__c, AccountId,
                       Marital_Status__c, Spouse_Name__r.Name, Area_of_Interests__c, Area_O_I__c,
                       Connection__r.Name, CONNECTION_NOTES__c, Category__c, Sector__c,
                       RecordTypeId, RecordType.Name, Deceased__c, Region__c, Website2__c,
                       Contact_Type__c, Edit__c, Protocol_tier__c, Birthdate, Interest__c, Alias__c,Office_Address__Street__s,
                       Office_Address__PostalCode__s,Office_Address__City__s,Office_Address__StateCode__s,Office_Address__CountryCode__s,
                       Escort__c, Deletion_Requested__c, Deletion_Reason__c, Approval_Status__c,
                       Nationality__c, Deletion_Status__c, Deletion_Status_1__c, OtherAddress, OtherStreet,Approver_Comments__c,Approver_Comments_2__c,
                       OtherCity, OtherState, OtherPostalCode, OtherCountry,
                       Company_Affiliated_1__r.Name, Company_Affiliated_2__r.Name,
                       Private_Email__c,Email_5__c,Email_6__c,
                       Job_Title_1__c, Job_Title_2__c, Job_Title_3__c,
                       Company_Affiliated_3__r.Name, Residing_City__c, Residing_Country__c,
                       MailingAddress, MailingStreet, MailingCity, MailingState,CRM_Notes__c,
                       MailingPostalCode, MailingCountry, Primary_Street__c, City__c,
                       Primary_State_Province__c, Primary_Country__c, Primary_ZipPostal_Code__c,
                       Deceased_Date__c, Sympathy_Message_Sent__c, Deceased_Message__c,
                       MUSEUMS__c, BUSINESS__c, EDUCATION__c, POLITICS__c,
                       PRIVATE_FAMILY__c, MEDIA_MARKETING__c,
                       Dietary_Restrictions__c, Allergies__c, Notes__c
                FROM Contact
                WHERE Id = :contactId
                LIMIT 1
            ];
        } catch (Exception e) {
            contact = null;
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Error fetching contact details: ' + e.getMessage()
            ));
        }
    }

    private void fetchProfilePicture(String contactId) {
        try {
            List<Attachment> attachments = [
                SELECT Id, Name, LastModifiedDate, ContentType
                FROM Attachment
                WHERE ParentId = :contactId
                AND ContentType IN ('image/png', 'image/jpeg', 'image/gif')
                ORDER BY LastModifiedDate DESC
                LIMIT 1
            ];
            if (!attachments.isEmpty()) {
                profilePictureUrl = '/servlet/servlet.FileDownload?file=' + attachments[0].Id;
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.WARNING,
                'Profile picture not available: ' + e.getMessage()
            ));
        }
    }

    private void fetchGuestList(String contactId) {
        try {
            guestList = [
                SELECT Id, Name, Date__c, Contact__c, Invitation__r.Name, RSVP__c, Attended__c
                FROM Guest_List__c
                WHERE Contact__c = :contactId
            ];
        } catch (Exception e) {
            guestList = new List<Guest_List__c>();
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Error retrieving guest list: ' + e.getMessage()
            ));
        }
    }

 private void fetchVisitsToDoha(String contactId) {
    try {
        visitsToDoha = [
            SELECT Id, Name, Start_date__c, End_date__c,
                   Purpose_of_visit__c, Accompanied_by__c,HE_Notes__c
            FROM Visit_to_Doha__c
            WHERE Contact__c = :contactId
        ];
    } catch (Exception e) {
        visitsToDoha = new List<Visit_to_Doha__c>();
        ApexPages.addMessage(new ApexPages.Message(
            ApexPages.Severity.ERROR,
            'Error retrieving visits: ' + e.getMessage()
        ));
    }
}
// Generic Date -> "MM/dd/yyyy" formatter, mirrors deceasedDateFormatted's
// approach: Date has no format(String) overload (only Datetime does), so
// build the string manually for a fixed, locale-independent format.
private String formatDate(Date d) {
    if (d == null) {
        return null;
    }
    String mm = String.valueOf(d.month()).leftPad(2, '0');
    String dd = String.valueOf(d.day()).leftPad(2, '0');
    String yyyy = String.valueOf(d.year());
    return mm + '/' + dd + '/' + yyyy;
}

    private void fetchherequest(String contactId) {
        try {
            herequests = [
                SELECT Id, Name, Guest_Name__c, HE_Request_Status__c, Feedback__c
                FROM HE_Request__c
                WHERE Guest_Name__c = :contactId
            ];
        } catch (Exception e) {
            herequests = new List<HE_Request__c>();
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Error retrieving HE requests: ' + e.getMessage()
            ));
        }
    }

    private void fetchildren(String contactId) {
        try {
            Children = [
                SELECT Id, Name, Contact__c, Age__c
                FROM Children__c
                WHERE Contact__c = :contactId
            ];
        } catch (Exception e) {
            Children = new List<Children__c>();
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Error retrieving children: ' + e.getMessage()
            ));
        }
    }

    private void fetcmeetingandnotes(String contactId) {
        try {
            Meetingandnotes = [
                SELECT Id, Name, Contact__c, Title__c, Date__c
                FROM Meeting_Notes__c
                WHERE Contact__c = :contactId
            ];
        } catch (Exception e) {
            Meetingandnotes = new List<Meeting_Notes__c>();
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Error retrieving meeting notes: ' + e.getMessage()
            ));
        }
    }

    private void fetchGifts(String contactId) {
    try {
        gifts = [
            SELECT Id, Name, RecordType.Name, Occasion_Purpose_Other__c,
                   Date_of_Exchange__c, Gift_Description__c
            FROM Gift_and_Donation__c
            WHERE Person_Accounts__c = :contactId
        ];
    } catch (Exception e) {
        gifts = new List<Gift_and_Donation__c>();
        ApexPages.addMessage(new ApexPages.Message(
            ApexPages.Severity.ERROR,
            'Error retrieving gifts: ' + e.getMessage()
        ));
    }
}

// ── Visit to Doha rows (Start Date, End Date, Purpose, Accompanied By, Notes) ──
public class VisitRow {
    public String name {get;set;}
    public String startDate {get;set;}
    public String endDate {get;set;}
    public String purposeOfVisit {get;set;}
    public String accompaniedBy {get;set;}
    public String heNotes {get;set;}

    public VisitRow(String name, String startDate, String endDate,
                     String purposeOfVisit, String accompaniedBy, String heNotes){
        this.name = name;
        this.startDate = startDate;
        this.endDate = endDate;
        this.purposeOfVisit = purposeOfVisit;
        this.accompaniedBy = accompaniedBy;
        this.heNotes = heNotes;
    }
}

public List<VisitRow> getVisitToDohaRows() {

    List<VisitRow> rows = new List<VisitRow>();

    if (visitsToDoha == null) return rows;

    for (Visit_to_Doha__c v : visitsToDoha) {
        rows.add(
            new VisitRow(
                v.Name,
                formatDate(v.Start_date__c),
                formatDate(v.End_date__c),
                v.Purpose_of_visit__c,
                v.Accompanied_by__c,
                stripHtmlAndEntities(v.HE_Notes__c)   // ✅ strips <p>, </p>, and other HTML tags/entities
            )
        );
    }

    return rows;
}

public class GiftRow {
    public String name {get;set;}
    public String recordTypeName {get;set;}
    public String dateOfExchange {get;set;}
    public String giftDescription {get;set;}

    public GiftRow(String name, String recordTypeName, String dateOfExchange, String giftDescription){
        this.name = name;
        this.recordTypeName = recordTypeName;
        this.dateOfExchange = dateOfExchange;
        this.giftDescription = giftDescription;
    }
}

public List<GiftRow> getGiftRows() {

    List<GiftRow> rows = new List<GiftRow>();

    if (gifts == null) return rows;

    for (Gift_and_Donation__c g : gifts) {
        rows.add(
            new GiftRow(
                g.Name,
                (g.RecordType != null) ? g.RecordType.Name : null,
                formatDate(g.Date_of_Exchange__c),
                g.Gift_Description__c
            )
        );
    }

    return rows;
}

    private void fetchSessionAttendances(String contactId) {
        try {
            sessionAttendances = [
                SELECT Id, Name, Contact__c, Event_Name__c, Sub_Event_Name__c, Attended__c, Registered__c
                FROM Session_Attendance__c
                WHERE Contact__c = :contactId
            ];
        } catch (Exception e) {
            sessionAttendances = new List<Session_Attendance__c>();
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Error retrieving session attendance: ' + e.getMessage()
            ));
        }
    }

    private String stripHtmlAndEntities(String html) {
        if (String.isBlank(html)) return '';
        String text = html.replaceAll('<[^>]+>', '');
        Map<String, String> entities = new Map<String, String>{
            '&#39;'  => '\'',
            '&quot;' => '"',
            '&amp;'  => '&',
            '&lt;'   => '<',
            '&gt;'   => '>',
            '&nbsp;' => ' '
        };
        for (String entity : entities.keySet()) {
            text = text.replaceAll(entity, entities.get(entity));
        }
        return text;
    }

    public static void generateAndSavePdf(Id contactId) {
        if (contactId == null) throw new AuraHandledException('Contact Id is required.');

        Blob pdfBlob = Blob.valueOf('Test PDF content');
        ContentVersion cv = new ContentVersion();
        cv.Title = 'TestFile.pdf';
        cv.PathOnClient = 'TestFile.pdf';
        cv.VersionData = pdfBlob;
        cv.IsMajorVersion = true;
        cv.Origin = 'H';
        insert cv;

        // Requery defensively – never assume a single-row SOQL assignment
        // will succeed, even immediately after a successful insert.
        List<ContentVersion> cvList = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ];

        if (cvList.isEmpty() || cvList[0].ContentDocumentId == null) {
            throw new AuraHandledException(
                'Unable to retrieve the generated file (ContentVersion ' + cv.Id +
                '). It may be a sharing/visibility issue, or the ContentDocumentId ' +
                'was not populated yet.'
            );
        }

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cvList[0].ContentDocumentId;
        cdl.LinkedEntityId = contactId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
    }
}