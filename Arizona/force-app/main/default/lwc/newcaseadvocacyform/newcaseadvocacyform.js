import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

// recordId is provided automatically when this component sits
// on a Case record detail page in Experience Builder
const FIELDS = ['Case.Status', 'Case.CaseNumber'];

const AUTO_DISMISS_DELAY = 5000; // 5 seconds

export default class CaseNewStatusBanner extends LightningElement {
    @api recordId;

    status;
    caseNumber;
    isDismissed = false;

    autoDismissTimeout;
    hasStartedTimer = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredCase({ data, error }) {
        if (data) {
            this.status = data.fields.Status.value;
            this.caseNumber = data.fields.CaseNumber.value;

            // Start the auto-dismiss timer only once, the first time
            // we know the banner is actually going to show
            if (this.status === 'New' && !this.hasStartedTimer) {
                this.startAutoDismissTimer();
            }
        } else if (error) {
            // eslint-disable-next-line no-console
            console.error('Error loading case record', error);
        }
    }

    startAutoDismissTimer() {
        this.hasStartedTimer = true;
        this.autoDismissTimeout = setTimeout(() => {
            this.isDismissed = true;
        }, AUTO_DISMISS_DELAY);
    }

    get showBanner() {
        return this.status === 'New' && !this.isDismissed;
    }

    closeBanner() {
        this.isDismissed = true;
        this.clearAutoDismissTimer();
    }

    clearAutoDismissTimer() {
        if (this.autoDismissTimeout) {
            clearTimeout(this.autoDismissTimeout);
            this.autoDismissTimeout = undefined;
        }
    }

    disconnectedCallback() {
        this.clearAutoDismissTimer();
    }
}