import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getGuestCategoryValues from '@salesforce/apex/GuestCategoryReportController.getGuestCategoryValues';

export default class GuestCategoryButtons extends NavigationMixin(LightningElement) {
    @api recordId; // Invitation__c (Event) record Id

    categories = [];
    error;

    @wire(getGuestCategoryValues)
    wiredValues({ data, error }) {
        if (data) {
            this.categories = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : error.message;
        }
    }

    get hasError() {
        return !!this.error;
    }

    handleClick(event) {
        const category = event.target.dataset.category;
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Guest_Category_Report' // API name of the custom Tab pointing to the report page
            },
            state: {
                c__eventId: this.recordId,
                c__category: category
            }
        });
    }
}