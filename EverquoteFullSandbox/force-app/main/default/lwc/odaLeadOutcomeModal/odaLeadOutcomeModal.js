import findPolicies from "@salesforce/apex/ODAPolicyController.findPolicies";
import savePolicies from "@salesforce/apex/ODAPolicyController.savePolicies";
import { showToastNotification, toastVariant } from "c/fireNotification";
import { api, LightningElement, track } from "lwc";

export default class OdaLeadOutcomeModal extends LightningElement {
  @track loading = false;
  @track policies = [this.defaultPolicy()];

  @api leadId;

  _isOpen = false;
  @api
  get isOpen() {
    return this._isOpen;
  }

  set isOpen(value) {
    this._isOpen = value;
    if (this._isOpen) {
      this.loadPolicies();
    }
  }

  loadPolicies() {
    this.loading = true;
    findPolicies({ leadId: this.leadId })
      .then((result) => {
        if (result.length > 0) {
          this.policies = result.map((policy) => {
            let uiPolicy = {
              componentId: policy.Id,
              id: policy.Id,
              carrier: policy.Carrier__c,
              product: policy.Product__c,
              quoteId: policy.Quote_Id__c,
              coverageAmount: policy.Coverage_Amount__c,
              manuallyAdded: false,
              riskClass: null
            };

            return uiPolicy;
          });
        }
      })
      .catch((err) => {})
      .finally(() => {
        this.loading = false;
      });
  }

  defaultPolicy() {
    return {
      componentId: Date.now(),
      manuallyAdded: true
    };
  }

  get policyCanBeRemoved() {
    if (this.policies.length > 1) {
      return true;
    } else {
      return false;
    }
  }

  addPolicy() {
    this.policies.push(this.defaultPolicy());
  }

  handlePolicyUpdated(event) {
    let data = event.detail;
    let index = this.policies.findIndex((policy) => policy.componentId === data.componentId);
    this.policies[index] = data;
  }

  validPolicies() {
    let validatedPolicies = [];
    this.policies.forEach((policy) => {
      policy.validate = true;
      validatedPolicies.push({ ...policy });
    });

    this.policies = validatedPolicies;

    let invalidPolicy = this.policies.find((policy) => !!policy.valid === false);
    return invalidPolicy === undefined || invalidPolicy === null;
  }

  save() {
    this.validPolicies();
    this.loading = true;
    setTimeout(() => {
      let invalidPolicy = this.policies.find((policy) => !!policy.valid === false);
      if (!!invalidPolicy) {
        showToastNotification(
          this,
          "",
          "Please make sure that policies details are correctly fill in",
          toastVariant.warning
        );
        this.loading = false;
        return;
      }

      savePolicies({
        leadId: this.leadId,
        policiesDto: this.policies
      })
        .then((resultString) => {
          let result = JSON.parse(resultString);

          if (result.failing_policies.length > 0) {
            this.handleFailingPolicies(result.failing_policies);
          } else {
            this.dispatchCloseEvent();
          }
        })
        .catch((err) => {
          showToastNotification(this, "", err.body.message, toastVariant.error);
        })
        .finally(() => {
          this.loading = false;
        });
    }, 500);
  }

  handleFailingPolicies(failingPolicies) {
    // remove successfully updated policies
    this.policies = this.policies.filter((policy) =>
      this.policyInList(
        policy,
        failingPolicies.map((failing) => failing.policy)
      )
    );

    // show error message for each failing policy
    failingPolicies.forEach((item) => {
      let policy = item.policy;
      showToastNotification(
        this,
        `Error occurred while saving policy ${policy.policyNumber} for ${policy.carrier} - ${policy.product}`,
        item.error,
        toastVariant.error
      );
    });
  }

  policyInList(policy, failingPolicies) {
    let existingPolicy = failingPolicies.find(
      (failingPolicy) =>
        failingPolicy.id === policy.id ||
        (failingPolicy.carrier === policy.carrier &&
          failingPolicy.product === policy.product &&
          failingPolicy.policyNumber === policy.policyNumber &&
          failingPolicy.quoteId === policy.quoteId &&
          failingPolicy.coverageAmount === policy.coverageAmount &&
          failingPolicy.cannotGetPolicyNumber === policy.cannotGetPolicyNumber &&
          failingPolicy.recordingWasPaused === policy.recordingWasPaused)
    );
    return !!existingPolicy;
  }

  cancel() {
    const closedEvent = new CustomEvent("cancel");
    this.dispatchEvent(closedEvent);
    this.resetFields();
  }

  handleRemovePolicy(event) {
    const componentId = event.target.dataset.id;
    const index = this.policies.findIndex((policy) => policy.componentId == componentId);
    this.policies.splice(index, 1);
  }

  dispatchCloseEvent() {
    let policiesWithoutPolicyNumber = this.policies.filter(
      (policy) => policy.cannotGetPolicyNumber === true
    );
    let missingPolicyNumbers = policiesWithoutPolicyNumber.length >= 1;
    let totalPolicyCount = this.policies.length;

    const closedEvent = new CustomEvent("modalclosed", {
      detail: {
        totalPolicyCount: totalPolicyCount,
        missingPolicyNumbers: missingPolicyNumbers
      }
    });
    this.dispatchEvent(closedEvent);
    this.resetFields();
  }

  resetFields() {
    this.policies = [this.defaultPolicy()];
  }
}