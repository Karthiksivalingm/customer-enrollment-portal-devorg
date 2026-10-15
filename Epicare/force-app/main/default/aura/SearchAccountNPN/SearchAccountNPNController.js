({
    NpnTracking : function(cmp, event, helper) {
        var recordId = cmp.get("v.recordId");
        var npnNum = cmp.get("v.accountFields.NPN__c"); // Replace with actual field API name

        var action = cmp.get("c.npnSearch");
        action.setParams({
            Ide: recordId,
            NpnNum: npnNum
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = JSON.parse(response.getReturnValue());

                if (result.status === 'FIRM' || result.status === 'INDIVIDUAL') {
                    if (result.doiRecordsCreated) {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title: 'Success',
                            message: 'DOI Records created successfully',
                            duration: 5000,
                            key: 'info_alt',
                            type: 'success',
                            mode: 'pester'
                        });
                        toastEvent.fire();
                    } else {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title: 'Info',
                            message: 'NPN found, but no DOI records created',
                            duration: 5000,
                            key: 'info_alt',
                            type: 'info',
                            mode: 'pester'
                        });
                        toastEvent.fire();
                    }
                } else {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title: 'Warning',
                        message: result.message || 'NPN not found or invalid',
                        duration: 5000,
                        key: 'warning',
                        type: 'warning',
                        mode: 'dismissible'
                    });
                    toastEvent.fire();
                }

                $A.get("e.force:closeQuickAction").fire();
            } else {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title: 'Failed',
                    message: 'Callout failed or invalid NPN Number',
                    duration: 5000,
                    key: 'info_alt',
                    type: 'error',
                    mode: 'pester'
                });
                toastEvent.fire();

                $A.get("e.force:closeQuickAction").fire();
            }
        });

        // Enqueue the action
        $A.enqueueAction(action);
    }
})