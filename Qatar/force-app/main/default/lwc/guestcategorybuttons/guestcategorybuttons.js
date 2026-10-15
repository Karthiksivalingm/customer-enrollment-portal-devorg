import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getGuestTierValues from '@salesforce/apex/GuestCategoryReportController.getGuestTierValues';
import getRegistrationStatusValues from '@salesforce/apex/GuestCategoryReportController.getRegistrationStatusValues';

const ALL_TIER_OPTION = { label: 'All Tiers', value: 'ALL' };
const ALL_STATUS_OPTION = { label: 'All Statuses', value: 'ALL' };

export default class GuestCategoryButtons extends NavigationMixin(LightningElement) {
    @api recordId; // Invitation__c (Event) record Id

    tierOptions = [];
    statusOptions = [];
    selectedTier;
    selectedStatus;
    generateAll = false;
    error;

    // "All Tiers" / "All Statuses" are added as a selectable option in each dropdown
    // (rather than only through the "Generate All" checkbox) so a tier and a status
    // can be picked independently — e.g. tier = "Local" with status = "All Statuses".
    // The Apex layer already treats the literal "ALL" value the same as no filter for
    // that field, so no changes are needed there.
    @wire(getGuestTierValues)
    wiredTiers({ data, error }) {
        if (data) {
            this.tierOptions = [ALL_TIER_OPTION, ...data.map((v) => ({ label: v, value: v }))];
        } else if (error) {
            this.error = error.body ? error.body.message : error.message;
        }
    }

    @wire(getRegistrationStatusValues)
    wiredStatuses({ data, error }) {
        if (data) {
            this.statusOptions = [ALL_STATUS_OPTION, ...data.map((v) => ({ label: v, value: v }))];
        } else if (error) {
            this.error = error.body ? error.body.message : error.message;
        }
    }

    get hasError() {
        return !!this.error;
    }

    get isGenerateDisabled() {
        if (this.generateAll) {
            return false;
        }
        return !this.selectedTier || !this.selectedStatus;
    }

    handleGenerateAllToggle(event) {
        this.generateAll = event.detail.checked;
        if (this.generateAll) {
            this.selectedTier = undefined;
            this.selectedStatus = undefined;
        }
    }

    handleTierChange(event) {
        this.selectedTier = event.detail.value;
    }

    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
    }

    handleGenerate() {
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Guest_Category_Report'
            },
            state: {
                c__eventId: this.recordId,
                c__tier: this.generateAll ? 'ALL' : this.selectedTier,
                c__status: this.generateAll ? 'ALL' : this.selectedStatus
            }
        });
    }
}