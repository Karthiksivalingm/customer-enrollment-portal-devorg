({
    submit : function(component, event, helper) {
         
     var recordId = component.get('v.recordId');
       var action = component.get("c.getmessagesfromapi");
          action.setParams({"recordide":recordId});
        component.set("v.showArrow", false);
       action.setCallback(this,function(response){
           var state = response.getState();
           
             if(state === "SUCCESS") {
                  var response = response.getReturnValue()
                  
                component.set("v.msg",response); 
                
             }
            
         });
        $A.enqueueAction(action);
                
    },
        handleChatScriptsLoaded: function(component, event, helper){
    	      window.setInterval(
            $A.getCallback(function() {
				
                 helper.scrollMethod(component, event, helper);
            }), 1000000
        );
	}
})