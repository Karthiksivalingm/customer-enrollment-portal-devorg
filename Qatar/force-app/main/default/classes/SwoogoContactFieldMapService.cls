/**
 * SwoogoContactFieldMapService
 *
 * Resolves the Swoogo Contact custom-field attributes (c_XXXXXXX) for
 * "Reason for Inviting" and "# of Invited Guests" by scanning Contact
 * field definitions (GET /contacts/fields) and matching on label keywords
 * — same approach as SwoogoQuestionMapService uses for per-event
 * registration Questions, but these are account-wide Contact fields
 * instead, since that's what the Swoogo UI actually surfaces these two
 * under (confirmed: the Add-Contact-to-Invitation-List API has no field
 * slots of its own, so "Reason"/"+1" live on the Contact record itself).
 *
 * Cached once per transaction (static), not per-event, since Contact
 * fields aren't event-scoped.
 */
public with sharing class SwoogoContactFieldMapService {

    private static Boolean loaded = false;
    private static String  plus1Attr;
    private static String  reasonAttr;

    private static final List<String> PLUS1_KEYWORDS = new List<String>{
        'plus 1', 'plus one', 'invited guest', '+1',
        'number of invited', 'no. of invited', 'no of invited'
    };
    private static final List<String> REASON_KEYWORDS = new List<String>{
        'reason', 'purpose'
    };

    private static void loadIfNeeded() {
        if (loaded) return;
        loaded = true;
        try {
            for (Object o : SwoogoApiClient.getContactFields()) {
                Map<String,Object> f = (Map<String,Object>) o;
                String fName = String.valueOf(
                    f.get('name') != null ? f.get('name') : '').toLowerCase().trim();
                String attr = String.valueOf(
                    f.get('attribute') != null ? f.get('attribute') : '').trim();
                if (String.isBlank(fName) || String.isBlank(attr)) continue;

                if (plus1Attr == null) {
                    for (String kw : PLUS1_KEYWORDS) {
                        if (fName.contains(kw)) {
                            plus1Attr = attr;
                            System.debug('ContactFieldMap: plus1Attr=' + attr + ' label=' + fName);
                            break;
                        }
                    }
                }
                if (reasonAttr == null) {
                    for (String kw : REASON_KEYWORDS) {
                        if (fName.contains(kw)) {
                            reasonAttr = attr;
                            System.debug('ContactFieldMap: reasonAttr=' + attr + ' label=' + fName);
                            break;
                        }
                    }
                }
            }
        } catch (Exception ex) {
            System.debug('SwoogoContactFieldMapService load error: ' + ex.getMessage());
        }
    }

    public static String getPlus1Attr()  { loadIfNeeded(); return plus1Attr; }
    public static String getReasonAttr() { loadIfNeeded(); return reasonAttr; }
}