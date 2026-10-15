({
	 NpnTracking : function(cmp, event, helper) {
        var recordId = cmp.get("v.recordId");
        var npnNum = cmp.get("v.ContactFields.NPN_Num__c"); 
        var action = cmp.get("c.npnSearch");
         action.setParams({
            Ide: cmp.get("v.recordId")
          
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var result = JSON.parse(response.getReturnValue());
                if(result.status=="FIRM" || result.status=="INDIVIDUAL"){ 
             //  alert(result.status);
                }
                else{
               //     alert(result.status);
                  alert('NPN not found in NIPR');  
                }
                if(result.status=="FIRM" || result.status=="INDIVIDUAL"){ 
               var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Success',
                    message: 'DOI Records created successfully',
                    duration:' 5000',
                    key: 'info_alt',
                    type: 'success',
                    mode: 'pester'
                });
                toastEvent.fire();
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                 dismissActionPanel.fire();
               }
                
                 var dismissActionPanel = $A.get("e.force:closeQuickAction");
                 dismissActionPanel.fire();
            } else {
                alert('Invalid NPN Number');
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Failed',
                    message: 'Invalid NPN Number',
                    duration:' 5000',
                    key: 'info_alt',
                    type: 'error',
                    mode: 'pester'
                });
                toastEvent.fire();
                
                 var dismissActionPanel = $A.get("e.force:closeQuickAction");
                 dismissActionPanel.fire();
                
            }
        });
        $A.enqueueAction(action);
    }
})