public class EventGuestBioController {

    public String guestBioHtml { get; private set; }
    public String  eventTitle   { get; set; }
    public String  eventDateStr { get; set; }
    public Boolean hasGuests    { get; set; }
    // At 12pt Helvetica in a ~75%-width text column with 1.6 line-height,
    // a single Letter/A4 page realistically holds somewhere around
    // 1800-2200 characters once the title row, footer reservation, and
    // cell padding are accounted for - and that's an estimate, not an
    // exact measurement, so a conservative buffer is intentional here
    // rather than cutting it close. 3200 (original) and even 2000 were
    // still letting occasional chunks run past one physical page.
    private static final Integer CHUNK_LIMIT = 1600;
    // Visualforce PDF rendering enforces a hard, non-configurable
    // platform limit: the total size of all images embedded in one
    // generated PDF cannot exceed 30 MB, regardless of the CSS
    // width/height the images are displayed at (a full-resolution
    // photo shown at 150x150 still counts its full file size). With
    // 1,000+ guests, each potentially carrying a full-resolution
    // uploaded photo, that ceiling is easy to exceed even though this
    // never shows up with a handful of small sandbox test images.
    // Rather than let the whole PDF fail to render for every guest
    // when the org-wide total crosses 30 MB, photos are added up to a
    // conservative budget (leaving headroom below the hard limit);
    // once the budget is used up, remaining guests simply fall back to
    // the existing "N/A" placeholder instead of a photo, and the PDF
    // still generates successfully with every guest's bio text intact.
    private static final Long IMAGE_BUDGET_BYTES = 25L * 1024 * 1024; // 25 MB safety margin under the 30 MB platform limit
    public EventGuestBioController() {
        hasGuests    = false;
        eventTitle   = 'Guest Biographies';
        eventDateStr = '';
        guestBioHtml = '';
        Id invitationId = ApexPages.currentPage().getParameters().get('id');
        if (invitationId == null) { return; }
        List<Invitation__c> invList = [
            SELECT Id, Name, Event_Start_Date__c
            FROM   Invitation__c
            WHERE  Id = :invitationId
            LIMIT  1
        ];
        if (invList.isEmpty()) { return; }
        Invitation__c inv = invList[0];
        if (!String.isBlank(inv.Name)) {
            eventTitle = inv.Name;
        }
        if (inv.Event_Start_Date__c != null) {
            eventDateStr = inv.Event_Start_Date__c.format();
        }
        String safeTitle = (String.isBlank(inv.Name) ? 'Guest Bios' : inv.Name)
            .replaceAll('[^a-zA-Z0-9 ]', '');
        ApexPages.currentPage().getHeaders().put(
            'Content-Disposition',
            'inline; filename=Guest Bios - ' + safeTitle + '.pdf'
        );

        List<Guest_List__c> guestRecords = [
            SELECT Id, Contact__c
            FROM   Guest_List__c
            WHERE  Invitation__c = :invitationId
            AND    Contact__c != null
        ];
        if (guestRecords.isEmpty()) { return; }
        Set<Id> contactIds = new Set<Id>();
        for (Guest_List__c gl : guestRecords) {
            contactIds.add(gl.Contact__c);
        }
        Map<Id, Contact> contactMap = new Map<Id, Contact>([
            SELECT Id, Name, Title,
                   Professional_Personal_Backgrounds__c
            FROM   Contact
            WHERE  Id IN :contactIds
            ORDER BY Name ASC
        ]);
        Map<Id, Attachment> attachMap = new Map<Id, Attachment>();
        Long totalImageBytes = 0;
        for (Attachment a : [
            SELECT Id, ParentId, BodyLength, LastModifiedDate
            FROM   Attachment
            WHERE  ParentId    IN :contactIds
            AND    ContentType IN ('image/png','image/jpeg','image/gif','image/jpg')
            ORDER BY LastModifiedDate DESC
        ]) {
            if (attachMap.containsKey(a.ParentId)) { continue; }
            // Long.valueOf() in Apex only accepts a String argument (unlike
            // Java's numeric overloads), so widen Integer -> Long via plain
            // assignment instead of a method call.
            Long size = 0L;
            if (a.BodyLength != null) { size = a.BodyLength; }
            if (totalImageBytes + size > IMAGE_BUDGET_BYTES) { continue; }
            attachMap.put(a.ParentId, a);
            totalImageBytes += size;
        }
        hasGuests = !contactMap.isEmpty();
        // StringBuilder-style concatenation via List<String> + join()
        // is far cheaper than repeated String += in a loop of 1000+
        // iterations.
        List<String> htmlParts = new List<String>();
        for (Contact c : contactMap.values()) {
            htmlParts.add(renderGuestBlock(c, attachMap.get(c.Id)));
        }
        guestBioHtml = String.join(htmlParts, '');
    }
    // Renders one guest's full HTML block (one or more pages if the
    // bio is too long to fit a single page once reflowed).
    private String renderGuestBlock(Contact c, Attachment attach) {
        Boolean hasPhoto = (attach != null);
        String photoImgTag = hasPhoto
            ? '<img src="/servlet/servlet.FileDownload?file=' + attach.Id +
              '" alt="photo" style="width:150px; height:150px; object-fit:cover; display:block; margin:0 auto;" />'
            : '<div class="photo-na">N/A</div>';
        String nameTitleHeader =
            '<div class="th-name">' + escapeHtml(c.Name) + '</div>' +
            (String.isBlank(c.Title) ? '' :
                '<div class="th-title">' + escapeHtml(c.Title) + '</div>');
        List<String> paragraphs = String.isBlank(c.Professional_Personal_Backgrounds__c)
            ? new List<String>()
            : normalizeParagraphs(c.Professional_Personal_Backgrounds__c);
        if (paragraphs.isEmpty()) {
            return
                '<div class="new-page-guest">' +
                  '<div class="page-content-wrap">' +
                    '<table class="bio-table">' +
                      '<tr class="bio-title-row"><td colspan="2">' + nameTitleHeader + '</td></tr>' +
                      '<tr>' +
                        '<td class="td-text" style="color:#999;font-style:italic;">Biography not yet available.</td>' +
                        '<td class="td-photo">' + photoImgTag + '</td>' +
                      '</tr>' +
                    '</table>' +
                  '</div>' +
                '</div>';
        }
        List<List<String>> chunks = packIntoChunks(paragraphs);
        List<String> pages = new List<String>();
        for (Integer i = 0; i < chunks.size(); i++) {
            String pageClass = (i == 0) ? 'new-page-guest' : 'new-page-chunk';
            String photoCell = (i == 0) ? photoImgTag : '';
            // Joined as one continuous flowing block (space-separated,
            // no per-paragraph <div>/<br>) to match the single-contact
            // ContactBio page's look, where paragraphs collapse into
            // one continuous justified block rather than a stack of
            // separately-broken paragraphs.
            List<String> escapedParagraphs = new List<String>();
            for (String para : chunks[i]) {
                escapedParagraphs.add(escapeHtml(para));
            }
            String chunkHtml = String.join(escapedParagraphs, ' ');
            pages.add(
                '<div class="' + pageClass + '">' +
                  '<div class="page-content-wrap">' +
                    '<table class="bio-table">' +
                      '<tr class="bio-title-row"><td colspan="2">' + nameTitleHeader + '</td></tr>' +
                      '<tr>' +
                        '<td class="td-text">' + chunkHtml + '</td>' +
                        '<td class="td-photo">' + photoCell + '</td>' +
                      '</tr>' +
                    '</table>' +
                  '</div>' +
                '</div>'
            );
        }
        return String.join(pages, '');
    }
    // Splits raw bio text into clean paragraphs: a real paragraph
    // break (blank line) is preserved as a separate paragraph; a
    // SINGLE line break inside a paragraph (a hard-wrapped fragment
    // copied out of a source PDF/Word doc) is treated as a soft wrap
    // and replaced with a space, so the text can reflow naturally
    // instead of being forced onto a new line at every old break.
    //
    // A paragraph produced this way can still be far longer than one
    // page can hold - this is exactly what was happening with bios
    // pasted in as one continuous block of text with no blank lines
    // anywhere (so the whole bio became a single "paragraph"). Since
    // packIntoChunks only ever splits BETWEEN paragraphs, never within
    // one, an oversized paragraph became one oversized chunk that
    // spilled across several physical PDF pages, losing the table
    // border/title-bar on every page after the first. Any paragraph
    // over CHUNK_LIMIT is now split further so it behaves like several
    // normal, page-sized paragraphs.
    private List<String> normalizeParagraphs(String raw) {
        List<String> result = new List<String>();
        if (String.isBlank(raw)) { return result; }
        String text = raw.replace('\r\n', '\n').replace('\r', '\n');
        String[] rawParagraphs = text.split('\n\\s*\n+');
        for (String rp : rawParagraphs) {
            String cleaned = rp.replace('\n', ' ').replaceAll('\\s+', ' ').trim();
            if (String.isBlank(cleaned)) { continue; }
            if (cleaned.length() <= CHUNK_LIMIT) {
                result.add(cleaned);
            } else {
                result.addAll(splitLongParagraph(cleaned));
            }
        }
        return result;
    }
    // Splits a single oversized paragraph into pieces no larger than
    // CHUNK_LIMIT, breaking on sentence boundaries (. ! ?) so a split
    // doesn't land mid-sentence wherever possible.
    //
    // This scans the text manually instead of using a java.util.regex
    // Matcher. A pattern like "[^.!?]+[.!?]+" run via Matcher.find()
    // over a long run of text with sparse or no sentence-ending
    // punctuation forces the regex engine into heavy backtracking at
    // every starting offset - for a several-thousand-character
    // paragraph with no '.', '!' or '?' at all (e.g. a bio pasted in
    // as one continuous block, exactly the case this method exists to
    // handle), that backtracking can exceed Salesforce's regex
    // complexity limit and throw
    // "System.LimitException: Regex too complicated". A manual O(n)
    // scan has no such failure mode regardless of length or
    // punctuation density.
    private List<String> splitLongParagraph(String text) {
        List<String> sentences = new List<String>();
        Integer len = text.length();
        Integer start = 0;
        Integer i = 0;
        while (i < len) {
            String ch = text.substring(i, i + 1);
            if (ch == '.' || ch == '!' || ch == '?') {
                Integer j = i + 1;
                // absorb a run of additional terminators, e.g. "?!" or "..."
                while (j < len) {
                    String nextCh = text.substring(j, j + 1);
                    if (nextCh == '.' || nextCh == '!' || nextCh == '?') {
                        j++;
                    } else {
                        break;
                    }
                }
                String sentence = text.substring(start, j).trim();
                if (!String.isBlank(sentence)) { sentences.add(sentence); }
                // skip the whitespace that follows before the next sentence starts
                while (j < len && isSentenceWhitespace(text.substring(j, j + 1))) {
                    j++;
                }
                start = j;
                i = j;
            } else {
                i++;
            }
        }
        if (start < len) {
            String remainder = text.substring(start).trim();
            if (!String.isBlank(remainder)) { sentences.add(remainder); }
        }
        if (sentences.isEmpty()) { sentences.add(text); }
        List<String> pieces = new List<String>();
        String current = '';
        for (String s : sentences) {
            if (s.length() > CHUNK_LIMIT) {
                // A single "sentence" is itself still too long (e.g.
                // no punctuation at all in a long run of text) - fall
                // back to a hard word-boundary split.
                if (!String.isBlank(current)) { pieces.add(current.trim()); current = ''; }
                pieces.addAll(hardSplitByWords(s));
                continue;
            }
            if (current.length() != 0 && (current.length() + s.length() + 1) > CHUNK_LIMIT) {
                pieces.add(current.trim());
                current = '';
            }
            current += (current.length() == 0 ? '' : ' ') + s;
        }
        if (!String.isBlank(current)) { pieces.add(current.trim()); }
        return pieces;
    }
    // Small whitespace check used by the manual scan in
    // splitLongParagraph above.
    private Boolean isSentenceWhitespace(String ch) {
        return ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r';
    }
    // Last-resort split for a "sentence" with no sentence-ending
    // punctuation at all - breaks on word boundaries instead of
    // mid-word.
    private List<String> hardSplitByWords(String text) {
        List<String> pieces = new List<String>();
        List<String> words = text.split(' ');
        String current = '';
        for (String w : words) {
            if (current.length() != 0 && (current.length() + w.length() + 1) > CHUNK_LIMIT) {
                pieces.add(current.trim());
                current = '';
            }
            current += (current.length() == 0 ? '' : ' ') + w;
        }
        if (!String.isBlank(current)) { pieces.add(current.trim()); }
        return pieces;
    }
    // Greedily packs paragraphs into page-sized chunks without ever
    // splitting a paragraph itself across two chunks. Safe now that
    // normalizeParagraphs guarantees no single paragraph exceeds
    // CHUNK_LIMIT on its own.
    private List<List<String>> packIntoChunks(List<String> paragraphs) {
        List<List<String>> chunks = new List<List<String>>();
        List<String> current = new List<String>();
        Integer currentLen = 0;
        for (String p : paragraphs) {
            Integer pLen = p.length();
            if (currentLen > 0 && (currentLen + pLen) > CHUNK_LIMIT) {
                chunks.add(current);
                current = new List<String>();
                currentLen = 0;
            }
            current.add(p);
            currentLen += pLen + 2;
        }
        if (!current.isEmpty()) {
            chunks.add(current);
        }
        return chunks;
    }
    // Minimal HTML escaping since this string is injected with
    // escape="false" on the VF page. Preserves newlines (used as
    // paragraph separators above) for the white-space: pre-line
    // styling on .td-text.
    private String escapeHtml(String input) {
        if (input == null) { return ''; }
        return input
            .replace('&', '&amp;')
            .replace('<', '&lt;')
            .replace('>', '&gt;')
            .replace('"', '&quot;');
    }
}