import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import EVENT_NAME_FIELD from '@salesforce/schema/Invitation__c.Name';

// The column key for the Event Name filter, confirmed via
// GET /services/data/v61.0/analytics/reports/<reportId>/describe
// (reportMetadata.reportFilters[2].column) on the DECLINED - LOCAL report.
// All 10 reports are built on the same Guest List report type, so this should be
// the same column on each — but if any report doesn't filter correctly, re-run the
// describe call for that specific report ID to confirm its column key matches.
const FILTER_COLUMN = 'Guest_List__c.Invitation__c';

const REPORTS = [
    { label: 'Confirmed - International',    reportId: '00OAe0000079MGgMAM' },
    { label: 'Confirmed - Local Guests',      reportId: '00OAe000006qoJpMAI' },
    { label: 'Declined - International',      reportId: '00OAe0000079Mi1MAE' },
    { label: 'Declined - Local',              reportId: '00OAe0000079OqHMAU' },
    { label: 'No Response - International',   reportId: '00OAe0000079N9RMAU' },
    { label: 'No Response - Local',           reportId: '00OAe0000079PCrMAM' },
    { label: 'Visited - International',       reportId: '00OAe0000079PETMA2' },
    { label: 'Visited - Local',               reportId: '00OAe0000079PRNMA2' },
    { label: 'Canceled - International',      reportId: '00OAe0000079PcfMAE' },
    { label: 'Canceled - Local',              reportId: '00OAe0000079glZMAQ' }
];

// Separate "Generate All" report, filtered by the event's record Id rather than by
// name — kept out of the REPORTS dropdown list since it isn't one of the selectable
// per-status/region reports.
const GENERATE_ALL_REPORT_ID = '00OAe000007PbLJMA0';

export default class EventReportButtons extends LightningElement {
    @api recordId;

    eventName;
    selectedReportId;

    @wire(getRecord, { recordId: '$recordId', fields: [EVENT_NAME_FIELD] })
    wiredRecord({ data, error }) {
        if (data) {
            this.eventName = data.fields.Name.value;
        } else if (error) {
            // eslint-disable-next-line no-console
            console.error('eventReportButtons: error loading Event Name', error);
        }
    }

    get reportOptions() {
        return REPORTS.map((r) => ({ label: r.label, value: r.reportId }));
    }

    get isGenerateDisabled() {
        return !this.selectedReportId;
    }

    handleReportChange(event) {
        this.selectedReportId = event.detail.value;
    }

    handleGenerateClick() {
        if (!this.selectedReportId) {
            return;
        }

        const value = this.eventName ? String(this.eventName) : '';

        const reportFilters = JSON.stringify([
            { column: FILTER_COLUMN, operator: 'equals', value }
        ]);

        const url = `/lightning/r/Report/${this.selectedReportId}/view?reportFilters=${encodeURIComponent(reportFilters)}`;

        // window.location.href can get intercepted by Lightning's internal router as an
        // in-app route change, reusing the already-open report component instead of doing a
        // real reload — which causes each click's filter to stack on top of the last one
        // instead of replacing it. Opening a NAMED tab forces a genuine full page load each
        // time (bypassing that router), while reusing the same browser tab across clicks.
        window.open(url, 'eventGuestListReportTab');
    }

    handleGenerateAllClick() {
        const value = this.eventName ? String(this.eventName) : '';

        const reportFilters = JSON.stringify([
            { column: FILTER_COLUMN, operator: 'equals', value }
        ]);

        const url = `/lightning/r/Report/${GENERATE_ALL_REPORT_ID}/view?reportFilters=${encodeURIComponent(reportFilters)}`;

        // Same named-tab approach as handleGenerateClick, for the same reason.
        window.open(url, 'eventGuestListReportTab');
    }
}