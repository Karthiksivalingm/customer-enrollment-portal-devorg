({

  originalLead: {}, // holds the lead parameters for the referral leads

  formatPhone: function (phoneStr) {
    phoneStr = phoneStr || "";
    var digitsOnlyPhone = phoneStr.replace(/\D/g, "");

    if (digitsOnlyPhone.length < 10) {
      return "";
    }

    digitsOnlyPhone = digitsOnlyPhone.slice(digitsOnlyPhone.length - 10);
    return "+1" + digitsOnlyPhone;
  },

  validateLeadData: function (leadData) {
    var errors = [];
    var requiredFields = [
      ["FirstName", "FirstName"],
      ["LastName", "LastName"],
      ["Gender__c", "Gender"],
      ["Date_of_Birth__c", "Date of Birth"],
      ["Street", "Street"],
      ["City", "City"],
      ["State", "State"],
      ["PostalCode", "Postal Code"],
      ["Phone", "Phone"],
      ["Email", "Email"],
      ["Major_Condition_Past_Year__c", "Major Condition Past Year"],
      ["Oda_New_Lead_Source__c", "New Lead Source"]
    ];

    var fieldIsPresent = function (field) {
      var fieldName = field[0];
      var fieldDisplayName = field[1];
      var fieldValue = leadData[fieldName];
      if (!fieldValue || fieldValue.length === 0) {
        errors.push("You must have a value for " + fieldDisplayName + ".");
      }
    };
    requiredFields.forEach(fieldIsPresent);

    if (!!leadData.State && leadData.State.length !== 2) {
      errors.push("Please use the 2 letter abbreviation for the state.");
    }

    if (!!leadData.Date_of_Birth__c && !leadData.Date_of_Birth__c.match(/^\d{4}-\d+-\d+$/)) {
      errors.push("Please enter the Date of Birth in mm/dd/yyyy format. ");
    }

    return errors;
  },

  showErrors: function (errors) {
    errors.forEach(function (err) {
      var toastEvent = $A.get("e.force:showToast");
      toastEvent.setParams({
        mode: "dismissible",
        type: "error",
        message: err
      });
      toastEvent.fire();
    });
  }
});