/**
 * TSTemplateSelector
 * -----------------------------------------------------------------------
 * Reads TS Documents template records WITHOUT SHARING.
 *
 * WHY THIS EXISTS
 *   docb__Document_Builder__c records are owned by whoever built them
 *   (Sandip Patel, in this org). With a private sharing model, an
 *   Experience Cloud portal user - CspLitePortal licence - is not shared
 *   those records and a query from a `with sharing` class returns zero
 *   rows. TSDocumentService then reports "No TS Documents template named
 *   ... exists", which is misleading: the template exists, it just isn't
 *   visible to that user.
 *
 *   Templates are CONFIGURATION, not user data. Every portal user is
 *   meant to see the same set, so record-level sharing has nothing
 *   useful to say here.
 *
 * UPDATED - THE REAL BUG BEHIND "No TS Documents template named ... exists
 * yet" EVEN THOUGH THE TEMPLATE VISIBLY EXISTS:
 *   The original version of this class always SELECTed
 *   docb__Template_Name__c (ALT_NAME_FIELD) alongside Name. That field
 *   name was a guess made when this class was written and was never
 *   confirmed against the actual installed package schema. Your Template
 *   record's layout only shows "Document Template Name" (Name),
 *   "Default Document Name", Description, Google Account Id, Is Active?,
 *   Base object API, Output format, and GDoc Template Document Id - there
 *   is no separate "Template Name" field anywhere in that layout.
 *
 *   If docb__Template_Name__c does not exist on this object in your org,
 *   EVERY call to findByName()/listAll() throws a SOQL
 *   "No such column 'docb__Template_Name__c'" exception the moment it
 *   runs - before it ever gets to compare names. TSDocumentService.
 *   getReviewTarget() catches that exception and replaces it with the
 *   generic "No TS Documents template named ... exists yet" message,
 *   which is why the real cause was invisible.
 *
 *   This version builds its SELECT list dynamically from the object's
 *   actual field describe, silently dropping any field (like a guessed
 *   docb__Template_Name__c) that doesn't exist, instead of letting one
 *   bad guess break every lookup. hasField() lets TSDocumentService check
 *   before it reads an optional field off a returned row.
 *
 * WHY A TOP-LEVEL CLASS
 *   Apex forbids static methods on inner classes, so this cannot be
 *   nested inside TSDocumentService. Same reason
 *   PhaseDocumentPrivilegedUpdater is its own file.
 *
 * SECURITY
 *   This class is NOT an entry point - it has no @AuraEnabled methods and
 *   performs no DML. It only ever reads template configuration, and every
 *   caller passes a template name it already resolved. Do not add DML or
 *   an @AuraEnabled method here without revisiting that reasoning.
 */
