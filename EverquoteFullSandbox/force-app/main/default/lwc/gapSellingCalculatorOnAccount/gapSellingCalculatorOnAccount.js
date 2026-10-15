import { LightningElement,wire,api,track } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import DOLLAR_OF_PREMIUM_LAST_MONTH from '@salesforce/schema/Account.Dollar_of_Premium_last_month__c';
import AVG_PREMIUM_LAST_MONTH from '@salesforce/schema/Account.Avg_per_premium_last_month__c';
import DESIRED_PREMIUM from '@salesforce/schema/Account.Desired_amount_of_premium__c';
import BIND_RATE from '@salesforce/schema/Account.Bind_Rate__c';
import GAP_IN_PREMIUM from '@salesforce/schema/Account.GAP_IN_Premium__c';
import GAP_POLICIES from '@salesforce/schema/Account.GAP_Policies__c';
import ESTIMATED_LEADS_PER_DAY from '@salesforce/schema/Account.Estimated_of_leads_per_day__c';
import ESTIMATED_LEADS_PER_MONTH from '@salesforce/schema/Account.Estimated_of_leads_per_month__c';
import ESTIMATED_COST_PER_WEEK from '@salesforce/schema/Account.Estimated_cost_of_leads_per_WEEK__c';
import ESTIMATED_COST_PER_MONTH from '@salesforce/schema/Account.Estimated_cost_of_leads_per_MONTH__c';
import AUTO_PREMIUM from '@salesforce/schema/Account.Auto_Premium__c';
import AUTO_PREFERRED from '@salesforce/schema/Account.Auto_Preferred__c';
import AUTO_STANDARD from '@salesforce/schema/Account.Auto_Standard__c';
import AUTO_NON_STANDARD from '@salesforce/schema/Account.Auto_Non_Standard__c';
import FINAL_EXPENSE from '@salesforce/schema/Account.Final_Expense__c';
import HOME_PREMIUM from '@salesforce/schema/Account.Home_Premium__c';
import HOME_BASIC from '@salesforce/schema/Account.Home_Basic__c';
import POLICIES_LAST_MONTH from '@salesforce/schema/Account.Number_of_policies_bound_last_month__c';
import AVG_POLICY_LAST_MONTH from '@salesforce/schema/Account.Avg_of_each_policy_last_month__c';
import DESIRED_POLICIES from '@salesforce/schema/Account.Desired_of_policies_each_month__c';
//import LAST_COMPLETED_BY from '@salesforce/schema/Account.Last_Completed_By_ISR__c';
//import LAST_COMPLETED_DATE from '@salesforce/schema/Account.Last_Completed_Date__c';

const FIELDS = [
    DOLLAR_OF_PREMIUM_LAST_MONTH,
    AVG_PREMIUM_LAST_MONTH,
    DESIRED_PREMIUM,
    BIND_RATE,
    GAP_IN_PREMIUM,
    GAP_POLICIES,
    ESTIMATED_LEADS_PER_DAY,
    ESTIMATED_LEADS_PER_MONTH,
    ESTIMATED_COST_PER_WEEK,
    ESTIMATED_COST_PER_MONTH,
    AUTO_PREMIUM,
    AUTO_PREFERRED,
    AUTO_STANDARD,
    AUTO_NON_STANDARD,
    FINAL_EXPENSE,
    HOME_PREMIUM,
    HOME_BASIC,
    POLICIES_LAST_MONTH,
    AVG_POLICY_LAST_MONTH,
    DESIRED_POLICIES
    //LAST_COMPLETED_BY,
    //LAST_COMPLETED_DATE
];
export default class GapSellingCalculatorOnAccount extends LightningElement {
 @api recordId;
    @track showPremium = false;
    @track showSpinner = false;
    @track showPolicy = false;
    @track value = '';

    // Tracking Account fields
    @track premiumLastMonth = 0;
    @track avgPremiumLastMonth = 0;
    @track desiredPremium = 0;
    @track bindRate = 0;
    @track policiesLastMonth = 0;
    @track avgPolicyLastMonth = 0;
    @track desiredPolicies = 0;
    @track autoPremium = 0;
    @track autoPreferred = 0;
    @track autoStandard = 0;
    @track autoNonStandard = 0;
    @track finalExpense = 0;
    @track homePremium = 0;
    @track homeBasic = 0;
    //@track lastCompletedBy ;
    //@track lastCompletedDate ;
    // formatlastCompletedDate ;

