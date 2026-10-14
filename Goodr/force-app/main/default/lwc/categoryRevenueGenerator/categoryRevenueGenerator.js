import { LightningElement, track } from 'lwc';
import recalculateRevenue from '@salesforce/apex/CategoryRevenueGenerator.generateCategoryRevenueForAllStoresWithChanges';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RevenueRecalcButton extends LightningElement {

    handleClick() {
        recalculateRevenue()
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Top stores recalculated successfully.',
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message || 'An error occurred',
                        variant: 'error'
                    })
                );
            });
    }
}