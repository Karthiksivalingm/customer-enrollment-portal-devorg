/**
 * SwoogoQuestionMapService
 *
 * Dynamically maps Swoogo event custom question attributes (c_XXXXXXX)
 * to Salesforce Guest_List__c fields by scanning question name/label
 * with keyword patterns.
 *
 * Handles per-event caching so event-questions API is only called once
 * per batch transaction per event.
 *
 * Mapped SF fields:
 *   Hotel_Name__c          → question name contains: hotel, accommodation, room
 *   Relationship_to__c     → question name contains: relationship, relation to
 *   Inbound_Date_Time__c   → COMBINED: I/B date attr + I/B time attr
 *   Outbound_Date_Time__c  → COMBINED: O/B date attr + O/B time attr
 *
 * NOT mapped (intentionally removed): X1_of_invited_guest__c.
 * It is a Lookup/relationship field in this org, not a text field —
 * Swoogo sends a plain name string for that question (e.g. "Praveen
 * Kumar"), which Salesforce can't coerce into a record Id, causing a
 * MALFORMED_ID error on the ENTIRE Guest_List__c record (not just that
 * field). That silently blocked Hotel_Name__c/Relationship_to__c/
 * Inbound/Outbound from saving too, since Database.update(list, false)
 * fails per-record.
 *
 * Reason_for_Inviting__c was removed per explicit request and is no
 * longer referenced by this service or by SwoogoRegistrantSyncService.
 */