    // Calculated fields
    @track gapPremium = 0;
    @track gapPolicies = 0;
    @track estimatedLeadsPerDay = 0;
    @track estimatedLeadsPerMonth = 0;
    @track estimatedCostPerWeek = 0;
    @track estimatedCostPerMonth = 0;
    @track isModalOpen = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredAccount({ error, data }) {
        if (data) {
            this.account = data;
            this.setFieldValues();
        } else if (error) {
            this.error = error;
            this.account = undefined;
        }
    }

    get options() {
        return [
            { label: 'Premium ($$)', value: 'Premium' },
            { label: 'Number of Policies', value: 'Policies' }
        ];
    }

    setFieldValues() {
        this.premiumLastMonth = getFieldValue(this.account, DOLLAR_OF_PREMIUM_LAST_MONTH) || 0;
        this.avgPremiumLastMonth = getFieldValue(this.account, AVG_PREMIUM_LAST_MONTH) || 0;
        this.desiredPremium = getFieldValue(this.account, DESIRED_PREMIUM) || 0;
        this.bindRate = getFieldValue(this.account, BIND_RATE) || 0;
        this.policiesLastMonth = getFieldValue(this.account, POLICIES_LAST_MONTH) || 0;
        this.avgPolicyLastMonth = getFieldValue(this.account, AVG_POLICY_LAST_MONTH) || 0;
        this.desiredPolicies = getFieldValue(this.account, DESIRED_POLICIES) || 0;
        this.autoPremium = getFieldValue(this.account, AUTO_PREMIUM) || 0;
        this.autoPreferred = getFieldValue(this.account, AUTO_PREFERRED) || 0;
        this.autoStandard = getFieldValue(this.account, AUTO_STANDARD) || 0;
        this.autoNonStandard = getFieldValue(this.account, AUTO_NON_STANDARD) || 0;
        this.finalExpense = getFieldValue(this.account, FINAL_EXPENSE) || 0;
        this.homePremium = getFieldValue(this.account, HOME_PREMIUM) || 0;
        this.homeBasic = getFieldValue(this.account, HOME_BASIC) || 0;
        //this.lastCompletedBy = getFieldValue(this.account, LAST_COMPLETED_BY) || '';
        //this.lastCompletedDate = getFieldValue(this.account, LAST_COMPLETED_DATE) || ''; 
        //this.formatDateTime(this.lastCompletedDate);
        this.calculateValues();
    }

    calculateValues() {
        this.gapPremium = this.showPremium
            ? this.desiredPremium - this.premiumLastMonth
            : (this.desiredPolicies - this.policiesLastMonth) * this.avgPolicyLastMonth;
        this.gapPremium = this.gapPremium.toFixed(2) || 0;
        this.gapPolicies = this.showPremium
            ? (this.desiredPremium - this.premiumLastMonth) / this.avgPremiumLastMonth
            : this.desiredPolicies - this.policiesLastMonth;
        this.gapPolicies = this.gapPolicies.toFixed(2) || 0;
        this._estimatedLeadsPerMonth = (this.gapPolicies / this.bindRate) * 100;
        this.estimatedLeadsPerMonth = parseFloat(this._estimatedLeadsPerMonth.toFixed(2)|| 0);
        this.estimatedLeadsPerDay = this.estimatedLeadsPerMonth / 20;
        this.estimatedLeadsPerDay = this.estimatedLeadsPerDay || 0;
        const costs = [
            this.autoPremium,
            this.autoPreferred,
            this.autoStandard,
            this.autoNonStandard,
            this.finalExpense,
            this.homePremium,
            this.homeBasic
        ].filter(cost => cost !== 0);

        const sum = costs.reduce((acc, curr) => acc + parseFloat(curr), 0);
        const averageCost = costs.length ? sum / costs.length : 0;

        this.estimatedLeadsPerDay = parseFloat(this.estimatedLeadsPerDay).toFixed(2);
        this.estimatedCostPerMonth = (averageCost * this._estimatedLeadsPerMonth).toFixed(2);
        this.estimatedCostPerWeek = (this.estimatedCostPerMonth / 4).toFixed(2);
    }

    handleChange(event) {
        this.value = event.detail.value;
        this.showPremium = this.value === 'Premium';
        this.showPolicy = !this.showPremium;
        this.calculateValues();
    }

