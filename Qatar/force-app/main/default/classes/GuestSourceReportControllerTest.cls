@isTest
private class GuestSourceReportControllerTest {

    private static Invitation__c createEvent() {
        Invitation__c evt = new Invitation__c(
            Name = 'Source Report Event',
            Event_Start_Date__c = Date.today(),
            Event_End_Date__c = Date.today().addDays(1)
        );
        insert evt;
        return evt;
    }

    private static Contact createContact(String lastName) {
        Contact c = new Contact(LastName = lastName);
        insert c;
        return c;
    }

    private static Guest_List__c buildGuest(Id eventId, Id contactId, String source, String invitationStatus,
                                             String tier, String rsvp) {
        return new Guest_List__c(
            Invitation__c = eventId,
            Contact__c = contactId,
            Source__c = source,
            Invitation_Status__c = invitationStatus,
            Guest_Tiers__c = tier,
            RSVP__c = rsvp
        );
    }

    @isTest
    static void testGetReportBuildsAllPivotTables() {
        Invitation__c evt = createEvent();

        String status1 = GuestSourceReportController.STATUS_VALUES[0];   // e.g. 'Bounced Email'
        String status2 = GuestSourceReportController.STATUS_VALUES[3];   // e.g. 'Accepted'
        String tier1 = GuestSourceReportController.TIER_VALUES[0];       // 'International Hosted'
        String tier2 = GuestSourceReportController.TIER_VALUES[2];       // 'Local'
        String rsvp1 = GuestSourceReportController.RSVP_VALUES[0];       // 'Accepted'
        String rsvp2 = GuestSourceReportController.RSVP_VALUES[2];       // 'Not Responded'

        // One Contact per guest so each Guest_List__c satisfies the required Contact__c field.
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 6; i++) {
            contacts.add(new Contact(LastName = 'Guest ' + i));
        }
        insert contacts;

        List<Guest_List__c> guests = new List<Guest_List__c>{
            // Known source/tier, counted in every applicable pivot
            buildGuest(evt.Id, contacts[0].Id, 'Website', status1, tier1, rsvp1),
            buildGuest(evt.Id, contacts[1].Id, 'Website', status2, tier1, rsvp1),
            buildGuest(evt.Id, contacts[2].Id, 'Referral', status1, tier2, rsvp2),

            // Blank source/tier -> should fall back to 'Unknown'
            buildGuest(evt.Id, contacts[3].Id, null, status1, null, rsvp1),

            // Blank invitation status -> should fall back to 'None' (not 'No Response')
            buildGuest(evt.Id, contacts[4].Id, 'Website', null, tier1, rsvp1),

            // Blank RSVP -> should fall back to 'None' (counted, not skipped)
            buildGuest(evt.Id, contacts[5].Id, 'Website', status1, tier1, null)
        };
        insert guests;

        Test.startTest();
        GuestSourceReportController.ReportWrapper wrapper = GuestSourceReportController.getReport(evt.Id);
        Test.stopTest();

        System.assertEquals('Source Report Event', wrapper.eventName);
        System.assertEquals('General Overview', wrapper.reportType);
        System.assertNotEquals(null, wrapper.reportDate);

        // ---- Source x Invitation Status ----
        Map<String, GuestSourceReportController.PivotRow> sourceRowsByLabel = rowsByLabel(wrapper.sourceRows);
        System.assert(sourceRowsByLabel.containsKey('Website'));
        System.assert(sourceRowsByLabel.containsKey('Referral'));
        System.assert(sourceRowsByLabel.containsKey('Unknown'), 'Blank source should roll up under Unknown.');

        Integer status1Index = GuestSourceReportController.STATUS_VALUES.indexOf(status1);
        Integer status2Index = GuestSourceReportController.STATUS_VALUES.indexOf(status2);
        Integer noResponseIndex = GuestSourceReportController.STATUS_VALUES.indexOf('No Response');
        Integer noneIndex = GuestSourceReportController.STATUS_VALUES.indexOf('None');

        System.assert(noneIndex >= 0, 'STATUS_VALUES should contain a None column.');

        // Website has: status1 (x2, including the null-RSVP guest), status2 (x1),
        // and one guest with a blank Invitation_Status__c -> counted under 'None'.
        System.assertEquals(2, sourceRowsByLabel.get('Website').values[status1Index]);
        System.assertEquals(1, sourceRowsByLabel.get('Website').values[status2Index]);
        System.assertEquals(1, sourceRowsByLabel.get('Website').values[noneIndex]);
        System.assertEquals(0, sourceRowsByLabel.get('Website').values[noResponseIndex],
            'Blank Invitation_Status__c should NOT be counted under No Response.');

        // Total row should sum all guests (6) across the status columns
        Integer sourceTotalSum = 0;
        for (Integer v : wrapper.sourceTotalRow.values) {
            sourceTotalSum += v;
        }
        System.assertEquals(6, sourceTotalSum);

        // ---- Location (Tier) x Invitation Status ----
        Map<String, GuestSourceReportController.PivotRow> tierRowsByLabel = rowsByLabel(wrapper.tierRows);
        System.assert(tierRowsByLabel.containsKey(tier1));
        System.assert(tierRowsByLabel.containsKey(tier2));
        System.assert(tierRowsByLabel.containsKey('Unknown'), 'Blank tier should roll up under Unknown.');

