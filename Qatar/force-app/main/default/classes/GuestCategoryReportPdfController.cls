public with sharing class GuestCategoryReportPdfController {
    public PdfReport report { get; private set; }
    public String errorMessage { get; private set; }

    private static final String ALL_SENTINEL = 'ALL';
    private static final Integer BIO_MAX_LENGTH = 450;
    private static final Integer SOFT_BREAK_CHUNK_SIZE = 10;

    // Same row-height-budget approach as GuestInvitationReportPdfController (ported
    // over 2026-08 — this report has the same narrow Reason of Attendance column and
    // was at real risk of the same issue: a long value there driving a single row's
    // real height far past what a Bio-only estimate would predict, and either getting
    // silently clipped or blowing out a page uncounted).
    //
    // CORRECTED 2026-08: the first calibration (13 / 6 chars-per-line) was derived by
    // extrapolating from the Invitation report's constants using column-width ratio
    // alone, without checking the implied character width. It worked out to ~9.8pt
    // per character at a 7.5pt font — nowhere close to a real average (~3.5-4pt/char)
    // — so it predicted 2-3x more wrapped lines than actually render. That made almost
    // every row's estimated height exceed the whole page budget by itself, forcing a
    // page break before nearly every guest (90 pages, one row per page, huge blank
    // space below each). Recalculated from actual column width in points, font size,
    // and cell padding — see the values below.
    private static final Decimal LINE_HEIGHT_PT = 9.75;
    private static final Decimal CELL_VERTICAL_PADDING_PT = 6;
    private static final Decimal BIO_CHARS_PER_LINE = 30;    // calibrated for the ~16% (~127pt) Guest Bio column
    private static final Decimal REASON_CHARS_PER_LINE = 12; // calibrated for the ~7% (~56pt) Reason of Attendance column
    private static final Integer BASELINE_ROW_LINES = 3;
    private static final Decimal FIRST_PAGE_BUDGET_PT = 460;
    private static final Decimal OTHER_PAGE_BUDGET_PT = 500;

    public GuestCategoryReportPdfController() {
        Map<String, String> params = ApexPages.currentPage().getParameters();
        try {
            Id eventId = (Id) params.get('eventId');
            String tier = normalizeFilter(params.get('tier'));
            String status = normalizeFilter(params.get('status'));
            GuestCategoryReportController.ReportWrapper source =
                GuestCategoryReportController.getReportForPdf(eventId, tier, status);
            report = new PdfReport(source);
        } catch (Exception e) {
            errorMessage = 'Unable to load report: ' + e.getMessage();
        }
    }

    // ---- Called imperatively by the LWC's Download PDF button (same pattern as
    //      GuestInvitationReportPdfController.getPdfBase64) so the button's spinner
    //      covers real PDF generation time instead of clearing the instant a URL is
    //      built. ----
    @AuraEnabled
    public static String getPdfBase64(Id eventId, String tier, String status) {
        PageReference pdfPage = Page.GuestCategoryReportPdf;
        pdfPage.getParameters().put('eventId', eventId);
        pdfPage.getParameters().put('tier', String.isBlank(tier) ? ALL_SENTINEL : tier);
        pdfPage.getParameters().put('status', String.isBlank(status) ? ALL_SENTINEL : status);

        Blob pdfBlob;
        if (Test.isRunningTest()) {
            pdfBlob = Blob.valueOf('Test PDF content');
        } else {
            pdfBlob = pdfPage.getContentAsPDF();
        }
        return EncodingUtil.base64Encode(pdfBlob);
    }

    // The "Generate All" / "All Tiers" / "All Statuses" selections come through as the
    // literal string "ALL" rather than a blank value. Left unnormalized, that string gets
    // bound straight into the SOQL filter (e.g. "Guest_Tiers__c = 'ALL'"), which matches
    // zero real records instead of skipping the filter. Same fix already applied on
    // GuestInvitationReportPdfController — convert the sentinel (and any other blank
    // value) to null so queryGuestsByRegistrationStatus treats it as "no filter".
    private static String normalizeFilter(String value) {
        if (String.isBlank(value) || value.equalsIgnoreCase(ALL_SENTINEL)) {
            return null;
        }
        return value;
    }

    // Strips HTML tags (e.g. from HYPERLINK() formula fields or rich text fields)
    // and decodes common entities, so the PDF renderer never sees markup as plain text
    // and never has to wrap an un-breakable token like a URL.
    // Must live on the OUTER class — Apex doesn't allow static methods on inner classes.
    private static String stripHtml(String input) {
        if (String.isBlank(input)) {
            return input;
        }
        String cleaned = input.replaceAll('<[^>]+>', '');
        cleaned = cleaned.replaceAll('&nbsp;', ' ')
                          .replaceAll('&amp;', '&')
                          .replaceAll('&lt;', '<')
                          .replaceAll('&gt;', '>')
                          .trim();
        return cleaned;
    }

    // Truncates at the last complete sentence within the limit so a long bio doesn't
    // make a single row tall enough to need its own page. Falls back to the last full
    // word if no sentence-ending punctuation falls in the back half of the limit, so
    // it never cuts off mid-word either.
    private static String truncate(String input, Integer maxLength) {
        if (String.isBlank(input) || input.length() <= maxLength) {
            return input;
        }
        String snippet = input.substring(0, maxLength);

        Integer lastSentenceEnd = -1;
        for (String punct : new List<String>{ '.', '!', '?' }) {
            Integer idx = snippet.lastIndexOf(punct);
            if (idx > lastSentenceEnd) {
                lastSentenceEnd = idx;
            }
        }
        if (lastSentenceEnd > (maxLength / 2)) {
            return snippet.substring(0, lastSentenceEnd + 1).trim();
        }

        Integer lastSpace = snippet.lastIndexOf(' ');
        if (lastSpace > 0) {
            snippet = snippet.substring(0, lastSpace);
        }
        return snippet.trim() + '...';
    }

    // Ported from GuestInvitationReportPdfController — inserts a zero-width space every
    // SOFT_BREAK_CHUNK_SIZE characters inside any long unbroken "word", since this old
    // PDF renderer has unreliable CSS word-break support and a long unbroken token (an
    // all-caps org name, a concatenated value, etc.) can otherwise bleed into the
    // neighboring cell instead of wrapping.
    private static String insertSoftBreaks(String input) {
        if (String.isBlank(input)) {
            return input;
        }
        String zeroWidthSpace = '\u200B';
        List<String> words = input.split(' ', -1);
        List<String> processedWords = new List<String>();
        for (String word : words) {
            if (word.length() <= SOFT_BREAK_CHUNK_SIZE) {
                processedWords.add(word);
                continue;
            }
            List<String> chunks = new List<String>();
            Integer start = 0;
            while (start < word.length()) {
                Integer ends = Math.min(start + SOFT_BREAK_CHUNK_SIZE, word.length());
                chunks.add(word.substring(start, ends));
                start = ends;
            }
            processedWords.add(String.join(chunks, zeroWidthSpace));
        }
        return String.join(processedWords, ' ');
    }

    // Same estimate as GuestInvitationReportPdfController: takes whichever of Bio or
    // Reason of Attendance needs more wrapped lines, since either can be the tallest
    // part of the row.
    private static Decimal estimateRowHeightPt(String bioText, String reasonText) {
        Integer bioLen = String.isBlank(bioText) ? 0 : bioText.length();
        Integer reasonLen = String.isBlank(reasonText) ? 0 : reasonText.length();
        Integer bioLines = Math.max(1, Integer.valueOf(Math.ceil(bioLen / BIO_CHARS_PER_LINE)));
        Integer reasonLines = Math.max(1, Integer.valueOf(Math.ceil(reasonLen / REASON_CHARS_PER_LINE)));
        Integer lines = Math.max(Math.max(bioLines, reasonLines), BASELINE_ROW_LINES);
        return CELL_VERTICAL_PADDING_PT + (lines * LINE_HEIGHT_PT);
    }

    // VF-friendly wrapper: explicit properties, not plain fields.
    public class PdfReport {
        public String eventName { get; set; }
        public String guestTier { get; set; }
        public String registrationStatus { get; set; }
        public String eventDate { get; set; }
        public List<PdfGuestRow> guests { get; set; }
        public Boolean photosOmittedDueToSize { get; set; }
        public Integer guestCount { get; set; }

        public PdfReport(GuestCategoryReportController.ReportWrapper src) {
            this.eventName = src.eventName;
            this.guestTier = String.isBlank(src.guestTier) ? 'All Tiers' : src.guestTier;
            this.registrationStatus = String.isBlank(src.registrationStatus) ? 'All Statuses' : src.registrationStatus;
            this.eventDate = src.eventDate;
            this.photosOmittedDueToSize = src.photosOmittedDueToSize;
            this.guests = new List<PdfGuestRow>();
            this.guestCount = src.guests == null ? 0 : src.guests.size();

            Decimal pageBudgetRemaining = FIRST_PAGE_BUDGET_PT;
            Boolean isFirstRow = true;
            for (GuestCategoryReportController.GuestRow g : src.guests) {
                PdfGuestRow row = new PdfGuestRow(g);
                Decimal rowHeight = estimateRowHeightPt(row.bio, row.reasonForAttendance);
                if (!isFirstRow && rowHeight > pageBudgetRemaining) {
                    row.startsNewPage = true;
                    pageBudgetRemaining = OTHER_PAGE_BUDGET_PT - rowHeight;
                } else {
                    pageBudgetRemaining -= rowHeight;
                }
                isFirstRow = false;
                this.guests.add(row);
            }
        }
    }

    public class PdfGuestRow {
        public String fullName { get; set; }
        public String photoUrl { get; set; }
        public String source { get; set; }
        public String registrationStatus { get; set; }
        public String title { get; set; }
        public String company { get; set; }
        public String jobTitle { get; set; }
        public String bio { get; set; }
        public String reasonForAttendance { get; set; }
        public String guestCategory { get; set; }
        public String tier { get; set; }
        public String inboundDate { get; set; }
        public String inboundTime { get; set; }
        public String outboundDate { get; set; }
        public String outboundTime { get; set; }
        public String accompanyingGuest { get; set; }
        public String relationshipTo { get; set; }
        public String groupId { get; set; }
        public String comments { get; set; }
        public String mainGuestFullName { get; set; }
        public String invitationStatus { get; set; }
        public String invitationTier { get; set; }
        public String firstName { get; set; }
        public String lastName { get; set; }
        public String registeredAt { get; set; }
        public Boolean startsNewPage { get; set; }

        public PdfGuestRow(GuestCategoryReportController.GuestRow g) {
            this.startsNewPage         = false;
            this.fullName             = GuestCategoryReportPdfController.stripHtml(g.fullName);
            this.photoUrl              = g.photoUrl; // relative /servlet/servlet.FileDownload URL, or blank if omitted
            this.source                = insertSoftBreaks(GuestCategoryReportPdfController.stripHtml(g.source));
            this.registrationStatus    = GuestCategoryReportPdfController.stripHtml(g.registrationStatus);
            this.title                 = GuestCategoryReportPdfController.stripHtml(g.title);
            this.company               = insertSoftBreaks(GuestCategoryReportPdfController.stripHtml(g.company));
            this.jobTitle              = insertSoftBreaks(GuestCategoryReportPdfController.stripHtml(g.jobTitle));
            this.bio                   = truncate(GuestCategoryReportPdfController.stripHtml(g.bio), BIO_MAX_LENGTH);
            this.reasonForAttendance   = insertSoftBreaks(GuestCategoryReportPdfController.stripHtml(g.reasonForAttendance));
            this.guestCategory         = insertSoftBreaks(GuestCategoryReportPdfController.stripHtml(g.guestCategory));
            this.tier                  = insertSoftBreaks(GuestCategoryReportPdfController.stripHtml(g.tier));
            this.inboundDate           = g.inboundDate;
            this.inboundTime           = g.inboundTime;
            this.outboundDate          = g.outboundDate;
            this.outboundTime          = g.outboundTime;
            this.accompanyingGuest     = insertSoftBreaks(GuestCategoryReportPdfController.stripHtml(g.accompanyingGuest));
            this.relationshipTo        = insertSoftBreaks(GuestCategoryReportPdfController.stripHtml(g.relationshipTo));
            this.groupId               = g.groupId;
            this.comments              = GuestCategoryReportPdfController.stripHtml(g.comments);
            this.mainGuestFullName     = GuestCategoryReportPdfController.stripHtml(g.mainGuestFullName);
            this.invitationStatus      = GuestCategoryReportPdfController.stripHtml(g.invitationStatus);
            this.invitationTier        = GuestCategoryReportPdfController.stripHtml(g.invitationTier);

        }
    }
}