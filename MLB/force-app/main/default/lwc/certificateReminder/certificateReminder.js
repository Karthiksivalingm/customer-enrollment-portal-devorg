import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CertificateUploadModal from 'c/certificateUploadModal';

import ACCOUNT_TYPE from '@salesforce/schema/Contact.Account.Type';
import AGREEMENT_STATUS from '@salesforce/schema/Contact.Agreement_Status__c';
import COI_COLLECTED from '@salesforce/schema/Contact.COI_Collected__c';
import FOOD_COLLECTED from '@salesforce/schema/Contact.Food_Services_Certificate_Collected__c';
import W9_COLLECTED from '@salesforce/schema/Contact.W_9_Collected__c';
import RECORD_TYPE from '@salesforce/schema/Contact.RecordType.DeveloperName';

const FIELDS = [ACCOUNT_TYPE, AGREEMENT_STATUS, COI_COLLECTED, FOOD_COLLECTED, W9_COLLECTED, RECORD_TYPE];
const VENDOR_RECORD_TYPE = 'Vendor_Contact';

// Certificates per Account.Type - matches the Upload Certificate flow. Optional ones can be uploaded but are not required.
const REQUIRED = {
    'Food and Beverage': ['FOOD', 'W9'],
    'Non-Profit': ['COI'],
    'Sales Activation': ['COI']
};
const OPTIONAL = {
    'Food and Beverage': [],
    'Non-Profit': ['W9'],
    'Sales Activation': ['W9']
};
const CERTIFICATES = {
    COI: { label: 'Certificate of Insurance (COI)', field: COI_COLLECTED },
    FOOD: { label: 'Food Service Certificate', field: FOOD_COLLECTED },
    W9: { label: 'W-9', field: W9_COLLECTED }
};

export default class CertificateReminder extends LightningElement {
    @api recordId;

    record;
    toastShown = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredContact({ data }) {
        if (data) {
            this.record = data;
            this.announceMissingCertificates();
        }
    }

    get accountType() {
        return this.record ? getFieldValue(this.record, ACCOUNT_TYPE) : null;
    }

    get isVendor() {
        return (
            Boolean(this.record) &&
            getFieldValue(this.record, RECORD_TYPE) === VENDOR_RECORD_TYPE &&
            Boolean(this.accountType && REQUIRED[this.accountType])
        );
    }

    get certificates() {
        if (!this.isVendor) {
            return [];
        }
        const build = (key, optional) => {
            const collected = getFieldValue(this.record, CERTIFICATES[key].field) === true;
            let stateLabel = 'Pending';
            if (collected) {
                stateLabel = 'Uploaded';
            } else if (optional) {
                stateLabel = 'Optional';
            }
            return {
                key,
                label: CERTIFICATES[key].label,
                collected,
                optional,
                icon: collected ? 'utility:success' : optional ? 'utility:add' : 'utility:clock',
                variant: collected ? 'success' : optional ? null : 'warning',
                stateLabel,
                itemClass: 'cert' + (collected ? ' cert_done' : optional ? ' cert_optional' : ' cert_pending')
            };
        };
        return [
            ...REQUIRED[this.accountType].map((key) => build(key, false)),
            ...(OPTIONAL[this.accountType] || []).map((key) => build(key, true))
        ];
    }

    /** Required certificates not yet uploaded. */
    get missing() {
        return this.certificates.filter((c) => !c.optional && !c.collected);
    }

    get hasMissing() {
        return this.missing.length > 0;
    }

    /** Optional certificates not yet uploaded - offered once the required ones are in. */
    get optionalOpen() {
        return this.certificates.filter((c) => c.optional && !c.collected);
    }

    get showOptionalUpload() {
        return !this.hasMissing && this.optionalOpen.length > 0;
    }

    get optionalUploadLabel() {
        return 'Upload ' + this.optionalOpen.map((c) => c.label).join(' / ') + ' (optional)';
    }

    get allUploaded() {
        return this.isVendor && this.missing.length === 0;
    }

    get agreementStatus() {
        return (this.record && getFieldValue(this.record, AGREEMENT_STATUS)) || 'Document Pending';
    }

    get bannerClass() {
        return 'banner ' + (this.allUploaded ? 'banner_done' : 'banner_pending');
    }

    get bannerIcon() {
        return this.allUploaded ? 'utility:success' : 'utility:warning';
    }

    get bannerTitle() {
        if (this.allUploaded) {
            return 'All required certificates are uploaded';
        }
        const n = this.missing.length;
        return `${n} certificate${n === 1 ? '' : 's'} still needed for this ${this.accountType} vendor`;
    }

    get bannerSubtitle() {
        return this.allUploaded
            ? 'This vendor is ready for the agreement step.'
            : 'Upload the certificates below to move this contact forward.';
    }

    get statusClass() {
        switch (this.agreementStatus) {
            case 'Document Uploaded':
            case 'Signed':
                return 'pill pill_done';
            case 'Ready to Send':
            case 'Draft':
            case 'Pre-Send':
            case 'Send in Progress':
            case 'Created':
            case 'Out for Approval':
            case 'Approved':
            case 'Out for Signature':
                return 'pill pill_ready';
            case 'Cancelled / Declined':
            case 'Expired':
                return 'pill pill_declined';
            default:
                return 'pill pill_pending';
        }
    }

    announceMissingCertificates() {
        if (this.toastShown || !this.isVendor || this.allUploaded) {
            return;
        }
        this.toastShown = true;
        const names = this.missing.map((c) => c.label);
        const list = names.length > 1 ? names.slice(0, -1).join(', ') + ' and ' + names[names.length - 1] : names[0];
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Certificates required',
                message: `Please upload the ${list} for this ${this.accountType} vendor.`,
                variant: 'warning',
                mode: 'dismissible'
            })
        );
    }

    async handleUpload() {
        const result = await CertificateUploadModal.open({
            size: 'medium',
            label: 'Upload Certificate',
            recordId: this.recordId
        });
        if (result === 'finished') {
            await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
        }
    }
}
