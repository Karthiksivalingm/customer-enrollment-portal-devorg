public with sharing class SwoogoApiClient {

    public static final String  BASE_URL             = 'https://api.swoogo.com/api/v1';
    public static final String  SF_EXTERNAL_ID_FIELD = 'c_8598114';
    private static final String TOKEN_URL            = BASE_URL + '/oauth2/token';
    private static final Integer PAGE_SIZE           = 50;
    private static final Integer MAX_CALLOUTS        = 98;
    private static final Integer DEFAULT_REG_TYPE_CAPACITY = 9999;
    private static String cachedToken;

    // ── Auth ──────────────────────────────────────────────────

    public static String getBearerToken() {
        if (String.isNotBlank(cachedToken)) return cachedToken;

        SwoogoConfig__mdt cfg = [
            SELECT ConsumerKey__c, ConsumerSecret__c
            FROM SwoogoConfig__mdt LIMIT 1
        ];

        String encoded = EncodingUtil.base64Encode(Blob.valueOf(
            EncodingUtil.urlEncode(cfg.ConsumerKey__c,    'UTF-8') + ':' +
            EncodingUtil.urlEncode(cfg.ConsumerSecret__c, 'UTF-8')
        ));

        HttpRequest req = new HttpRequest();
        req.setEndpoint(TOKEN_URL);
        req.setMethod('POST');
        req.setHeader('Authorization', 'Basic ' + encoded);
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded;charset=UTF-8');
        req.setBody('grant_type=client_credentials');
        req.setTimeout(10000);

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200)
            throw new SwoogoException('Auth failed [' + res.getStatusCode() + ']: ' + res.getBody());

        cachedToken = (String)((Map<String,Object>)
            JSON.deserializeUntyped(res.getBody())).get('access_token');
        return cachedToken;
    }

    // ── Events ────────────────────────────────────────────────

    public static SwoogoEvent getEventById(String eventId) {
        return (SwoogoEvent) JSON.deserialize(
            doGet('/events/' + eventId + '.json'), SwoogoEvent.class);
    }

    // Full fetch — used on first run
    public static List<SwoogoEvent> getAllEvents() {
        Map<Long, SwoogoEvent> byId = new Map<Long, SwoogoEvent>();
        try {
            for (Object o : getAllPages(
                '/events.json?fields=id,name,status,start_date,end_date,location,event_venue_type,updated_at,created_at')) {
                SwoogoEvent e = (SwoogoEvent) JSON.deserialize(JSON.serialize(o), SwoogoEvent.class);
                byId.put(e.id, e);
            }
        } catch (Exception ex) { System.debug('getAllEvents error: ' + ex.getMessage()); }
        // Also pull draft events which may not appear in default status filter
        try {
            for (Object o : getAllPages(
                '/events.json?fields=id,name,status,start_date,end_date,location,updated_at'
                + '&search=status%3Ddraft')) {
                SwoogoEvent e = (SwoogoEvent) JSON.deserialize(JSON.serialize(o), SwoogoEvent.class);
                if (!byId.containsKey(e.id)) byId.put(e.id, e);
            }
        } catch (Exception ex) { System.debug('getDraftEvents error: ' + ex.getMessage()); }
        return byId.values();
    }

    // Delta fetch — used on subsequent runs; returns events updated after the given datetime
    public static List<SwoogoEvent> getEventsUpdatedAfter(Datetime since) {
        List<SwoogoEvent> result = new List<SwoogoEvent>();
        String sinceEncoded = EncodingUtil.urlEncode(formatDT(since), 'UTF-8');
        try {
            for (Object o : getAllPages(
                '/events.json?fields=id,name,status,start_date,end_date,location,event_venue_type,updated_at,created_at'
                + '&updated_after=' + sinceEncoded)) {
                result.add((SwoogoEvent) JSON.deserialize(JSON.serialize(o), SwoogoEvent.class));
            }
        } catch (Exception ex) {
            System.debug('getEventsUpdatedAfter error: ' + ex.getMessage());
        }
        return result;
    }

    // ── Sessions (Sub-events) ─────────────────────────────────

    // Full session fetch for a single event
    public static List<SwoogoSession> getSessionsForEvent(String eventId) {
        List<SwoogoSession> result = new List<SwoogoSession>();
        for (Object o : getAllPages(
            '/sessions.json?event_id=' + eventId
            + '&fields=id,name,start_time,end_time,location,date,updated_at,event_id,description,body'
            + '&status=any')) {
            String sessionJson = JSON.serialize(o).replace('"date":', '"session_date":');
            // Map body → description if description is empty
            Map<String,Object> sMap = (Map<String,Object>) JSON.deserializeUntyped(sessionJson);
            if ((sMap.get('description') == null || String.valueOf(sMap.get('description')) == 'null')
                && sMap.get('body') != null) {
                sMap.put('description', sMap.get('body'));
            }
            result.add((SwoogoSession) JSON.deserialize(JSON.serialize(sMap), SwoogoSession.class));
        }
        return result;
    }

    // Delta session fetch — sessions updated after a given datetime for a specific event
    public static List<SwoogoSession> getSessionsUpdatedAfter(String eventId, Datetime since) {
        List<SwoogoSession> result = new List<SwoogoSession>();
        String sinceEncoded = EncodingUtil.urlEncode(formatDT(since), 'UTF-8');
        try {
            for (Object o : getAllPages(
                '/sessions.json?event_id=' + eventId
                + '&fields=id,name,start_time,end_time,location,date,updated_at,event_id,description,body'
                + '&status=any'
                + '&updated_after=' + sinceEncoded)) {
                String sessionJson = JSON.serialize(o).replace('"date":', '"session_date":');
                Map<String,Object> sMap = (Map<String,Object>) JSON.deserializeUntyped(sessionJson);
                if ((sMap.get('description') == null || String.valueOf(sMap.get('description')) == 'null')
                    && sMap.get('body') != null) {
                    sMap.put('description', sMap.get('body'));
                }
                result.add((SwoogoSession) JSON.deserialize(JSON.serialize(sMap), SwoogoSession.class));
            }
        } catch (Exception ex) {
            System.debug('SessionsDelta error ' + eventId + ': ' + ex.getMessage());
        }
        return result;
    }

    // ── Registrants ───────────────────────────────────────────

    public static List<SwoogoRegistrant> getRegistrantsForEvent(String eventId) {
        return getRegistrantsForEvent(eventId, new List<String>());
    }

    public static List<SwoogoRegistrant> getRegistrantsForEvent(
        String eventId, List<String> extraFields)
    {
        String fields = 'id,first_name,last_name,email,job_title'
            + ',mobile_phone,work_phone,registration_status,contact_id,deleted,event_id,session_ids'
            + ',' + SF_EXTERNAL_ID_FIELD;
        if (extraFields != null && !extraFields.isEmpty())
            fields += ',' + String.join(extraFields, ',');
        return fetchRegistrants(
            '/registrants.json?event_id=' + eventId
            + '&fields=' + fields,
            eventId, 'full');
    }

    public static List<SwoogoRegistrant> getRegistrantsUpdatedAfter(String eventId, Datetime since) {
        return getRegistrantsUpdatedAfter(eventId, since, new List<String>());
    }

    public static List<SwoogoRegistrant> getRegistrantsUpdatedAfter(
        String eventId, Datetime since, List<String> extraFields)
    {
        String fields = 'id,first_name,last_name,email,job_title'
            + ',mobile_phone,work_phone,registration_status,contact_id,deleted,event_id,session_ids'
            + ',' + SF_EXTERNAL_ID_FIELD;
        if (extraFields != null && !extraFields.isEmpty())
            fields += ',' + String.join(extraFields, ',');
        return fetchRegistrants(
            '/registrants.json?event_id=' + eventId
            + '&updated_after=' + EncodingUtil.urlEncode(formatDT(since), 'UTF-8')
            + '&fields=' + fields,
            eventId, 'delta');
    }

    // Returns raw Map list preserving custom field values (c_XXXXXXX)
    // Used by question map service to read custom field values
    public static List<Map<String,Object>> getRawRegistrants(
        String eventId, List<String> extraFields, Datetime since)
    {
        List<Map<String,Object>> result = new List<Map<String,Object>>();
        String baseFields = 'id,registration_status';
        if (extraFields != null && !extraFields.isEmpty())
            baseFields += ',' + String.join(extraFields, ',');

        String path = '/registrants.json?event_id=' + eventId
            + '&fields=' + baseFields;
        if (since != null)
            path += '&updated_after='
                + EncodingUtil.urlEncode(formatDT(since), 'UTF-8');

        try {
            Integer page       = 1;
            Integer totalPages = 1;
            do {
                if (Limits.getCallouts() >= MAX_CALLOUTS - 5) break;
                String sep  = path.contains('?') ? '&' : '?';
                String body = doGet(path + sep + 'page=' + page
                    + '&per_page=' + PAGE_SIZE);
                Map<String,Object> parsed =
                    (Map<String,Object>) JSON.deserializeUntyped(body);
                Map<String,Object> meta = (Map<String,Object>) parsed.get('_meta');
                if (meta != null) {
                    Object total = meta.get('totalCount');
                    if (total != null
                        && Integer.valueOf(String.valueOf(total)) == 0) break;
                    Object pc = meta.get('pageCount');
                    if (pc != null)
                        totalPages = Integer.valueOf(String.valueOf(pc));
                }
                List<Object> items = (List<Object>) parsed.get('items');
                if (items == null || items.isEmpty()) break;
                for (Object o : items)
                    result.add((Map<String,Object>) o);
                // Removed: "if (items.size() < PAGE_SIZE) break;" — Swoogo
                // silently caps some endpoints below the requested per_page
                // (confirmed: requested 50, received 20 on session-attendances),
                // so that size comparison broke the loop after page 1 even
                // when many more pages existed. page >= totalPages (from
                // Swoogo's own reported pageCount) below is the only
                // reliable stop condition.
                if (page >= totalPages) break;
                page++;
            } while (true);
        } catch (Exception ex) {
            System.debug('getRawRegistrants error event=' + eventId
                + ': ' + ex.getMessage());
        }
        System.debug('getRawRegistrants event=' + eventId
            + ' count=' + result.size());
        return result;
    }

    private static List<SwoogoRegistrant> fetchRegistrants(
        String path, String eventId, String label)
    {
        List<SwoogoRegistrant> result = new List<SwoogoRegistrant>();
        try {
            Integer page       = 1;
            Integer totalPages = 1;
            do {
                if (Limits.getCallouts() >= MAX_CALLOUTS - 5) {
                    System.debug('Registrant fetch stopped — callout budget low. event='
                        + eventId + ' label=' + label + ' callouts=' + Limits.getCallouts());
                    break;
                }
                String sep  = path.contains('?') ? '&' : '?';
                String body = doGet(path + sep + 'page=' + page + '&per_page=' + PAGE_SIZE);
                Map<String,Object> parsed = (Map<String,Object>) JSON.deserializeUntyped(body);

                Map<String,Object> meta = (Map<String,Object>) parsed.get('_meta');
                if (meta != null) {
                    Object total = meta.get('totalCount');
                    if (total != null && Integer.valueOf(String.valueOf(total)) == 0) break;
                    Object pc = meta.get('pageCount');
                    if (pc != null) totalPages = Integer.valueOf(String.valueOf(pc));
                }

                List<Object> items = (List<Object>) parsed.get('items');
                if (items == null || items.isEmpty()) break;
                for (Object o : items) {
                    Map<String,Object> regMap = (Map<String,Object>) o;
                    SwoogoRegistrant r = (SwoogoRegistrant) JSON.deserialize(
                        JSON.serialize(o), SwoogoRegistrant.class);
                    Object rawSessionIds = regMap.get('session_ids');
                    if (rawSessionIds != null) {
                        r.session_ids = new List<String>();
                        for (Object sid : (List<Object>) rawSessionIds)
                            r.session_ids.add(String.valueOf(sid));
                    }
                    result.add(r);
                }
                // Removed: "if (items.size() < PAGE_SIZE) break;" — see note
                // in getRawRegistrants() above for why this is unreliable.
                if (page >= totalPages) break;
                page++;
            } while (true);
        } catch (Exception ex) {
            System.debug('Registrants ' + label + ' error ' + eventId + ': ' + ex.getMessage());
        }
        System.debug('Registrants (' + label + ') for ' + eventId + ': ' + result.size());
        return result;
    }

    // ── Session Attendances ───────────────────────────────────

    public static List<SessionAttendance> getSessionAttendances(String eventId) {
        List<SessionAttendance> result = new List<SessionAttendance>();
        try {
            String path = '/session-attendances.json?event_id=' + eventId;
            Integer page       = 1;
            Integer totalPages = 1;
            do {
                if (Limits.getCallouts() >= MAX_CALLOUTS - 5) {
                    System.debug('Attendance fetch stopped — callout budget low. event='
                        + eventId + ' callouts=' + Limits.getCallouts());
                    break;
                }
                String sep  = path.contains('?') ? '&' : '?';
                String body = doGet(path + sep + 'page=' + page + '&per_page=' + PAGE_SIZE);
                Map<String,Object> parsed = (Map<String,Object>) JSON.deserializeUntyped(body);

                Map<String,Object> meta = (Map<String,Object>) parsed.get('_meta');
                if (meta != null) {
                    Object total = meta.get('totalCount');
                    if (total != null && Integer.valueOf(String.valueOf(total)) == 0) break;
                    Object pc = meta.get('pageCount');
                    if (pc != null) totalPages = Integer.valueOf(String.valueOf(pc));
                }

                List<Object> items = (List<Object>) parsed.get('items');
                if (items == null || items.isEmpty()) break;
                for (Object o : items)
                    result.add((SessionAttendance) JSON.deserialize(
                        JSON.serialize(o), SessionAttendance.class));
                // Removed: "if (items.size() < PAGE_SIZE) break;" — confirmed
                // via live callout: Swoogo returns perPage=20 on this endpoint
                // even when per_page=50 is requested, so this size check was
                // silently stopping the fetch after page 1 of 35 (686 total
                // records). page >= totalPages (Swoogo's own reported
                // pageCount) is the only condition that actually reflects
                // whether more pages remain.
                if (page >= totalPages) break;
                page++;
            } while (true);
        } catch (Exception ex) {
            System.debug('Attendances error ' + eventId + ': ' + ex.getMessage());
        }
        System.debug('Attendances for ' + eventId + ': ' + result.size());
        return result;
    }

    // Delta attendance fetch — attendances updated after a given datetime
    public static List<SessionAttendance> getSessionAttendancesUpdatedAfter(
        String eventId, Datetime since)
    {
        List<SessionAttendance> result = new List<SessionAttendance>();
        String sinceEncoded = EncodingUtil.urlEncode(formatDT(since), 'UTF-8');
        try {
            String path = '/session-attendances.json?event_id=' + eventId
                + '&updated_after=' + sinceEncoded;
            Integer page       = 1;
            Integer totalPages = 1;
            do {
                if (Limits.getCallouts() >= MAX_CALLOUTS - 5) {
                    System.debug('Attendance delta fetch stopped — callout budget low. event='
                        + eventId + ' callouts=' + Limits.getCallouts());
                    break;
                }
                String sep  = path.contains('?') ? '&' : '?';
                String body = doGet(path + sep + 'page=' + page + '&per_page=' + PAGE_SIZE);
                Map<String,Object> parsed = (Map<String,Object>) JSON.deserializeUntyped(body);

                Map<String,Object> meta = (Map<String,Object>) parsed.get('_meta');
                if (meta != null) {
                    Object total = meta.get('totalCount');
                    if (total != null && Integer.valueOf(String.valueOf(total)) == 0) break;
                    Object pc = meta.get('pageCount');
                    if (pc != null) totalPages = Integer.valueOf(String.valueOf(pc));
                }

                List<Object> items = (List<Object>) parsed.get('items');
                if (items == null || items.isEmpty()) break;
                for (Object o : items)
                    result.add((SessionAttendance) JSON.deserialize(
                        JSON.serialize(o), SessionAttendance.class));
                // Removed: "if (items.size() < PAGE_SIZE) break;" — same
                // fix as getSessionAttendances() above; page >= totalPages
                // is the only reliable stop condition for this endpoint.
                if (page >= totalPages) break;
                page++;
            } while (true);
        } catch (Exception ex) {
            System.debug('Attendances delta error ' + eventId + ': ' + ex.getMessage());
        }
        System.debug('Attendances (delta) for ' + eventId + ': ' + result.size());
        return result;
    }

    // ── Contacts (search / create by email) ────────────────────
    // Used by the invitation-list flow: resolve a Swoogo contact_id for
    // an SF Contact that has no contact_external_id__c yet.

    // GET /contacts.json?search=email=X — returns the contact_id if one
    // already exists in Swoogo for this email.
    public static Long findContactIdByEmail(String email) {
        if (String.isBlank(email)) return null;
        try {
            String path = '/contacts.json?fields=id,email'
                + '&search=email%3D' + EncodingUtil.urlEncode(email, 'UTF-8');
            String body = doGet(path);
            Map<String,Object> parsed = (Map<String,Object>) JSON.deserializeUntyped(body);
            List<Object> items = (List<Object>) parsed.get('items');
            if (items != null && !items.isEmpty()) {
                Map<String,Object> c = (Map<String,Object>) items[0];
                return Long.valueOf(String.valueOf(c.get('id')));
            }
        } catch (Exception ex) {
            System.debug('findContactIdByEmail error email=' + email + ': ' + ex.getMessage());
        }
        return null;
    }

    // POST /contacts/create — creates a new Swoogo contact, form-encoded.
    // Stamps SF_EXTERNAL_ID_FIELD (c_8598114) at creation time — mirrors the
    // same field already set on new registrants via createRegistrant(), so
    // a brand-new Swoogo contact created for a main guest is linked back to
    // its Salesforce Contact just like a brand-new child-guest registrant is.
    // NOTE: this only covers contacts created here for the first time. If a
    // matching contact was found via findContactIdByEmail() instead, this
    // method is never called, and that existing Swoogo contact's
    // c_8598114 is NOT backfilled — there is currently no confirmed
    // "update existing contact" endpoint wired up in this class to do so.
    public static Long createContact(
        String email, String firstName, String lastName, String salesforceContactId)
    {
        String formBody = 'email=' + EncodingUtil.urlEncode(email, 'UTF-8')
            + '&first_name=' + EncodingUtil.urlEncode(firstName, 'UTF-8')
            + '&last_name=' + EncodingUtil.urlEncode(lastName, 'UTF-8')
            + '&' + SF_EXTERNAL_ID_FIELD + '='
            + EncodingUtil.urlEncode(salesforceContactId, 'UTF-8');
        String response = postForm('/contacts/create', formBody);
        Map<String,Object> result = (Map<String,Object>) JSON.deserializeUntyped(response);
        return Long.valueOf(String.valueOf(result.get('id')));
    }

    // PUT /cfs-contacts/update/{contact_id} — updates a custom field on an
    // EXISTING Swoogo contact, form-encoded. This is the counterpart to
    // createContact()'s automatic c_8598114 stamping: when a contact is
    // resolved via findContactIdByEmail() (found, not created), createContact()
    // never runs, so c_8598114 is never set on that contact by any other path.
    // Call this explicitly whenever a contact was found rather than created,
    // so it gets the same SF Contact Id link either way.
    public static void updateContactExternalId(Long swoogoContactId, String salesforceContactId) {
        String formBody = SF_EXTERNAL_ID_FIELD + '='
            + EncodingUtil.urlEncode(salesforceContactId, 'UTF-8');
        putForm('/cfs-contacts/update/' + swoogoContactId, formBody);
    }

    public class SwoogoInvitationListMember {
        public Long   contact_id;
        public String status;
        public String created_at;
        public String updated_at;
    }

    // GET /invitation-lists/{id}/contacts.json — members of one invitation
    // list, including created_at/updated_at so callers can resolve which
    // membership is most recent when a contact appears on more than one list.
    public static List<SwoogoInvitationListMember> getInvitationListMembers(Long invitationListId) {
        List<SwoogoInvitationListMember> result = new List<SwoogoInvitationListMember>();
        try {
            for (Object o : getAllPages(
                '/invitation-lists/' + invitationListId + '/contacts.json'
                + '?fields=contact_id,status,created_at,updated_at')) {
                result.add((SwoogoInvitationListMember) JSON.deserialize(
                    JSON.serialize(o), SwoogoInvitationListMember.class));
            }
        } catch (Exception ex) {
            System.debug('getInvitationListMembers error listId=' + invitationListId
                + ': ' + ex.getMessage());
        }
        return result;
    }

    // ── Invitation Lists ──────────────────────────────────────

    // Fetch all invitation lists configured for an event
    public static List<SwoogoInvitationList> getInvitationListsForEvent(String eventId) {
        List<SwoogoInvitationList> result = new List<SwoogoInvitationList>();
        try {
            for (Object o : getAllPages(
                '/invitation-lists.json?event_id=' + eventId
                + '&fields=id,name,event_id')) {
                result.add((SwoogoInvitationList) JSON.deserialize(
                    JSON.serialize(o), SwoogoInvitationList.class));
            }
        } catch (Exception ex) {
            System.debug('getInvitationListsForEvent error event=' + eventId
                + ': ' + ex.getMessage());
        }
        return result;
    }

    // Add a Swoogo contact to an invitation list.
    // POST /invitation-lists/{invitation_list_id}/contact/{contact_id}
    // No request body — list/contact ids are in the path.
    public static void addContactToInvitationList(Long invitationListId, Long contactId) {
        String path = '/invitation-lists/' + invitationListId
            + '/contact/' + contactId;
        post(path, null);
    }

    // POST /registrants/{registrant_id}/groups/{group_id}
    // Adds a registrant to another registrant's group in Swoogo. Used for
    // child/+1 guests who register directly rather than via an invitation
    // list — the group_id passed in is the main guest's own registrant id.
    // No request body — registrant/group ids are in the path.
    public static void addRegistrantToGroup(Long registrantId, Long groupId) {
        String path = '/registrants/' + registrantId + '/groups/' + groupId;
        post(path, null);
    }

    // ── Pagination ────────────────────────────────────────────

    public static List<Object> getAllPages(String path) {
        List<Object> all   = new List<Object>();
        Integer page       = 1;
        Integer totalPages = 1;
        do {
            if (Limits.getCallouts() >= MAX_CALLOUTS - 5) {
                System.debug('getAllPages stopped — callout budget low. path='
                    + path + ' page=' + page + ' callouts=' + Limits.getCallouts());
                break;
            }
            String sep  = path.contains('?') ? '&' : '?';
            String body = doGet(path + sep + 'page=' + page + '&per_page=' + PAGE_SIZE);
            Map<String,Object> parsed = (Map<String,Object>) JSON.deserializeUntyped(body);

            Map<String,Object> meta = (Map<String,Object>) parsed.get('_meta');
            if (meta != null) {
                Object total = meta.get('totalCount');
                if (total != null && Integer.valueOf(String.valueOf(total)) == 0) break;
                Object pc = meta.get('pageCount');
                if (pc != null) totalPages = Integer.valueOf(String.valueOf(pc));
            }

            List<Object> items = (List<Object>) parsed.get('items');
            if (items == null || items.isEmpty()) break;
            all.addAll(items);
            if (page >= totalPages) break;
            page++;
        } while (true);
        return all;
    }

    // ── HTTP ──────────────────────────────────────────────────

    public static String doGet(String path)             { return send('GET',    path, null, false); }
    public static String post(String path, String body) { return send('POST',   path, body, false); }
    public static String postForm(String path, String formBody) { return send('POST', path, formBody, true); }
    public static String put(String path, String body)  { return send('PUT',    path, body, false); }
    public static String putForm(String path, String formBody)  { return send('PUT', path, formBody, true); }
    public static String del(String path)               { return send('DELETE', path, null, false); }

    // Stores the X-Rate-Limit-Reset value (seconds until window resets)
    // from the most recent 429 response. SwoogoSessionSyncBatch reads
    // this after catching a 429 exception to schedule its retry for
    // exactly the right delay instead of guessing.
    public static Integer lastRateLimitResetSeconds = null;

    private static String send(String method, String path, String body, Boolean asForm) {
        String token = getBearerToken();
        HttpRequest req = buildReq(method, path, body, token, asForm);
        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() == 401) {
            cachedToken = null;
            token = getBearerToken();
            req = buildReq(method, path, body, token, asForm);
            res = new Http().send(req);
        }

        if (res.getStatusCode() == 429) {
            // Read the exact reset time from the response header so
            // callers can schedule a retry for precisely the right
            // delay rather than guessing with a fixed constant.
            String resetHeader = res.getHeader('X-Rate-Limit-Reset');
            if (String.isNotBlank(resetHeader)) {
                try {
                    lastRateLimitResetSeconds = Integer.valueOf(resetHeader);
                } catch (Exception ex) {
                    lastRateLimitResetSeconds = 120; // fallback: 2 min
                }
            } else {
                lastRateLimitResetSeconds = 120; // fallback: 2 min
            }
            System.debug('429 rate limited. Reset in '
                + lastRateLimitResetSeconds + 's. path='
                + path.substringBefore('?').substringAfterLast('/'));
            throw new SwoogoException(method + ' ' + path
                + ' [429]: ' + res.getBody());
        }

        if (res.getStatusCode() >= 200 && res.getStatusCode() < 300)
            return String.isNotBlank(res.getBody()) ? res.getBody() : '{}';

        throw new SwoogoException(method + ' ' + path
            + ' [' + res.getStatusCode() + ']: ' + res.getBody());
    }

    private static HttpRequest buildReq(
        String method, String path, String body, String token, Boolean asForm)
    {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(BASE_URL + path);
        req.setMethod(method);
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Accept', 'application/json');
        if (body != null) {
            req.setHeader('Content-Type', asForm
                ? 'application/x-www-form-urlencoded;charset=UTF-8'
                : 'application/json');
            req.setBody(body);
        }
        req.setTimeout(30000);
        return req;
    }

    public static String formatDT(Datetime dt) {
        return dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    }

    // ── Models ────────────────────────────────────────────────

    public class SwoogoEvent {
        public Long   id;
        public String name;
        public String start_date;
        public String end_date;
        public String location;
        public String event_venue_type;
        public String status;
        public String updated_at;
        public String created_at;
    }

    public class SwoogoSession {
        public Long   id;
        public String name;
        public String start_time;
        public String end_time;
        public String session_date;
        public String location;
        public String description;
        public String updated_at;
        public Long   event_id;
    }

    public class SwoogoRegistrant {
        public Long         id;
        public Long         event_id;
        public String       first_name;
        public String       last_name;
        public String       email;
        public String       registration_status;
        public String       job_title;
        public String       mobile_phone;
        public String       work_phone;
        public String       contact_id;
        public String       c_8598114;
        public Boolean      deleted;
        public List<String> session_ids;
    }

    public class SwoogoInvitationList {
        public Long   id;
        public String name;
        public Long   event_id;
    }

    public class SessionAttendance {
        public Long   registrant_id;
        public Long   session_id;
        public Long   event_id;
        public String check_in_date;
        public String on_demand_date;
        public String updated_at;
    }

    public class SwoogoException extends Exception {}

    // ── Create Registrant (SF → Swoogo) ───────────────────────

    public static Long createRegistrant(
        Long eventId, Long sessionId,
        String firstName, String lastName, String email,
        String company, String jobTitle,
        String mobilePhone, String salesforceContactId,
        String registrantType)
    {
        try {
            String checkPath = '/registrants.json?event_id=' + eventId
                + '&fields=id,email'
                + '&search=email%3D' + EncodingUtil.urlEncode(email, 'UTF-8');
            String checkBody = doGet(checkPath);
            Map<String,Object> checkParsed =
                (Map<String,Object>) JSON.deserializeUntyped(checkBody);
            List<Object> existingItems = (List<Object>) checkParsed.get('items');
            if (existingItems != null && !existingItems.isEmpty()) {
                Map<String,Object> existingReg = (Map<String,Object>) existingItems[0];
                Long existingId = Long.valueOf(String.valueOf(existingReg.get('id')));
                System.debug('Registrant already exists. Email=' + email
                    + ' Registrant ID=' + existingId);
                return existingId;
            }
        } catch (Exception ex) {
            System.debug('Registrant existence check error: ' + ex.getMessage());
        }

        Map<String,Object> payload = new Map<String,Object>{
            'event_id'           => eventId,
            'first_name'         => firstName,
            'last_name'          => lastName,
            'email'              => email,
            'company'            => company,
            'job_title'          => jobTitle,
            'mobile_phone'       => mobilePhone,
            SF_EXTERNAL_ID_FIELD => salesforceContactId
        };
        if (String.isNotBlank(registrantType)) {
            Long regTypeId = getOrCreateRegTypeId(eventId, registrantType);
            if (regTypeId != null) {
                payload.put('reg_type_id', regTypeId);
            } else {
                System.debug('Could not resolve/create reg type in Swoogo for: ' + registrantType);
            }
        }
        if (sessionId != null) {
            payload.put('session_ids', new List<Long>{ sessionId });
        }
        String response = post('/registrants/create.json', JSON.serialize(payload));
        Map<String,Object> result = (Map<String,Object>) JSON.deserializeUntyped(response);
        return Long.valueOf(String.valueOf(result.get('id')));
    }


    // Fetch reg type ID from Swoogo by matching name to Guest_Tiers__c value.
    // If no matching reg type exists for this event, creates one automatically.
    public static Long getOrCreateRegTypeId(Long eventId, String tierName) {
        if (String.isBlank(tierName)) return null;
        String trimmedName = tierName.trim();

        // 1. Try to find an existing reg type with this name
        try {
            String body = doGet('/reg-types.json?event_id=' + eventId
                + '&fields=id,name&per_page=50');
            Map<String,Object> parsed = (Map<String,Object>) JSON.deserializeUntyped(body);
            List<Object> items = (List<Object>) parsed.get('items');
            if (items != null) {
                for (Object o : items) {
                    Map<String,Object> rt = (Map<String,Object>) o;
                    String rtName = String.valueOf(rt.get('name')).trim();
                    if (rtName.equalsIgnoreCase(trimmedName)) {
                        return Long.valueOf(String.valueOf(rt.get('id')));
                    }
                }
            }
        } catch (Exception ex) {
            System.debug('Reg type lookup error: ' + ex.getMessage());
        }

        // 2. Not found — create a new reg type in Swoogo with this name
        try {
            String createBody = 'event_id=' + eventId
                + '&name=' + EncodingUtil.urlEncode(trimmedName, 'UTF-8')
                + '&capacity=' + DEFAULT_REG_TYPE_CAPACITY;
            String response = postForm('/reg-types/create', createBody);
            Map<String,Object> result = (Map<String,Object>) JSON.deserializeUntyped(response);
            return Long.valueOf(String.valueOf(result.get('id')));
        } catch (Exception ex) {
            System.debug('Reg type creation error: ' + ex.getMessage());
            return null;
        }
    }

}