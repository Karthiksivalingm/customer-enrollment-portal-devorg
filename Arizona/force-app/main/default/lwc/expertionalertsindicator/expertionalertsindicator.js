import { LightningElement, wire } from 'lwc';
import getExpirationAlertsForCurrentUser from '@salesforce/apex/ExpirationAlertController.getExpirationAlertsForCurrentUser';

export default class ExpirationAlertsIndicator extends LightningElement {
    isLoading = true;
    errorMessage;
    alerts = [];

    // Tracks whether the person has closed the popup this page load.
    // Once dismissed it won't reappear until they navigate away and
    // back / refresh - same one-time-nudge pattern as the record-page
    // modal, just without the click-to-open badge step.
    dismissed = false;

    @wire(getExpirationAlertsForCurrentUser)
    wiredAlerts({ data, error }) {
        this.isLoading = false;

        if (data) {
            this.alerts = data.map((alert) => this.buildRow(alert));
            this.errorMessage = undefined;
        } else if (error) {
            this.errorMessage = this.reduceError(error);
            this.alerts = [];
        }
    }

    buildRow(alert) {
        const iconByStatus = {
            expired: { icon: 'utility:ban', variant: 'error', rowClass: 'alert-row alert-row_expired' },
            critical: { icon: 'utility:warning', variant: 'warning', rowClass: 'alert-row alert-row_critical' },
            warning: { icon: 'utility:warning', variant: 'warning', rowClass: 'alert-row alert-row_warning' }
        };
        const visuals = iconByStatus[alert.severity] || iconByStatus.warning;

        return {
            ...alert,
            iconName: visuals.icon,
            iconVariant: visuals.variant,
            rowClass: visuals.rowClass,
            formattedDate: this.formatDate(alert.expirationDate)
        };
    }

    formatDate(isoDate) {
        if (!isoDate) {
            return '';
        }
        const [year, month, day] = isoDate.split('-');
        return `${month}/${day}/${year}`;
    }

    // Modal opens automatically once data resolves to something worth
    // showing (an error, or at least one alert) AND the person hasn't
    // dismissed it. No click required - it deliberately does NOT open
    // just because isLoading is true, so contacts with nothing expiring
    // never see a flash-then-vanish popup.
    get showModal() {
        if (this.dismissed) {
            return false;
        }
        return !!this.errorMessage || this.alerts.length > 0;
    }

    get certificationAlerts() {
        return this.alerts.filter((a) => a.groupName === 'certification');
    }

    get documentAlerts() {
        return this.alerts.filter((a) => a.groupName === 'document');
    }

    get serviceAlerts() {
        return this.alerts.filter((a) => a.groupName === 'service');
    }

    get hahAlerts() {
        return this.alerts.filter((a) => a.groupName === 'hah');
    }

    handleClose() {
        this.dismissed = true;
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((e) => e.message).join(', ');
        }
        return error?.body?.message || error?.message || 'An unknown error occurred.';
    }
}