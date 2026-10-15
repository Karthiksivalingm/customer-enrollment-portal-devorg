public with sharing class GuestSourceReportController {

    // Source table columns — driven by Invitation_Status__c
    // 'None' added to bucket blank/null Invitation_Status__c values
    public static final List<String> STATUS_VALUES = new List<String>{
        'Bounced Email', 'No Response', 'Visited', 'Accepted', 'Declined', 'None'
    };

    // Location table columns — driven by Invitation_Status__c
    public static final List<String> LOCATION_STATUS_VALUES = new List<String>{
        'Bounced Email', 'No Response', 'Visited', 'Accepted', 'Declined', 'None'
    };

    public static final List<String> TIER_VALUES = new List<String>{
        'International Hosted', 'International Non-Hosted', 'Local'
    };

    // Registrant Status (RSVP__c) columns — used by the two new tables
    // 'None' added to bucket blank/null RSVP__c values
    public static final List<String> RSVP_VALUES = new List<String>{
        'Accepted', 'Rejected', 'Not Responded', 'Confirmed', 'Attended', 'Cancelled', 'None'
    };

    private static final String NONE_STATUS = 'None';

    @AuraEnabled(cacheable=true)
    public static ReportWrapper getReport(Id eventId) {
        ReportWrapper wrapper = new ReportWrapper();

        // ---- Header info ----
        Invitation__c evt = [
            SELECT Id, Name, LastModifiedDate
            FROM Invitation__c
            WHERE Id = :eventId
            LIMIT 1
        ];
        wrapper.eventName = evt.Name;
        wrapper.reportType = 'General Overview';

        // ---- Pull all guests for this event ----
        List<Guest_List__c> guests = [
            SELECT Id, Source__c, Invitation_Status__c, Guest_Tiers__c, RSVP__c, LastModifiedDate
            FROM Guest_List__c
            WHERE Invitation__c = :eventId
        ];

        // Report date = most recent LastModifiedDate among related guests (falls back to the Event's own date if none)
        Datetime latest = evt.LastModifiedDate;
        for (Guest_List__c g : guests) {
            if (g.LastModifiedDate > latest) {
                latest = g.LastModifiedDate;
            }
        }
        wrapper.reportDate = latest.format('MM/dd/yyyy');

        // ---- Build Source x Invitation Status pivot ----
        Map<String, Map<String, Integer>> sourceCounts = new Map<String, Map<String, Integer>>();
        Map<String, Integer> sourceStatusTotals = new Map<String, Integer>();
        for (String s : STATUS_VALUES) {
            sourceStatusTotals.put(s, 0);
        }

        // ---- Build Location x Invitation Status pivot ----
        Map<String, Map<String, Integer>> tierCounts = new Map<String, Map<String, Integer>>();
        Map<String, Integer> tierStatusTotals = new Map<String, Integer>();
        for (String s : LOCATION_STATUS_VALUES) {
            tierStatusTotals.put(s, 0);
        }

        // ---- Build Source x Registrant Status (RSVP__c) pivot ----
        Map<String, Map<String, Integer>> sourceRsvpCounts = new Map<String, Map<String, Integer>>();
        Map<String, Integer> sourceRsvpTotals = new Map<String, Integer>();
        for (String s : RSVP_VALUES) {
            sourceRsvpTotals.put(s, 0);
        }

        // ---- Build Guest Tier x Registrant Status (RSVP__c) pivot ----
        Map<String, Map<String, Integer>> tierRsvpCounts = new Map<String, Map<String, Integer>>();
        Map<String, Integer> tierRsvpTotals = new Map<String, Integer>();
        for (String s : RSVP_VALUES) {
            tierRsvpTotals.put(s, 0);
        }

        for (Guest_List__c g : guests) {
            String src = String.isBlank(g.Source__c) ? 'Unknown' : g.Source__c;
            // Blank/null Invitation_Status__c now buckets under 'None' instead of 'No Response'
            String invStatus = String.isBlank(g.Invitation_Status__c) ? NONE_STATUS : g.Invitation_Status__c;
            String tier = String.isBlank(g.Guest_Tiers__c) ? 'Unknown' : g.Guest_Tiers__c;
            // Blank/null RSVP__c now buckets under 'None' instead of being skipped
            String rsvpStatus = String.isBlank(g.RSVP__c) ? NONE_STATUS : g.RSVP__c;

            // Source x Invitation Status
            if (!sourceCounts.containsKey(src)) {
                Map<String, Integer> row = new Map<String, Integer>();
                for (String s : STATUS_VALUES) row.put(s, 0);
                sourceCounts.put(src, row);
            }
            if (sourceCounts.get(src).containsKey(invStatus)) {
                sourceCounts.get(src).put(invStatus, sourceCounts.get(src).get(invStatus) + 1);
                sourceStatusTotals.put(invStatus, sourceStatusTotals.get(invStatus) + 1);
            }

            // Location x Invitation Status
            if (!tierCounts.containsKey(tier)) {
                Map<String, Integer> row = new Map<String, Integer>();
                for (String s : LOCATION_STATUS_VALUES) row.put(s, 0);
                tierCounts.put(tier, row);
            }
            if (tierCounts.get(tier).containsKey(invStatus)) {
                tierCounts.get(tier).put(invStatus, tierCounts.get(tier).get(invStatus) + 1);
                tierStatusTotals.put(invStatus, tierStatusTotals.get(invStatus) + 1);
            }

            // Source x Registrant Status (RSVP__c) — no longer skipped when blank;
            // blank guests are now counted under the 'None' column.
            if (!sourceRsvpCounts.containsKey(src)) {
                Map<String, Integer> row = new Map<String, Integer>();
                for (String s : RSVP_VALUES) row.put(s, 0);
                sourceRsvpCounts.put(src, row);
            }
            if (sourceRsvpCounts.get(src).containsKey(rsvpStatus)) {
                sourceRsvpCounts.get(src).put(rsvpStatus, sourceRsvpCounts.get(src).get(rsvpStatus) + 1);
                sourceRsvpTotals.put(rsvpStatus, sourceRsvpTotals.get(rsvpStatus) + 1);
            }

            // Guest Tier x Registrant Status (RSVP__c)
            if (!tierRsvpCounts.containsKey(tier)) {
                Map<String, Integer> row = new Map<String, Integer>();
                for (String s : RSVP_VALUES) row.put(s, 0);
                tierRsvpCounts.put(tier, row);
            }
            if (tierRsvpCounts.get(tier).containsKey(rsvpStatus)) {
                tierRsvpCounts.get(tier).put(rsvpStatus, tierRsvpCounts.get(tier).get(rsvpStatus) + 1);
                tierRsvpTotals.put(rsvpStatus, tierRsvpTotals.get(rsvpStatus) + 1);
            }
        }

        // ---- Assemble Source rows (Invitation Status) ----
        List<String> sourceKeys = new List<String>(sourceCounts.keySet());
        sourceKeys.sort();
        for (String src : sourceKeys) {
            wrapper.sourceRows.add(buildRow(src, sourceCounts.get(src), STATUS_VALUES));
        }
        wrapper.sourceTotalRow = buildRow('Total', sourceStatusTotals, STATUS_VALUES);

        // ---- Assemble Location rows (fixed order: International Hosted, International Non-Hosted, Local) ----
        for (String tier : TIER_VALUES) {
            if (tierCounts.containsKey(tier)) {
                wrapper.tierRows.add(buildRow(tier, tierCounts.get(tier), LOCATION_STATUS_VALUES));
            }
        }
        for (String tier : tierCounts.keySet()) {
            if (!TIER_VALUES.contains(tier)) {
                wrapper.tierRows.add(buildRow(tier, tierCounts.get(tier), LOCATION_STATUS_VALUES));
            }
        }
        wrapper.tierTotalRow = buildRow('Total', tierStatusTotals, LOCATION_STATUS_VALUES);

        // ---- Assemble Source rows (Registrant Status) ----
        List<String> sourceRsvpKeys = new List<String>(sourceRsvpCounts.keySet());
        sourceRsvpKeys.sort();
        for (String src : sourceRsvpKeys) {
            wrapper.sourceRsvpRows.add(buildRow(src, sourceRsvpCounts.get(src), RSVP_VALUES));
        }
        wrapper.sourceRsvpTotalRow = buildRow('Total', sourceRsvpTotals, RSVP_VALUES);

        // ---- Assemble Guest Tier rows (Registrant Status, fixed tier order) ----
        for (String tier : TIER_VALUES) {
            if (tierRsvpCounts.containsKey(tier)) {
                wrapper.tierRsvpRows.add(buildRow(tier, tierRsvpCounts.get(tier), RSVP_VALUES));
            }
        }
        for (String tier : tierRsvpCounts.keySet()) {
            if (!TIER_VALUES.contains(tier)) {
                wrapper.tierRsvpRows.add(buildRow(tier, tierRsvpCounts.get(tier), RSVP_VALUES));
            }
        }
        wrapper.tierRsvpTotalRow = buildRow('Total', tierRsvpTotals, RSVP_VALUES);

        wrapper.statusColumns = STATUS_VALUES;
        wrapper.locationStatusColumns = LOCATION_STATUS_VALUES;
        wrapper.rsvpStatusColumns = RSVP_VALUES;

        return wrapper;
    }

    private static PivotRow buildRow(String label, Map<String, Integer> counts, List<String> columns) {
        PivotRow row = new PivotRow();
        row.label = label;
        for (String s : columns) {
            row.values.add(counts.containsKey(s) ? counts.get(s) : 0);
        }
        return row;
    }

    public class ReportWrapper {
        @AuraEnabled public String eventName;
        @AuraEnabled public String reportType;
        @AuraEnabled public String reportDate;
        @AuraEnabled public List<String> statusColumns = new List<String>();
        @AuraEnabled public List<String> locationStatusColumns = new List<String>();
        @AuraEnabled public List<String> rsvpStatusColumns = new List<String>();
        @AuraEnabled public List<PivotRow> sourceRows = new List<PivotRow>();
        @AuraEnabled public PivotRow sourceTotalRow;
        @AuraEnabled public List<PivotRow> tierRows = new List<PivotRow>();
        @AuraEnabled public PivotRow tierTotalRow;
        @AuraEnabled public List<PivotRow> sourceRsvpRows = new List<PivotRow>();
        @AuraEnabled public PivotRow sourceRsvpTotalRow;
        @AuraEnabled public List<PivotRow> tierRsvpRows = new List<PivotRow>();
        @AuraEnabled public PivotRow tierRsvpTotalRow;
    }

    public class PivotRow {
        @AuraEnabled public String label;
        @AuraEnabled public List<Integer> values = new List<Integer>();
    }
}