import { LightningElement, api, wire } from 'lwc';
import getExpirationAlerts from '@salesforce/apex/ExpirationAlertController.getExpirationAlerts';

export default class ExpirationAlerts extends LightningElement {
    @api recordId;

    isLoading = true;
    errorMessage;
    alerts = [];

    @wire(getExpirationAlerts, { contactId: '$recordId' })
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
            expired: { icon: 'utility:error', variant: 'error', rowClass: 'alert-row alert-row_expired' },
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

    get hasAlerts() {
        return this.alerts.length > 0;
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

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((e) => e.message).join(', ');
        }
        return error?.body?.message || error?.message || 'An unknown error occurred.';
    }
}