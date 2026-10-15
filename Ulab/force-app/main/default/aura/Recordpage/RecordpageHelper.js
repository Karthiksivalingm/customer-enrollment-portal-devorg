({
    scrollMethod : function(component, event, helper) {
        
        jQuery(document).ready(function(){
            $('.msg_card_body').scrollTop($('.msg_card_body').prop("scrollHeight"));
            
        });
    }
})