    handleInputChange(event) {
        const field = event.target.dataset.id;
        this[field] = parseFloat(event.target.value) || 0;
        this.calculateValues();
    }

    handleSave() {
        this.showSpinner = true;
        console.log('this.premiumLastMonth---162--',this.premiumLastMonth);
        const fields = {
            Id: this.recordId,
            [DOLLAR_OF_PREMIUM_LAST_MONTH.fieldApiName]: this.premiumLastMonth,
            [AVG_PREMIUM_LAST_MONTH.fieldApiName]: this.avgPremiumLastMonth,
            [DESIRED_PREMIUM.fieldApiName]: this.desiredPremium,
            [POLICIES_LAST_MONTH.fieldApiName]: this.policiesLastMonth,
            [AVG_POLICY_LAST_MONTH.fieldApiName]: this.avgPolicyLastMonth,
            [DESIRED_POLICIES.fieldApiName]: this.desiredPolicies,
            [BIND_RATE.fieldApiName]: this.bindRate,
            [ESTIMATED_LEADS_PER_DAY.fieldApiName]: this.estimatedLeadsPerDay,
            [ESTIMATED_LEADS_PER_MONTH.fieldApiName]: this.estimatedLeadsPerMonth,
            [ESTIMATED_COST_PER_WEEK.fieldApiName]: this.estimatedCostPerWeek,
            [ESTIMATED_COST_PER_MONTH.fieldApiName]: this.estimatedCostPerMonth,
            [AUTO_PREMIUM.fieldApiName]: this.autoPremium,
            [AUTO_PREFERRED.fieldApiName]: this.autoPreferred,
            [AUTO_STANDARD.fieldApiName]: this.autoStandard,
            [AUTO_NON_STANDARD.fieldApiName]: this.autoNonStandard,
            [FINAL_EXPENSE.fieldApiName]: this.finalExpense,
            [HOME_PREMIUM.fieldApiName]: this.homePremium,
            [HOME_BASIC.fieldApiName]: this.homeBasic
        };

        const recordInput = { fields };
        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Record updated successfully',
                        variant: 'success'
                    })
                );
                this.showSpinner = false;
                return refreshApex(this.account);
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
                this.showSpinner = false;
            });
    }
    clearAndSaveRecord(){
          const inputFields = this.template.querySelectorAll(
       'lightning-input'
      );
   if (inputFields) {
       inputFields.forEach(field => {
           field.value=0;
       });
   }
            this.premiumLastMonth=0,
            this.avgPremiumLastMonth=0,
            this.desiredPremium=0,
            this.policiesLastMonth=0,
            this.avgPolicyLastMonth=0,
            this.desiredPolicies=0,
            this.bindRate=0,
            this.estimatedLeadsPerDay=0,
            this.estimatedLeadsPerMonth=0,
            this.estimatedCostPerWeek=0,
            this.estimatedCostPerMonth=0,
            this.autoPremium=0,
            this.autoPreferred=0,
            this.autoStandard=0,
            this.autoNonStandard=0,
            this.finalExpense=0,
            this.homePremium=0,
            this.homeBasic=0
      this.handleSave();
     
    }
    handleReset(event) {
        this.isModalOpen = true;       
    }
    okModalAction() {
        this.isModalOpen = false;
        this.clearAndSaveRecord();
    }
    cancelModalAction() {
        this.isModalOpen = false;
    }
     /*formatDateTime(dateTimeString) {
       // Create a new Date object from the input string
        const date = new Date(dateTimeString);

        // Format date as DD/MM/YYYY
        const day = String(date.getUTCDate()).padStart(2, '0');
        const month = String(date.getUTCMonth() + 1).padStart(2, '0'); // Months are zero-based
        const year = date.getUTCFullYear();

        // Format time as HH:MM AM/PM
        let hours = date.getUTCHours();
        const minutes = String(date.getUTCMinutes()).padStart(2, '0');
        const ampm = hours >= 12 ? 'PM' : 'AM';
        hours = hours % 12;
        hours = hours ? hours : 12; // The hour '0' should be '12'
        const strTime = hours + ':' + minutes + ' ' + ampm;

        // Combine date and time
       // this.formatlastCompletedDate = `${month}/${day}/${year} ${strTime}`;
    }*/
}