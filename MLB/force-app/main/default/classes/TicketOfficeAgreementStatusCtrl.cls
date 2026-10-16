/**
 * Shared controller for the Ticket Office email components (TicketOfficeAgreementStatus,
 * TicketOfficeAgreementSummary, TicketOfficeLogo) used by the Ticket_Office_Agreement_Details template.
 * - Status: read from the Opportunity's most recently modified Adobe Sign agreement - the one whose
 *   status change triggered the notification.
 * - Summary: agreement value and the per-type key figures, including Membership seat/parking totals.
 * - Logo: public URL of the externally available Marlins_Logo document.
 */
public without sharing class TicketOfficeAgreementStatusCtrl {

    public Id opportunityId { get; set; }

    private echosign_dev1__SIGN_Agreement__c agreement;
    private Boolean agreementLoaded = false;
    private Opportunity opp;

    // ---------------------------------------------------------------- Status

    private echosign_dev1__SIGN_Agreement__c getAgreement() {
        if (!agreementLoaded && opportunityId != null) {
            List<echosign_dev1__SIGN_Agreement__c> rows = [
                SELECT Name, echosign_dev1__Status__c
                FROM echosign_dev1__SIGN_Agreement__c
                WHERE echosign_dev1__Opportunity__c = :opportunityId
                ORDER BY LastModifiedDate DESC
                LIMIT 1
            ];
            agreement = rows.isEmpty() ? null : rows[0];
            agreementLoaded = true;
        }
        return agreement;
    }

    public String getAdobeStatus() {
        echosign_dev1__SIGN_Agreement__c a = getAgreement();
        return a == null || String.isBlank(a.echosign_dev1__Status__c) ? 'Unknown' : a.echosign_dev1__Status__c;
    }

    public String getAgreementName() {
        echosign_dev1__SIGN_Agreement__c a = getAgreement();
        return a == null ? '' : a.Name;
    }

    public String getStatusLabel() {
        switch on getAdobeStatus() {
            when 'Out for Approval' { return 'Sent for Sales Manager approval'; }
            when 'Out for Signature', 'Approved' { return 'Approved by Sales Manager'; }
            when 'Signed' { return 'Signed by customer'; }
            when 'Cancelled / Declined' { return 'Agreement declined'; }
            when else { return getAdobeStatus(); }
        }
    }

    public String getStatusNote() {
        switch on getAdobeStatus() {
            when 'Out for Approval' { return 'Agreement value is $50,000 or more.'; }
            when 'Out for Signature', 'Approved' { return 'Released to the customer for signature.'; }
            when 'Signed' { return 'Agreement complete. Executed copy follows from Adobe Sign.'; }
            when 'Cancelled / Declined' { return 'Please confirm next steps with the Sales Rep.'; }
            when else { return 'Agreement status updated in Adobe Sign.'; }
        }
    }

    /** HTML entity for the status icon. */
    public String getStatusIcon() {
        switch on getAdobeStatus() {
            when 'Out for Approval' { return '&#10148;'; }
            when 'Out for Signature', 'Approved' { return '&#10004;'; }
            when 'Signed' { return '&#9733;'; }
            when 'Cancelled / Declined' { return '&#10006;'; }
            when else { return '&#8226;'; }
        }
    }

    public String getStatusColor() {
        switch on getAdobeStatus() {
            when 'Out for Approval' { return '#E08600'; }
            when 'Out for Signature', 'Approved' { return '#0E8A4F'; }
            when 'Signed' { return '#0083B8'; }
            when 'Cancelled / Declined' { return '#EF3340'; }
            when else { return '#41748D'; }
        }
    }

    public String getStatusTint() {
        switch on getAdobeStatus() {
            when 'Out for Approval' { return '#FFF4E0'; }
            when 'Out for Signature', 'Approved' { return '#E5F6EC'; }
            when 'Signed' { return '#EAF7FD'; }
            when 'Cancelled / Declined' { return '#FDEBED'; }
            when else { return '#EEF4F7'; }
        }
    }

    // ---------------------------------------------------------------- Summary

    public class SummaryColumn {
        public String label { get; private set; }
        public String value { get; private set; }
        public Boolean primary { get; private set; }
        SummaryColumn(String label, String value, Boolean primary) {
            this.label = label;
            this.value = String.isBlank(value) ? '—' : value;
            this.primary = primary;
        }
    }

    private Opportunity getOpp() {
        if (opp == null && opportunityId != null) {
            List<Opportunity> rows = [
                SELECT Agreement_Type__c, Total_MembershipPrice__c, This_Season_Total_Amount__c,
                       Total_Multi_Product__c, Total_Flex_Membership__c, Payment_Type__c, Payment_Plan__c,
                       Amount_allocated_to_Flex__c, Amount_allocated_to_Suites__c, Amount_allocated_to_Groups__c,
                       Suite_Number__c, Total_Tickets_in_Suite__c, Total_of_Games__c
                FROM Opportunity
                WHERE Id = :opportunityId
            ];
            opp = rows.isEmpty() ? null : rows[0];
        }
        return opp;
    }

    public List<SummaryColumn> getSummaryColumns() {
        List<SummaryColumn> cols = new List<SummaryColumn>();
        Opportunity o = getOpp();
        if (o == null) {
            return cols;
        }
        switch on o.Agreement_Type__c {
            when 'Membership' {
                cols.add(new SummaryColumn('AGREEMENT VALUE', money(o.Total_MembershipPrice__c), true));
                cols.add(new SummaryColumn('PAYMENT PLAN', o.Payment_Type__c, false));
                Decimal seats = 0, parking = 0;
                for (Membership_Agreement__c m : [
                    SELECT Plan_Type__c, Qty_Seats__c, Plan_Type_Parking__c, Qty_Parking__c
                    FROM Membership_Agreement__c
                    WHERE Opportunity_LUR__c = :o.Id
                ]) {
                    if (String.isNotBlank(m.Plan_Type__c) && m.Qty_Seats__c != null) {
                        seats += m.Qty_Seats__c;
                    }
                    if (String.isNotBlank(m.Plan_Type_Parking__c) && m.Qty_Parking__c != null) {
                        parking += m.Qty_Parking__c;
                    }
                }
                cols.add(new SummaryColumn('SEATS', String.valueOf(seats.intValue()), false));
                cols.add(new SummaryColumn('PARKING', String.valueOf(parking.intValue()), false));
            }
            when 'Suite Lease' {
                cols.add(new SummaryColumn('AGREEMENT VALUE', money(o.This_Season_Total_Amount__c), true));
                cols.add(new SummaryColumn('SUITE', String.isBlank(o.Suite_Number__c) ? null : '#' + o.Suite_Number__c, false));
                cols.add(new SummaryColumn('TICKETS', o.Total_Tickets_in_Suite__c, false));
                cols.add(new SummaryColumn('GAMES', o.Total_of_Games__c, false));
            }
            when 'Multi-Product' {
                cols.add(new SummaryColumn('AGREEMENT VALUE', money(o.Total_Multi_Product__c), true));
                cols.add(new SummaryColumn('FLEX', money(o.Amount_allocated_to_Flex__c), false));
                cols.add(new SummaryColumn('SUITES', money(o.Amount_allocated_to_Suites__c), false));
                cols.add(new SummaryColumn('GROUPS', money(o.Amount_allocated_to_Groups__c), false));
            }
            when 'Flex' {
                cols.add(new SummaryColumn('AGREEMENT VALUE', money(o.Total_Flex_Membership__c), true));
                cols.add(new SummaryColumn('PAYMENT PLAN', o.Payment_Plan__c, false));
            }
        }
        return cols;
    }

    /** $#,##0.00 formatting, independent of the running user's locale. */
    @TestVisible
    private static String money(Decimal amount) {
        if (amount == null) {
            return null;
        }
        Decimal rounded = amount.setScale(2, RoundingMode.HALF_UP);
        Boolean negative = rounded < 0;
        String digits = String.valueOf(rounded.abs());
        String whole = digits.substringBefore('.');
        String cents = digits.substringAfter('.');
        String grouped = '';
        while (whole.length() > 3) {
            grouped = ',' + whole.right(3) + grouped;
            whole = whole.left(whole.length() - 3);
        }
        return (negative ? '-' : '') + '$' + whole + grouped + '.' + cents;
    }

    // ---------------------------------------------------------------- Logo

    /** Public URL of the externally available Marlins_Logo document, or blank if it is missing. */
    public String getLogoUrl() {
        List<Document> docs = [SELECT Id FROM Document WHERE DeveloperName = 'Marlins_Logo' LIMIT 1];
        if (docs.isEmpty()) {
            return '';
        }
        return Url.getOrgDomainUrl().toExternalForm() + '/servlet/servlet.ImageServer?id=' + docs[0].Id
            + '&oid=' + UserInfo.getOrganizationId();
    }
}