public with sharing class SwoogoQuestionMapService {

    // ── Cache: eventId → EventQuestionMap ─────────────────────
    private static Map<String, EventQuestionMap> cache =
        new Map<String, EventQuestionMap>();

    // ── Keyword patterns → SF field ───────────────────────────
    // Order matters — more specific patterns first

    // Simple text field keywords
    private static final Map<String, String> TEXT_KEYWORDS =
        new Map<String, String>{
            'hotel'         => 'Hotel_Name__c',
            'accommodation' => 'Hotel_Name__c',
            'room'          => 'Hotel_Name__c',
            'relationship'  => 'Relationship_to__c',
            'relation to'   => 'Relationship_to__c'
        };

    // Inbound date keywords (I/B Dep. Date, Inbound Date, etc.)
    private static final List<String> INBOUND_DATE_KEYWORDS =
        new List<String>{ 'i/b dep', 'i/b date', 'inbound dep', 'inbound date',
                          'i/b departure', 'ib dep', 'ib date' };

    // Inbound time keywords (I/B T/O Time, Inbound Time, etc.)
    private static final List<String> INBOUND_TIME_KEYWORDS =
        new List<String>{ 'i/b t/o', 'i/b time', 'inbound t/o', 'inbound time',
                          'i/b to time', 'ib t/o', 'ib time', 'i/b to' };

    // Outbound date keywords (O/B Date, Outbound Date, etc.)
    private static final List<String> OUTBOUND_DATE_KEYWORDS =
        new List<String>{ 'o/b date', 'outbound date', 'o/b dep', 'outbound dep',
                          'o/b departure', 'ob date', 'ob dep' };

    // Outbound time keywords (O/B TO Time, Outbound Time, etc.)
    private static final List<String> OUTBOUND_TIME_KEYWORDS =
        new List<String>{ 'o/b to time', 'o/b time', 'outbound t/o', 'outbound time',
                          'o/b t/o', 'ob to time', 'ob time', 'o/b to' };

    // ── Public entry point ────────────────────────────────────

    public static EventQuestionMap getMapForEvent(String eventId) {
        if (cache.containsKey(eventId)) return cache.get(eventId);

        EventQuestionMap eqm = new EventQuestionMap();

        try {
            Integer page       = 1;
            Integer totalPages = 1;

            do {
                String body = SwoogoApiClient.doGet(
                    '/event-questions.json?event_id=' + eventId
                    + '&per_page=100&page=' + page
                    + '&fields=id,name,attribute');

                Map<String,Object> parsed =
                    (Map<String,Object>) JSON.deserializeUntyped(body);

                // Update total pages from meta
                Map<String,Object> meta = (Map<String,Object>) parsed.get('_meta');
                if (meta != null && page == 1) {
                    Object pc = meta.get('pageCount');
                    if (pc != null)
                        totalPages = Integer.valueOf(String.valueOf(pc));
                }

                List<Object> items = (List<Object>) parsed.get('items');
                if (items == null || items.isEmpty()) break;

                for (Object o : items) {
                Map<String,Object> q = (Map<String,Object>) o;
                String qName = String.valueOf(q.get('name') != null
                    ? q.get('name') : '').toLowerCase().trim();
                String attr  = String.valueOf(q.get('attribute') != null
                    ? q.get('attribute') : '').trim();

                if (String.isBlank(qName) || String.isBlank(attr)) continue;

                // ── Check inbound date ─────────────────────────
                if (eqm.inboundDateAttr == null) {
                    for (String kw : INBOUND_DATE_KEYWORDS) {
                        if (qName.contains(kw)) {
                            eqm.inboundDateAttr = attr;
                            System.debug('QuestionMap: inboundDate=' + attr
                                + ' label=' + qName);
                            break;
                        }
                    }
                    if (eqm.inboundDateAttr != null) continue;
                }

                // ── Check inbound time ─────────────────────────
                if (eqm.inboundTimeAttr == null) {
                    for (String kw : INBOUND_TIME_KEYWORDS) {
                        if (qName.contains(kw)) {
                            eqm.inboundTimeAttr = attr;
                            System.debug('QuestionMap: inboundTime=' + attr
                                + ' label=' + qName);
                            break;
                        }
                    }
                    if (eqm.inboundTimeAttr != null) continue;
                }

                // ── Check outbound date ────────────────────────
                if (eqm.outboundDateAttr == null) {
                    for (String kw : OUTBOUND_DATE_KEYWORDS) {
                        if (qName.contains(kw)) {
                            eqm.outboundDateAttr = attr;
                            System.debug('QuestionMap: outboundDate=' + attr
                                + ' label=' + qName);
                            break;
                        }
                    }
                    if (eqm.outboundDateAttr != null) continue;
                }

                // ── Check outbound time ────────────────────────
                if (eqm.outboundTimeAttr == null) {
                    for (String kw : OUTBOUND_TIME_KEYWORDS) {
                        if (qName.contains(kw)) {
                            eqm.outboundTimeAttr = attr;
                            System.debug('QuestionMap: outboundTime=' + attr
                                + ' label=' + qName);
                            break;
                        }
                    }
                    if (eqm.outboundTimeAttr != null) continue;
                }

                // ── Check simple text fields ───────────────────
                for (String kw : TEXT_KEYWORDS.keySet()) {
                    if (qName.contains(kw)) {
                        String sfField = TEXT_KEYWORDS.get(kw);
                        // Don't overwrite already mapped field
                        if (!eqm.simpleFieldMap.containsKey(sfField)) {
                            eqm.simpleFieldMap.put(sfField, attr);
                            System.debug('QuestionMap: ' + sfField
                                + '=' + attr + ' label=' + qName);
                        }
                        break;
                    }
                }
            }

            // Build the combined custom fields list for registrant API call
                page++;
            } while (page <= totalPages);

            eqm.buildCustomFieldsList();

        } catch (Exception ex) {
            System.debug('QuestionMap error event=' + eventId
                + ': ' + ex.getMessage());
        }

        cache.put(eventId, eqm);
        System.debug('QuestionMap for event=' + eventId + ': ' + eqm);
        return eqm;
    }

    // ── EventQuestionMap wrapper ──────────────────────────────

    public class EventQuestionMap {
        // Inbound: need TWO attributes to combine into one DateTime
        public String inboundDateAttr;   // e.g. c_6251500
        public String inboundTimeAttr;   // e.g. c_6251503

        // Outbound: need TWO attributes to combine into one DateTime
        public String outboundDateAttr;  // e.g. c_6251515
        public String outboundTimeAttr;  // e.g. c_6251518

        // Simple text fields: SF_field → swoogo_attr
        // e.g. Hotel_Name__c → c_6251999, Relationship_to__c → c_6251222
        public Map<String, String> simpleFieldMap = new Map<String, String>();

        // All custom field attributes to request in registrant API
        public List<String> customFieldsList = new List<String>();

        // Whether this event has any mapped fields
        public Boolean hasAnyMapping {
            get {
                return !simpleFieldMap.isEmpty()
                    || inboundDateAttr != null
                    || outboundDateAttr != null;
            }
        }

        public void buildCustomFieldsList() {
            Set<String> attrs = new Set<String>();
            if (inboundDateAttr  != null) attrs.add(inboundDateAttr);
            if (inboundTimeAttr  != null) attrs.add(inboundTimeAttr);
            if (outboundDateAttr != null) attrs.add(outboundDateAttr);
            if (outboundTimeAttr != null) attrs.add(outboundTimeAttr);
            for (String sfField : simpleFieldMap.keySet())
                attrs.add(simpleFieldMap.get(sfField));
            customFieldsList = new List<String>(attrs);
        }

        /**
         * Apply custom field values from a registrant raw map
         * to a Guest_List__c record using SObject.put()
         */
        public void applyToGuestList(
            Guest_List__c gl,
            Map<String, Object> registrantRawMap)
        {
            // Simple text fields
            for (String sfField : simpleFieldMap.keySet()) {
                String attr = simpleFieldMap.get(sfField);
                Object val  = registrantRawMap.get(attr);
                if (val != null && String.valueOf(val) != 'null') {
                    gl.put(sfField, String.valueOf(val));
                }
            }

            // Inbound DateTime = date + time combined
            if (inboundDateAttr != null) {
                Object dateVal = registrantRawMap.get(inboundDateAttr);
                Object timeVal = inboundTimeAttr != null
                    ? registrantRawMap.get(inboundTimeAttr) : null;
                Datetime dt = buildDT(dateVal, timeVal);
                if (dt != null) gl.put('Inbound_Date_Time__c', dt);
            }

            // Outbound DateTime = date + time combined
            if (outboundDateAttr != null) {
                Object dateVal = registrantRawMap.get(outboundDateAttr);
                Object timeVal = outboundTimeAttr != null
                    ? registrantRawMap.get(outboundTimeAttr) : null;
                Datetime dt = buildDT(dateVal, timeVal);
                if (dt != null) gl.put('Outbound_Date_Time__c', dt);
            }
        }

        private Datetime buildDT(Object dateVal, Object timeVal) {
            if (dateVal == null || String.valueOf(dateVal) == 'null') return null;
            String datePart = String.valueOf(dateVal).trim();
            if (String.isBlank(datePart)) return null;
            String timePart = (timeVal != null && String.valueOf(timeVal) != 'null')
                ? String.valueOf(timeVal).trim() : '00:00:00';
            try {
                return Datetime.valueOf(datePart + ' ' + timePart);
            } catch (Exception e) {
                System.debug('buildDT failed: ' + datePart + ' ' + timePart);
                return null;
            }
        }

        public override String toString() {
            return 'EventQuestionMap{'
                + 'inboundDate=' + inboundDateAttr
                + ' inboundTime=' + inboundTimeAttr
                + ' outboundDate=' + outboundDateAttr
                + ' outboundTime=' + outboundTimeAttr
                + ' simpleFields=' + simpleFieldMap
                + '}';
        }
    }
}