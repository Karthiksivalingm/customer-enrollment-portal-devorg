({
    handleClick : function(component, event, helper) {
        debugger;
        var action = component.get('c.callBatch');
      action.setParams({ companyId : component.get('v.recordId')
                       
                       });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == 'SUCCESS'){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "success",
                    "title": "Success!",
                    "message": "The Job has been successfully initiated."
                });
                toastEvent.fire();
            }
            
        });
        $A.enqueueAction(action);
    }
})