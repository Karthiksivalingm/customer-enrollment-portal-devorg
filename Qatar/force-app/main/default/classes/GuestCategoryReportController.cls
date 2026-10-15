public with sharing class GuestCategoryReportController {

    // ---- Used by the selector component to populate both dropdowns ----
    @AuraEnabled(cacheable=true)
    public static List<String> getGuestTierValues() {
        return getPicklistValues(Guest_List__c.Guest_Tiers__c);
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getRegistrationStatusValues() {
        return getPicklistValues(Guest_List__c.RSVP__c);
    }

    // ---- Same idea, for the invitation-based report's selector ----
    @AuraEnabled(cacheable=true)
    public static List<String> getInvitationTierValues() {
        return getPicklistValues(Guest_List__c.Invitation_Tier__c);
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getInvitationStatusValues() {
        return getPicklistValues(Guest_List__c.Invitation_Status__c);
    }

    private static List<String> getPicklistValues(Schema.SObjectField field) {
        List<String> values = new List<String>();
        Schema.DescribeFieldResult fieldResult = field.getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (entry.isActive()) {
                values.add(entry.getValue());
            }
        }
        return values;
    }

    // ---- Main report query, filtered strictly to one event + one tier + one registration status ----
    // Photos are embedded as base64 data URIs (rather than a servlet.FileDownload URL) because
    // that URL points at the org's My Domain host, a different origin than the Lightning page
    // the LWC renders on. Browsers that block third-party cookies (Safari ITP, Chrome) won't
    // carry the session cookie cross-origin, so the image request gets redirected to a login
    // page instead of the file — showing as a broken image. Embedding avoids the extra request
    // entirely.
    // NOTE: previously this ran a static SOQL query with "Guest_Tiers__c = :guestTier
    // AND RSVP__c = :registrationStatus". Binding a null variable to "=" in SOQL doesn't
    // mean "skip this filter" — it actually matches records where the field IS null. So
    // when "Generate All" passed blank tier/status, this was literally returning only the
    // blank-tier/blank-status records. Switched to a dynamic query: a specific filter is
    // applied when given, and when it's left blank ("all"), blank-field records are
    // explicitly excluded instead of being the only thing matched.
    @AuraEnabled(cacheable=true)
    public static ReportWrapper getReport(Id eventId, String guestTier, String registrationStatus) {
        ReportWrapper wrapper = new ReportWrapper();

        Invitation__c evt = [
            SELECT Id, Name, Event_Start_Date__c, Event_End_Date__c
            FROM Invitation__c
            WHERE Id = :eventId
            LIMIT 1
        ];
        wrapper.eventName = evt.Name;
        wrapper.guestTier = guestTier;
        wrapper.registrationStatus = registrationStatus;
        wrapper.eventDate = formatDateRange(evt.Event_Start_Date__c, evt.Event_End_Date__c);

        List<Guest_List__c> guests = queryGuestsByRegistrationStatus(eventId, guestTier, registrationStatus);

        GuestRowsResult result = buildGuestRows(guests, true);
        wrapper.guests = result.rows;
        wrapper.photosOmittedDueToSize = result.photosOmittedDueToSize;
        return wrapper;
    }

    // ---- Same as getReport, but for the PDF controller: uses URL-based photoUrl
    //      (see UPDATE note on getReportByInvitationForPdf below — base64 was tried
    //      and conclusively does not render in this org's PDF engine). ----
    public static ReportWrapper getReportForPdf(Id eventId, String guestTier, String registrationStatus) {
        ReportWrapper wrapper = new ReportWrapper();

        Invitation__c evt = [
            SELECT Id, Name, Event_Start_Date__c, Event_End_Date__c
            FROM Invitation__c
            WHERE Id = :eventId
            LIMIT 1
        ];
        wrapper.eventName = evt.Name;
        wrapper.guestTier = guestTier;
        wrapper.registrationStatus = registrationStatus;
        wrapper.eventDate = formatDateRange(evt.Event_Start_Date__c, evt.Event_End_Date__c);

        List<Guest_List__c> guests = queryGuestsByRegistrationStatus(eventId, guestTier, registrationStatus);

        GuestRowsResult result = buildGuestRows(guests, false);
        wrapper.guests = result.rows;
        wrapper.photosOmittedDueToSize = result.photosOmittedDueToSize;
        return wrapper;
    }

    // ---- Same report, filtered by Invitation Tier + Invitation Status instead (used by the LWC) ----
    @AuraEnabled(cacheable=true)
    public static ReportWrapper getReportByInvitation(Id eventId, String guestTier, String invitationStatus) {
        ReportWrapper wrapper = new ReportWrapper();

        Invitation__c evt = [
            SELECT Id, Name, Event_Start_Date__c, Event_End_Date__c
            FROM Invitation__c
            WHERE Id = :eventId
            LIMIT 1
        ];
        wrapper.eventName = evt.Name;
        wrapper.guestTier = guestTier;
        wrapper.registrationStatus = invitationStatus; // wrapper field reused to carry invitation status for header display
        wrapper.eventDate = formatDateRange(evt.Event_Start_Date__c, evt.Event_End_Date__c);

        List<Guest_List__c> guests = queryGuestsByInvitation(eventId, guestTier, invitationStatus);
        GuestRowsResult result = buildGuestRows(guests, false);
        wrapper.guests = result.rows;
        wrapper.photosOmittedDueToSize = result.photosOmittedDueToSize;
        return wrapper;
    }

    // ---- Same as above but embeds guest photos as base64 data URIs instead of URLs.
    //      Used ONLY by the PDF controller: Visualforce's renderAs="pdf" engine cannot
    //      reliably fetch remote/session-authenticated image URLs at render time, so the
    //      photo bytes are embedded directly in the HTML instead of linked. ----
    public static ReportWrapper getReportByInvitationForPdf(Id eventId, String guestTier, String invitationStatus) {
        ReportWrapper wrapper = new ReportWrapper();

        Invitation__c evt = [
            SELECT Id, Name, Event_Start_Date__c, Event_End_Date__c
            FROM Invitation__c
            WHERE Id = :eventId
            LIMIT 1
        ];
        wrapper.eventName = evt.Name;
        wrapper.guestTier = guestTier;
        wrapper.registrationStatus = invitationStatus;
        wrapper.eventDate = formatDateRange(evt.Event_Start_Date__c, evt.Event_End_Date__c);

        List<Guest_List__c> guests = queryGuestsByInvitation(eventId, guestTier, invitationStatus);
        // NOTE (2026-08): base64 embedding was tried here and confirmed NOT to work —
        // a test PDF came back with every single photo broken (worse than the URL
        // approach below, which rendered at least some photos correctly). So base64
        // is conclusively out for this org's PDF engine. Back to URL-based, now using
        // a RELATIVE path (see buildGuestRows) instead of an absolute My Domain URL —
        // the previous absolute-URL version worked intermittently, which points at a
        // domain/session mismatch (VF pages can render on a different host than the
        // org's My Domain) rather than the URL approach being fundamentally broken.
        // If photos are still inconsistent after this, the next path is a Files
        // (ContentVersion) public/session-parameterized distribution URL instead of
        // the legacy Attachment servlet.
        GuestRowsResult result = buildGuestRows(guests, false);
        wrapper.guests = result.rows;
        wrapper.photosOmittedDueToSize = result.photosOmittedDueToSize;
        return wrapper;
    }

    // ---- Shared query builder for both the LWC and PDF report paths.
    //      guestTier / invitationStatus are only added as WHERE conditions when they
    //      actually have a value, since binding a null value directly would become
    //      "Field = NULL" in SOQL rather than "ignore this filter". ----
    private static List<Guest_List__c> queryGuestsByInvitation(Id eventId, String guestTier, String invitationStatus) {
        String query =
            'SELECT Id, Contact__c, Contact__r.Name, Source__c, RSVP__c, ' +
            'Title__c, Company__c, Job_Title__c, Bio__c, Reason_for_Inviting__c, ' +
            'Guest_Category__c, Guest_Tiers__c, ' +
            'Inbound_Date_Time__c, Outbound_Date_Time__c, ' +
            'X1_of_Invited_Guests__c, Relationship_to__c, Group_ID__c, ' +
            'Main_Guest__c, Main_Guest__r.Contact__r.Name, ' +
            'Invitation_Status__c, Invitation_Tier__c ' +
            'FROM Guest_List__c ' +
            'WHERE Invitation__c = :eventId';

        if (String.isNotBlank(guestTier)) {
            query += ' AND Guest_Tiers__c = :guestTier';
        } else {
            // "All Tiers" selected — still exclude records with no tier set, rather
            // than showing blank-tier rows alongside every real tier value.
            query += ' AND Guest_Tiers__c != null';
        }
        if (String.isNotBlank(invitationStatus)) {
            query += ' AND Invitation_Status__c = :invitationStatus';
        } else {
            // "All Statuses" selected — same idea, exclude blank-status records.
            query += ' AND Invitation_Status__c != null';
        }

        query += ' ORDER BY Contact__r.Name';

        return Database.query(query);
    }

    // ---- Same idea as queryGuestsByInvitation, but for the Guest_Tiers__c / RSVP__c
    //      pair used by getReport (the Guest Registration Report / "Generate All"
    //      screen). Same reasoning: a blank filter means "no filter for this field",
    //      which in SOQL requires explicitly excluding null rather than binding null
    //      into "= :var" (which would match only the null rows). ----
    private static List<Guest_List__c> queryGuestsByRegistrationStatus(Id eventId, String guestTier, String registrationStatus) {
        String query =
            'SELECT Id, Contact__c, Contact__r.Name, Source__c, RSVP__c, ' +
            'Title__c, Company__c, Job_Title__c, Bio__c, Reason_for_Inviting__c, ' +
            'Guest_Category__c, Guest_Tiers__c, ' +
            'Inbound_Date_Time__c, Outbound_Date_Time__c, ' +
            'X1_of_Invited_Guests__c, Relationship_to__c, Group_ID__c, ' +
            'Main_Guest__c, Main_Guest__r.Contact__r.Name, ' +
            'Invitation_Status__c, Invitation_Tier__c ' +
            'FROM Guest_List__c ' +
            'WHERE Invitation__c = :eventId';

        if (String.isNotBlank(guestTier)) {
            query += ' AND Guest_Tiers__c = :guestTier';
        } else {
            // "All Tiers" selected — exclude records with no tier set.
            query += ' AND Guest_Tiers__c != null';
        }
        if (String.isNotBlank(registrationStatus)) {
            query += ' AND RSVP__c = :registrationStatus';
        } else {
            // "All Statuses" selected — exclude records with no registration status set.
            query += ' AND RSVP__c != null';
        }

        query += ' ORDER BY Contact__r.Name';

        return Database.query(query);
    }

    // ---- PDF photo sizing ----
    // The URL-based photo path (used by the PDF controller) links straight to the
    // ORIGINAL Attachment via servlet.FileDownload — there's no Salesforce-generated
    // thumbnail for Attachments the way there is for Files/ContentVersion, so the PDF
    // renderer downloads and embeds the full-resolution image for every guest that has
    // one. With a fixed size cap that's still unbounded as the guest count (n) grows:
    // e.g. a 195KB-per-photo cap still adds up to ~95MB at 500 guests. Instead, the
    // per-photo byte cap is computed from the guest count so the TOTAL photo weight in
    // the PDF stays roughly within budget no matter how large n is. Guests whose photo
    // doesn't fit the budget simply render without a photo — the VF page already
    // handles that (NOT(ISBLANK(g.photoUrl))) — rather than failing the whole report.
    private static final Integer PDF_PHOTO_TOTAL_BUDGET_BYTES = 15000000; // ~15MB of the 30MB ceiling reserved for photos
    private static final Integer PDF_PHOTO_MIN_BYTES = 15000;             // always allow at least a small headshot through
    private static final Integer PDF_PHOTO_MAX_BYTES = 200000;            // don't need more than this even for a tiny guest list

    private static Integer calculatePdfPhotoByteBudget(Integer distinctContactCount) {
        if (distinctContactCount == null || distinctContactCount <= 0) {
            return PDF_PHOTO_MAX_BYTES;
        }
        Integer perPhoto = PDF_PHOTO_TOTAL_BUDGET_BYTES / distinctContactCount;
        return Math.max(PDF_PHOTO_MIN_BYTES, Math.min(PDF_PHOTO_MAX_BYTES, perPhoto));
    }

    // Checks the attachment's actual byte signature ("magic bytes") rather than
    // trusting its stored ContentType — a corrupted upload or placeholder stub can
    // still be labeled image/jpeg, and would render as a broken image no matter how
    // it's embedded. An attachment that fails this check is treated as if the guest
    // has no photo at all, rather than being included and breaking in the PDF.
    private static Boolean isValidImage(Blob body, String contentType) {
        if (body == null || body.size() < 8) {
            return false;
        }
        String hex = EncodingUtil.convertToHex(body).toUpperCase();
        if (hex.startsWith('FFD8FF')) {
            // A genuinely valid JPEG can still be unrenderable in this PDF engine —
            // see isProgressiveJpeg below.
            return !isProgressiveJpeg(hex);
        }
        if (hex.startsWith('89504E470D0A1A0A')) {
            return true; // PNG
        }
        if (hex.startsWith('474946383761') || hex.startsWith('474946383961')) {
            return true; // GIF87a / GIF89a
        }
        if (String.isNotBlank(contentType) && contentType.equalsIgnoreCase('image/svg+xml')) {
            String prefix = body.toString().trim().toLowerCase();
            return prefix.startsWith('<?xml') || prefix.startsWith('<svg');
        }
        return false;
    }

    // The Visualforce PDF engine here (iText 2.0.8, ~2008) reliably fails to decode
    // progressive-encoded JPEGs — a very common output of phone cameras and modern
    // export/resize tools — even though the file itself is perfectly valid. That's
    // the leading explanation for a guest whose photo passes the magic-byte check
    // above but still renders as a broken image: it's a real photo, just encoded in
    // a way this old renderer can't handle. Walks the JPEG's marker segments looking
    // for the Start-Of-Frame marker: SOF0/SOF1 (0xFFC0/0xFFC1) is baseline — safe.
    // SOF2 (0xFFC2) is progressive, and other SOF variants (0xFFC3, 0xFFC5-0xFFC7,
    // 0xFFC9-0xFFCF) are rarer encodings this renderer is equally unlikely to
    // support — all treated as unsafe.
    private static Boolean isProgressiveJpeg(String hex) {
        Integer byteLen = hex.length() / 2;
        Integer i = 2; // skip the SOI marker (FFD8), already confirmed by the caller
        while (i + 1 < byteLen) {
            if (hex.substring(i * 2, i * 2 + 2) != 'FF') {
                i++;
                continue; // resync — shouldn't normally happen in a well-formed JPEG
            }
            String marker = hex.substring((i + 1) * 2, (i + 1) * 2 + 2);
            i += 2;

            if (marker == 'D8' || marker == '01' || (marker >= 'D0' && marker <= 'D9')) {
                // Markers with no length field (SOI/TEM/RSTn); D9 is EOI — stop.
                if (marker == 'D9') {
                    return false;
                }
                continue;
            }
            if (i + 1 >= byteLen) {
                return false; // truncated — let the magic-byte check's caller have already handled corruption
            }

            Integer segLen = hexToInt(hex.substring(i * 2, i * 2 + 4));

            if (marker == 'C0' || marker == 'C1') {
                return false; // baseline / extended sequential baseline — safe
            }
            if (marker == 'C2' || marker == 'C3'
                || (marker >= 'C5' && marker <= 'C7')
                || (marker >= 'C9' && marker <= 'CF')) {
                return true; // progressive or other non-baseline SOF — treat as unsafe
            }
            if (marker == 'DA' || segLen == null || segLen < 2) {
                return false; // reached image data without finding a SOF marker — give up safely
            }
            i += segLen;
        }
        return false;
    }

    // Apex's Integer.valueOf has no radix/hex overload, so this converts a hex
    // string (as produced by EncodingUtil.convertToHex, uppercase) to its integer
    // value one nibble at a time.
    private static Integer hexToInt(String hexStr) {
        String digits = '0123456789ABCDEF';
        Integer result = 0;
        for (Integer idx = 0; idx < hexStr.length(); idx++) {
            result = (result * 16) + digits.indexOf(hexStr.substring(idx, idx + 1));
        }
        return result;
    }

    // Small holder so buildGuestRows can report back whether any guest's photo was
    // left out of the PDF because it didn't fit the size budget, alongside the rows
    // themselves — callers (PDF paths) surface this via ReportWrapper.photosOmittedDueToSize.
    private class GuestRowsResult {
        List<GuestRow> rows;
        Boolean photosOmittedDueToSize;
        GuestRowsResult(List<GuestRow> rows, Boolean photosOmittedDueToSize) {
            this.rows = rows;
            this.photosOmittedDueToSize = photosOmittedDueToSize;
        }
    }

    // ---- Shared row-building logic (comments lookup + photo lookup) used by all report queries.
    //      embedPhotoAsBase64 = true  -> photoUrl holds a data:...;base64,... URI (for PDF rendering
    //                                     and for the category report LWC, which otherwise hits
    //                                     cross-origin cookie blocking on the FileDownload servlet URL)
    //      embedPhotoAsBase64 = false -> photoUrl holds an absolute download URL, size-capped
    //                                     dynamically (see calculatePdfPhotoByteBudget above) so the
    //                                     report scales to any number of guest records ----
    private static GuestRowsResult buildGuestRows(List<Guest_List__c> guests, Boolean embedPhotoAsBase64) {
        Set<Id> guestIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        for (Guest_List__c g : guests) {
            guestIds.add(g.Id);
            if (g.Contact__c != null) {
                contactIds.add(g.Contact__c);
            }
        }

        // First HE Request per guest (by creation order) supplies the Comments column
        Map<Id, String> guestToComment = new Map<Id, String>();
        if (!guestIds.isEmpty()) {
            for (HE_Request__c req : [
                SELECT Id, Name, Guest_List__c
                FROM HE_Request__c
                WHERE Guest_List__c IN :guestIds
                ORDER BY CreatedDate ASC
            ]) {
                if (!guestToComment.containsKey(req.Guest_List__c)) {
                    guestToComment.put(req.Guest_List__c, req.Name);
                }
            }
        }

        // Guest photo — same source as the related-list table: the most recent image
        // Attachment on the related Contact record.
        Map<Id, String> photoMap = new Map<Id, String>();
        Boolean photosOmittedDueToSize = false;
        if (!contactIds.isEmpty()) {
            // Lightweight pass (no Body field, so no heap cost) just to know which
            // contacts have a qualifying photo attachment at all. Compared against
            // photoMap afterward to detect "had a photo, but it didn't fit the size
            // budget" so the PDF can surface that instead of silently showing nothing.
            Set<Id> parentsWithAnyPhotoAttachment = new Set<Id>();
            for (Attachment att : [
                SELECT ParentId
                FROM Attachment
                WHERE ParentId IN :contactIds
                AND ContentType IN ('image/jpeg','image/jpg','image/png','image/gif','image/svg+xml')
            ]) {
                parentsWithAnyPhotoAttachment.add(att.ParentId);
            }

            if (embedPhotoAsBase64) {
                // NOTE: confirmed NOT to render in this org's PDF engine — a generated
                // PDF using this branch came back with every photo broken. Kept only
                // for the on-screen LWC path (getReport), which still needs base64 to
                // dodge the browser's cross-origin cookie blocking on the FileDownload
                // URL. Do not switch a PDF-facing method to this branch.
                Integer photoByteBudget = calculatePdfPhotoByteBudget(contactIds.size());
                try {
                    for (Attachment att : [
                        SELECT Id, ParentId, ContentType, BodyLength, Body
                        FROM Attachment
                        WHERE ParentId IN :contactIds
                        AND ContentType IN ('image/jpeg','image/jpg','image/png','image/gif','image/svg+xml')
                        AND BodyLength < :photoByteBudget
                        ORDER BY CreatedDate DESC
                    ]) {
                        if (!photoMap.containsKey(att.ParentId) && isValidImage(att.Body, att.ContentType)) {
                            String base64Data = EncodingUtil.base64Encode(att.Body);
                            photoMap.put(att.ParentId, 'data:' + att.ContentType + ';base64,' + base64Data);
                        }
                    }
                } catch (Exception ex) {
                    // Degrade gracefully: report still generates, just without embedded photos.
                    photoMap.clear();
                }
            } else {
                // Dynamic cap: as the guest/contact count grows, the allowed per-photo
                // size shrinks, keeping total embedded photo weight roughly constant
                // regardless of how many records (n) are in the report.
                //
                // RELATIVE path, not an absolute My Domain URL: Visualforce pages can be
                // served from a different host than the org's My Domain (the Enhanced
                // Domains VF host, e.g. *.vf.force.com, vs. the My Domain login host that
                // URL.getOrgDomainUrl() returns). An absolute cross-host URL is a plausible
                // reason the PDF's image fetch worked for some guests and not others — a
                // relative path always resolves against whatever host actually served the
                // page, so there's no host mismatch for the renderer's fetch to trip over.
                //
                // NOTE (2026-08): the URL/domain theory turned out not to be the (whole)
                // story — the exact same single guest's photo rendered correctly across
                // three different attempts (absolute URL, base64, relative URL), while
                // every other guest broke every time. That's the signature of bad source
                // data, not a flaky fetch: most "photo" attachments are labeled image/jpeg
                // etc but aren't actually valid, decodable image bytes (corrupted upload,
                // placeholder stub, etc). Now validating the real byte signature (magic
                // bytes) of each attachment before including it — an attachment that fails
                // this check would never render correctly no matter how it's embedded, so
                // it's treated the same as "no photo" instead of producing a broken icon.
                Integer photoByteBudget = calculatePdfPhotoByteBudget(contactIds.size());

                for (Attachment att : [
                    SELECT Id, ParentId, ContentType, Body
                    FROM Attachment
                    WHERE ParentId IN :contactIds
                    AND ContentType IN ('image/jpeg','image/jpg','image/png','image/gif','image/svg+xml')
                    AND BodyLength < :photoByteBudget
                    ORDER BY CreatedDate DESC
                ]) {
                    if (!photoMap.containsKey(att.ParentId) && isValidImage(att.Body, att.ContentType)) {
                        photoMap.put(att.ParentId, '/servlet/servlet.FileDownload?file=' + att.Id);
                    }
                }
            }

            // A contact has a real photo on file, but none of their attachments made
            // it under the size budget — that's a true omission, distinct from a
            // contact simply having no photo at all.
            for (Id parentId : parentsWithAnyPhotoAttachment) {
                if (!photoMap.containsKey(parentId)) {
                    photosOmittedDueToSize = true;
                    break;
                }
            }
        }

        List<GuestRow> rows = new List<GuestRow>();
        for (Guest_List__c g : guests) {
            GuestRow row = new GuestRow();
            row.fullName = g.Contact__r != null ? g.Contact__r.Name : '';
            row.photoUrl = (g.Contact__c != null && photoMap.containsKey(g.Contact__c)) ? photoMap.get(g.Contact__c) : '';
            row.source = g.Source__c;
            row.registrationStatus = g.RSVP__c;
            row.title = g.Title__c;
            row.company = g.Company__c;
            row.jobTitle = g.Job_Title__c;
            row.bio = g.Bio__c;
            row.reasonForAttendance = g.Reason_for_Inviting__c;
            row.guestCategory = g.Guest_Category__c;
            row.tier = g.Guest_Tiers__c;
            row.inboundDate = g.Inbound_Date_Time__c != null ? g.Inbound_Date_Time__c.date().format() : '';
            row.inboundTime = g.Inbound_Date_Time__c != null ? formatTime(g.Inbound_Date_Time__c) : '';
            row.outboundDate = g.Outbound_Date_Time__c != null ? g.Outbound_Date_Time__c.date().format() : '';
            row.outboundTime = g.Outbound_Date_Time__c != null ? formatTime(g.Outbound_Date_Time__c) : '';
            row.accompanyingGuest = g.X1_of_Invited_Guests__c;
            row.relationshipTo = g.Relationship_to__c;
            row.groupId = g.Group_ID__c;
            row.comments = guestToComment.get(g.Id);
            row.mainGuestFullName = (g.Main_Guest__c != null && g.Main_Guest__r.Contact__r != null)
                ? g.Main_Guest__r.Contact__r.Name
                : '';
            row.invitationStatus = g.Invitation_Status__c;
            row.invitationTier = g.Invitation_Tier__c;
            rows.add(row);
        }
        return new GuestRowsResult(rows, photosOmittedDueToSize);
    }

    private static String formatTime(Datetime dt) {
        return dt.format('hh:mm a');
    }

    private static String formatDateRange(Date startDate, Date endDate) {
        if (startDate == null) {
            return '';
        }
        if (endDate == null || endDate == startDate) {
            return startDate.format();
        }
        return startDate.format() + ' - ' + endDate.format();
    }

    public class ReportWrapper {
        @AuraEnabled public String eventName;
        @AuraEnabled public String guestTier;
        @AuraEnabled public String registrationStatus;
        @AuraEnabled public String eventDate;
        @AuraEnabled public List<GuestRow> guests = new List<GuestRow>();
        @AuraEnabled public Boolean photosOmittedDueToSize = false;
    }

    public class GuestRow {
        @AuraEnabled public String fullName;
        @AuraEnabled public String photoUrl;
        @AuraEnabled public String source;
        @AuraEnabled public String registrationStatus;
        @AuraEnabled public String title;
        @AuraEnabled public String company;
        @AuraEnabled public String jobTitle;
        @AuraEnabled public String bio;
        @AuraEnabled public String reasonForAttendance;
        @AuraEnabled public String guestCategory;
        @AuraEnabled public String tier;
        @AuraEnabled public String inboundDate;
        @AuraEnabled public String inboundTime;
        @AuraEnabled public String outboundDate;
        @AuraEnabled public String outboundTime;
        @AuraEnabled public String accompanyingGuest;
        @AuraEnabled public String relationshipTo;
        @AuraEnabled public String groupId;
        @AuraEnabled public String comments;
        @AuraEnabled public String mainGuestFullName;
        @AuraEnabled public String invitationStatus;
        @AuraEnabled public String invitationTier;
    }

}