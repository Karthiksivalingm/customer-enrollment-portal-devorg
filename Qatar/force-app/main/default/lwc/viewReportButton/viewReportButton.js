import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import REPORT_FOLDER_ID from '@salesforce/label/c.Report_Folder_Id';

export default class ViewReportButton extends NavigationMixin(LightningElement) {
    handleClick() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/lightning/r/Folder/' + REPORT_FOLDER_ID + '/view?queryScope=userFolders'
            }
        });
    }
}