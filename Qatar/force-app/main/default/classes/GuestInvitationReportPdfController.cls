public with sharing class GuestInvitationReportPdfController {
    public PdfReport report { get; private set; }
    public String errorMessage { get; private set; }

    private static final String ALL_SENTINEL = 'ALL';
    private static final Integer BIO_MAX_LENGTH = 450;
    private static final Integer SOFT_BREAK_CHUNK_SIZE = 10;

    // Rough row-height estimate used to decide where to force a page break, since
    // the renderer does not reliably honor page-break-inside: avoid on table rows —
    // rows straddling a page boundary just get visually split instead of moved
    // whole to the next page. These are approximations (Apex can't measure actual
    // rendered text width), tuned from the current PDF layout (7.5pt font, 1.3 line
    // height, landscape A4). Adjust if rows still split or if too much blank space
    // appears at the bottom of pages.
    //
    // Two columns wrap heavily enough to drive row height: Guest Bio (~20% column
    // width) and Reason of Attendance (~14% column width) — Reason of Attendance
    // was previously left out of this estimate entirely, so a long value there
    // (which can run as long as, or longer than, the bio) was invisible to the
    // page-break logic and could blow a single row out to consume most of a page
    // uncounted. The estimate now takes whichever of the two needs more lines.
    private static final Decimal LINE_HEIGHT_PT = 9.75;
    private static final Decimal CELL_VERTICAL_PADDING_PT = 6;
    private static final Decimal BIO_CHARS_PER_LINE = 16;    // calibrated for the ~20% Guest Bio column
    private static final Decimal REASON_CHARS_PER_LINE = 11; // calibrated for the ~14% Reason of Attendance column
    private static final Integer BASELINE_ROW_LINES = 3; // minimum lines even for a short/empty bio
    private static final Decimal FIRST_PAGE_BUDGET_PT = 460; // after report header + table header
    private static final Decimal OTHER_PAGE_BUDGET_PT = 500; // after repeating table header only

    public GuestInvitationReportPdfController() {
        Map<String, String> params = ApexPages.currentPage().getParameters();
        try {
            Id eventId = (Id) params.get('eventId');
            String tier = normalizeFilter(params.get('tier'));
            String status = normalizeFilter(params.get('status'));
            GuestCategoryReportController.ReportWrapper source =
                GuestCategoryReportController.getReportByInvitationForPdf(eventId, tier, status);
            report = new PdfReport(source);
        } catch (Exception e) {
            errorMessage = 'Unable to load report: ' + e.getMessage();
        }
    }

    // ---- Called imperatively by the LWC's Download PDF button. Renders this same
    //      Visualforce page server-side and returns the finished PDF as base64 bytes,
    //      instead of the LWC just building a URL and opening a new tab. The old
    //      approach (NavigationMixin.GenerateUrl + window.open) resolved almost
    //      instantly regardless of how long the PDF actually took to render, so the
    //      button's spinner disappeared long before the report was ready — this way
    //      the Apex call itself doesn't return until the PDF is fully built, so the
    //      spinner in the LWC accurately covers the real generation time. ----
    @AuraEnabled
    public static String getPdfBase64(Id eventId, String tier, String status) {
        PageReference pdfPage = Page.GuestInvitationReportPdf;
        pdfPage.getParameters().put('eventId', eventId);
        pdfPage.getParameters().put('tier', String.isBlank(tier) ? ALL_SENTINEL : tier);
        pdfPage.getParameters().put('status', String.isBlank(status) ? ALL_SENTINEL : status);

        Blob pdfBlob;
        if (Test.isRunningTest()) {
            // getContentAsPDF() isn't supported in test context.
            pdfBlob = Blob.valueOf('Test PDF content');
        } else {
            pdfBlob = pdfPage.getContentAsPDF();
        }
        return EncodingUtil.base64Encode(pdfBlob);
    }

    private static String normalizeFilter(String value) {
        if (String.isBlank(value) || value.equalsIgnoreCase(ALL_SENTINEL)) {
            return null;
        }
        return value;
    }

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

    private static String truncate(String input, Integer maxLength) {
        if (String.isBlank(input) || input.length() <= maxLength) {
            return input;
        }
        String snippet = input.substring(0, maxLength);

        // Prefer to end at the last complete sentence within the limit, so we don't
        // cut off mid-word or mid-thought.
        Integer lastSentenceEnd = -1;
        for (String punct : new List<String>{ '.', '!', '?' }) {
            Integer idx = snippet.lastIndexOf(punct);
            if (idx > lastSentenceEnd) {
                lastSentenceEnd = idx;
            }
        }
        // Only use the sentence break if it's not so early that we'd throw away most
        // of the allowed length (e.g. an abbreviation like "Dr." near the start).
        if (lastSentenceEnd > (maxLength / 2)) {
            return snippet.substring(0, lastSentenceEnd + 1).trim();
        }

        // No usable sentence break — fall back to the last full word so we at least
        // don't cut off mid-word.
        Integer lastSpace = snippet.lastIndexOf(' ');
        if (lastSpace > 0) {
            snippet = snippet.substring(0, lastSpace);
        }
        return snippet.trim() + '...';
    }

    // Inserts a zero-width space every SOFT_BREAK_CHUNK_SIZE characters inside any
    // "word" (run of non-space characters) longer than that chunk size. Salesforce's
    // renderAs="pdf" engine has unreliable support for CSS word-break/overflow-wrap,
    // so long unbroken values (e.g. "INTERNATIONAL", "MINISTERSANDGOVERNMENT...")
    // can visually overflow into neighboring table cells. A real zero-width space
    // character gives the renderer an actual point to break the line at.
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

    // Estimates a row's rendered height in points. Takes whichever of Guest Bio or
    // Reason of Attendance needs more wrapped lines in its (narrower) column, since
    // either one can be the tallest part of the row.
    private static Decimal estimateRowHeightPt(String bioText, String reasonText) {
        Integer bioLen = String.isBlank(bioText) ? 0 : bioText.length();
        Integer reasonLen = String.isBlank(reasonText) ? 0 : reasonText.length();
        Integer bioLines = Math.max(1, Integer.valueOf(Math.ceil(bioLen / BIO_CHARS_PER_LINE)));
        Integer reasonLines = Math.max(1, Integer.valueOf(Math.ceil(reasonLen / REASON_CHARS_PER_LINE)));
        Integer lines = Math.max(Math.max(bioLines, reasonLines), BASELINE_ROW_LINES);
        return CELL_VERTICAL_PADDING_PT + (lines * LINE_HEIGHT_PT);
    }

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
                    // Won't fit in what's left on the current page — force it onto
                    // a fresh page instead of letting the renderer split it.
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
        public Boolean startsNewPage { get; set; }

        public PdfGuestRow(GuestCategoryReportController.GuestRow g) {
            this.startsNewPage         = false;
            this.fullName             = stripHtml(g.fullName);
            this.photoUrl              = g.photoUrl; // relative /servlet/servlet.FileDownload URL, or blank if omitted due to size
            this.source                = insertSoftBreaks(stripHtml(g.source));
            this.title                 = stripHtml(g.title);
            this.company               = insertSoftBreaks(stripHtml(g.company));
            this.jobTitle               = insertSoftBreaks(stripHtml(g.jobTitle));
            this.bio                   = truncate(stripHtml(g.bio), BIO_MAX_LENGTH);
            this.reasonForAttendance   = insertSoftBreaks(stripHtml(g.reasonForAttendance));
            this.guestCategory         = insertSoftBreaks(stripHtml(g.guestCategory));
            this.tier                  = insertSoftBreaks(stripHtml(g.tier));
            this.inboundDate           = g.inboundDate;
            this.inboundTime           = g.inboundTime;
            this.outboundDate          = g.outboundDate;
            this.outboundTime          = g.outboundTime;
            this.accompanyingGuest     = insertSoftBreaks(stripHtml(g.accompanyingGuest));
            this.relationshipTo        = insertSoftBreaks(stripHtml(g.relationshipTo));
            this.groupId               = g.groupId;
            this.comments              = stripHtml(g.comments);
            this.mainGuestFullName     = stripHtml(g.mainGuestFullName);
            this.invitationStatus      = stripHtml(g.invitationStatus);
            this.invitationTier        = stripHtml(g.invitationTier);
        }
    }
}