        // Fixed order check: TIER_VALUES entries should appear before any ad-hoc tier labels
        System.assertEquals(tier1, wrapper.tierRows[0].label);

        // ---- Source x Registrant Status (RSVP), blank RSVP now counted under 'None' ----
        Map<String, GuestSourceReportController.PivotRow> sourceRsvpByLabel = rowsByLabel(wrapper.sourceRsvpRows);
        Integer rsvpNoneIndex = GuestSourceReportController.RSVP_VALUES.indexOf('None');
        System.assert(rsvpNoneIndex >= 0, 'RSVP_VALUES should contain a None column.');
        System.assertEquals(1, sourceRsvpByLabel.get('Website').values[rsvpNoneIndex],
            'Blank RSVP__c should be counted under the None column, not skipped.');

        Integer rsvpTotal = 0;
        for (GuestSourceReportController.PivotRow row : wrapper.sourceRsvpRows) {
            for (Integer v : row.values) {
                rsvpTotal += v;
            }
        }
        // All 6 guests should now be counted (including the blank-RSVP guest under 'None')
        System.assertEquals(6, rsvpTotal);

        // ---- Guest Tier x Registrant Status (RSVP) ----
        Integer tierRsvpTotal = 0;
        for (GuestSourceReportController.PivotRow row : wrapper.tierRsvpRows) {
            for (Integer v : row.values) {
                tierRsvpTotal += v;
            }
        }
        System.assertEquals(6, tierRsvpTotal);

        // ---- Column metadata echoed back ----
        System.assertEquals(GuestSourceReportController.STATUS_VALUES, wrapper.statusColumns);
        System.assertEquals(GuestSourceReportController.LOCATION_STATUS_VALUES, wrapper.locationStatusColumns);
        System.assertEquals(GuestSourceReportController.RSVP_VALUES, wrapper.rsvpStatusColumns);
    }

    @isTest
    static void testGetReportWithNoGuestsReturnsOnlyTotals() {
        Invitation__c evt = createEvent();

        Test.startTest();
        GuestSourceReportController.ReportWrapper wrapper = GuestSourceReportController.getReport(evt.Id);
        Test.stopTest();

        System.assertEquals(0, wrapper.sourceRows.size());
        System.assertEquals(0, wrapper.tierRows.size());
        System.assertEquals(0, wrapper.sourceRsvpRows.size());
        System.assertEquals(0, wrapper.tierRsvpRows.size());

        for (Integer v : wrapper.sourceTotalRow.values) {
            System.assertEquals(0, v);
        }
    }

    @isTest
    static void testReportDateUsesMostRecentGuestModification() {
        Invitation__c evt = createEvent();
        Contact c = createContact('Recency Guest');
        Guest_List__c g = buildGuest(evt.Id, c.Id, 'Website',
            GuestSourceReportController.STATUS_VALUES[0],
            GuestSourceReportController.TIER_VALUES[0],
            GuestSourceReportController.RSVP_VALUES[0]);
        insert g;

        Test.startTest();
        GuestSourceReportController.ReportWrapper wrapper = GuestSourceReportController.getReport(evt.Id);
        Test.stopTest();

        System.assertEquals(Datetime.now().format('MM/dd/yyyy'), wrapper.reportDate);
    }

    @isTest
    static void testBlankInvitationStatusAndRsvpBucketUnderNone() {
        Invitation__c evt = createEvent();
        Contact c = createContact('None Bucket Guest');

        // Both Invitation_Status__c and RSVP__c blank -> both should land in 'None'
        Guest_List__c g = buildGuest(evt.Id, c.Id, 'Website', null,
            GuestSourceReportController.TIER_VALUES[0], null);
        insert g;

        Test.startTest();
        GuestSourceReportController.ReportWrapper wrapper = GuestSourceReportController.getReport(evt.Id);
        Test.stopTest();

        Integer statusNoneIndex = GuestSourceReportController.STATUS_VALUES.indexOf('None');
        Integer rsvpNoneIndex = GuestSourceReportController.RSVP_VALUES.indexOf('None');

        Map<String, GuestSourceReportController.PivotRow> sourceRowsByLabel = rowsByLabel(wrapper.sourceRows);
        Map<String, GuestSourceReportController.PivotRow> sourceRsvpByLabel = rowsByLabel(wrapper.sourceRsvpRows);

        System.assertEquals(1, sourceRowsByLabel.get('Website').values[statusNoneIndex],
            'Blank Invitation_Status__c should be counted under None.');
        System.assertEquals(1, sourceRsvpByLabel.get('Website').values[rsvpNoneIndex],
            'Blank RSVP__c should be counted under None.');
    }

    private static Map<String, GuestSourceReportController.PivotRow> rowsByLabel(
        List<GuestSourceReportController.PivotRow> rows) {
        Map<String, GuestSourceReportController.PivotRow> result = new Map<String, GuestSourceReportController.PivotRow>();
        for (GuestSourceReportController.PivotRow row : rows) {
            result.put(row.label, row);
        }
        return result;
    }
}