import { LightningElement, api, wire } from 'lwc';
import getExpirationAlerts from '@salesforce/apex/AccountExpirationAlertController.getExpirationAlerts';

export default class AccountExpirationAlerts extends LightningElement {

    @api recordId;

    isLoading = true;
    error;

    groupedAlerts = [];

    @wire(getExpirationAlerts, { accountId: '$recordId' })
    wiredAlerts({ error, data }) {

        this.isLoading = false;

        if (data) {

            this.error = undefined;
            this.groupedAlerts = this.buildGroups(data);

        }
        else if (error) {

            this.groupedAlerts = [];
            this.error = this.reduceError(error);

        }

    }

    buildGroups(alerts) {

        const groups = {};

        alerts.forEach(alert => {

            if (!groups[alert.groupName]) {

                groups[alert.groupName] = {
                    name: alert.groupName,
                    alerts: []
                };

            }

            groups[alert.groupName].alerts.push(
                this.buildRow(alert)
            );

        });

        return Object.values(groups);

    }

    buildRow(alert) {

        let rowClass = 'alert-row';

        if (alert.severity === 'critical') {

            rowClass += ' alert-row_critical';

        }
        else if (alert.severity === 'warning') {

            rowClass += ' alert-row_warning';

        }

        return {

            ...alert,

            rowClass,

            formattedDate: this.formatDate(alert.expirationDate),

            showAuthorization:

                alert.groupName === 'Authorizations',

            showPCSP:

                alert.groupName === 'PCSP'

        };

    }

    formatDate(dateValue) {

        if (!dateValue) {
            return '';
        }

        const date = new Date(dateValue);

        return date.toLocaleDateString();

    }

    reduceError(error) {

        if (Array.isArray(error.body)) {

            return error.body
                .map(e => e.message)
                .join(', ');

        }

        return error.body?.message || error.message;

    }

    get hasAlerts() {

        return this.groupedAlerts.length > 0;

    }

}