public without sharing class TSTemplateSelector {
    private static final String TEMPLATE_OBJECT   = 'docb__Document_Builder__c';
    private static final String NAME_FIELD        = 'Name';
    private static final String ALT_NAME_FIELD    = 'docb__Template_Name__c';
    private static final String BASE_OBJECT_FIELD = 'docb__Base_object_API__c';
    private static final String ACTIVE_FIELD      = 'docb__Is_Active__c';
    private static final String OUTPUT_FIELD      = 'docb__Output_format__c';
    private static final String GDOC_ID_FIELD     = 'docb__GDoc_Template_Document_ID__c';
    private static final String DEFAULT_NAME_FLD  = 'docb__Default_File_Name__c';

    /** Every field the callers WOULD LIKE to query, preference order doesn't matter. */
    private static final List<String> WANTED_FIELDS = new List<String>{
        'Id', NAME_FIELD, ALT_NAME_FIELD, BASE_OBJECT_FIELD,
        ACTIVE_FIELD, OUTPUT_FIELD, GDOC_ID_FIELD, DEFAULT_NAME_FLD
    };

    /** Cached per-transaction so the describe call only happens once. */
    private static List<String> cachedSelectFields;

    /**
     * The subset of WANTED_FIELDS that actually exist on
     * docb__Document_Builder__c in this org. A field that was guessed
     * wrong (or belongs to a different package version) is skipped
     * instead of breaking every query that touches this object.
     */
    private static List<String> resolveSelectFields() {
        if (cachedSelectFields != null) {
            return cachedSelectFields;
        }
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(TEMPLATE_OBJECT);
        if (objType == null) {
            throw new TSTemplateSelectorException(
                'The object "' + TEMPLATE_OBJECT + '" does not exist or is not visible '
                + 'to the running user. Confirm the TS Documents package is installed '
                + 'and its object permissions are granted.'
            );
        }
        Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();
        List<String> resolved = new List<String>();
        List<String> missing = new List<String>();
        for (String f : WANTED_FIELDS) {
            if (f == 'Id' || fieldMap.containsKey(f.toLowerCase())) {
                resolved.add(f);
            } else {
                missing.add(f);
            }
        }
        if (!missing.isEmpty()) {
            System.debug(LoggingLevel.WARN,
                'TSTemplateSelector: these fields do not exist on ' + TEMPLATE_OBJECT
                + ' and were skipped - ' + String.join(missing, ', '));
        }
        cachedSelectFields = resolved;
        return resolved;
    }

    private static String selectList() {
        return String.join(resolveSelectFields(), ', ');
    }

    /** True when `fieldApiName` was actually included in the last query's SELECT list. */
    public static Boolean hasField(String fieldApiName) {
        return resolveSelectFields().contains(fieldApiName);
    }

    /**
     * One template by either of its name fields, active ones preferred.
     * Returns null when nothing matches - the caller decides what to say.
     * Only compares against ALT_NAME_FIELD when that field actually
     * exists on the object.
     */
    public static SObject findByName(String templateName) {
        if (String.isBlank(templateName)) {
            return null;
        }
        String whereClause = NAME_FIELD + ' = :templateName';
        if (hasField(ALT_NAME_FIELD)) {
            whereClause += ' OR ' + ALT_NAME_FIELD + ' = :templateName';
        }
        String orderBy = hasField(ACTIVE_FIELD) ? (ACTIVE_FIELD + ' DESC') : NAME_FIELD;
        String soql =
            'SELECT ' + selectList() +
            ' FROM ' + TEMPLATE_OBJECT +
            ' WHERE ' + whereClause +
            ' ORDER BY ' + orderBy +
            ' LIMIT 1';
        List<SObject> rows = Database.query(soql);
        return rows.isEmpty() ? null : rows[0];
    }

    /** Every template in the org. */
    public static List<SObject> listAll() {
        return Database.query(
            'SELECT ' + selectList() +
            ' FROM ' + TEMPLATE_OBJECT +
            ' ORDER BY ' + NAME_FIELD
        );
    }

    /** How many templates exist at all - used to explain a failed lookup. */
    public static Integer countAll() {
        return Database.countQuery('SELECT COUNT() FROM ' + TEMPLATE_OBJECT);
    }

    /** Names only, for diagnostics and for building a match index. */
    public static List<String> listNames() {
        List<String> names = new List<String>();
        for (SObject row : listAll()) {
            String name = (String) row.get(NAME_FIELD);
            if (String.isNotBlank(name)) {
                names.add(name);
            }
        }
        return names;
    }

    /**
     * Reads an optional field off a template row without throwing when
     * that field wasn't part of the SELECT list (because it doesn't
     * exist on the object). Use this - not row.get(...) directly - for
     * ALT_NAME_FIELD and DEFAULT_NAME_FLD everywhere they're read.
     */
    public static Object safeGet(SObject row, String fieldApiName) {
        if (row == null || !hasField(fieldApiName)) {
            return null;
        }
        try {
            return row.get(fieldApiName);
        } catch (Exception e) {
            return null;
        }
    }

    public class TSTemplateSelectorException extends Exception {}
}