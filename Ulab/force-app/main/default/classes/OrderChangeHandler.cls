public class OrderChangeHandler {

    public static void handleAfterUpdate(List<uLab_Order__c> newList, List<uLab_Order__c> oldList){

        System.debug('***OrderChangeTriggered***');

        final String eventType = 'sfdc.order.statusChanged'; 
        List<uLab_Order__c> ordersToUpdate = new List<uLab_Order__c>();
        List<sfdc_order_statusChanged__e> events = new List<sfdc_order_statusChanged__e>();

        // Collect Order Ids
        Set<Id> orderIds = new Set<Id>();
        for(uLab_Order__c ord : newList){
            orderIds.add(ord.Id);
        }

        // Query Assigned uAssistant details
        Map<Id,uLab_Order__c> orderMap = new Map<Id,uLab_Order__c>(
            [SELECT Id,
                    Assigned_uAssistant__r.FirstName,
                    Assigned_uAssistant__r.LastName
             FROM uLab_Order__c
             WHERE Id IN :orderIds]
        );

        for (Integer i = 0; i < newList.size(); i++) {

            uLab_Order__c newOrder = newList[i];
            uLab_Order__c oldOrder = oldList[i];
            uLab_Order__c orderWithUser = orderMap.get(newOrder.Id);

            System.debug('Send to WebApp: ' + newOrder.Send_to_WebApp__c);

            if (
                (newOrder.Send_to_WebApp__c == true && newOrder.uAssist_Status__c != oldOrder.uAssist_Status__c)
                ||
                (newOrder.Generate_PE_Manually__c == true && oldOrder.Generate_PE_Manually__c == false)
            ) {    
                System.debug('uAssist Status changed / Manual Trigger');

                // Status handling (case-safe)
                String status = newOrder.uAssist_Status__c != null 
                    ? newOrder.uAssist_Status__c.toLowerCase() 
                    : '';

                // Conditional mapping
                String onHoldMessage;

                if (status == 'cancel' || status == 'cancelled') {

                    onHoldMessage = newOrder.Order_Cancellation_Comments__c;

                } else if (status == 'rejected') {

                    onHoldMessage = newOrder.Order_Rejection_Comments__c;

                } else {

                    onHoldMessage = newOrder.On_Hold_Message__c;
                }

                sfdc_order_statusChanged__e eventObj = new sfdc_order_statusChanged__e(
                    eventType__c = eventType,
                    uLab_Acct_Number__c = newOrder.uLab_Acct_Number__c, 
                    order_id__c = newOrder.orderId__c,
                    RecordTypeId__c = newOrder.RecordTypeId,
                    uAssist_Status__c = newOrder.uAssist_Status__c,
                    uAssist_Status_Old__c = oldOrder.uAssist_Status__c,
                    Number_of_Plans__c = newOrder.Number_of_Plans__c,
                    Plan_1__c = newOrder.Plan_1__c,
                    Plan_2__c = newOrder.Plan_2__c,
                    Plan_3__c = newOrder.Plan_3__c,
                 // Record_Type_Name__c  =orderWithUser.RecordType.DeveloperName,

                    // Updated field
                    On_Hold_Message__c = onHoldMessage,

                    uAssistant_First_Name__c = orderWithUser.Assigned_uAssistant__r.FirstName,
                    uAssistant_Last_Name__c  = orderWithUser.Assigned_uAssistant__r.LastName,
                    Order_Cancellation_Comments__c = newOrder.Order_Cancellation_Comments__c,

                    Event_Processing_Sequence__c =
                        newOrder.Event_Processing_Sequence__c == null ? 1 :
                        newOrder.Event_Processing_Sequence__c
                );

                // Debug Payload
                System.debug('Payload -> ' + JSON.serializePretty(eventObj));

                events.add(eventObj);

                // Reset checkbox if manually triggered
                if (newOrder.Generate_PE_Manually__c == true) {
                    ordersToUpdate.add(
                        new uLab_Order__c(
                            Id = newOrder.Id,
                            Generate_PE_Manually__c = false
                        )
                    );
                }

                System.debug('New Order Platform Event added');
            }
        }

        // Debug all events
        System.debug('All Events Payload -> ' + JSON.serializePretty(events));

        List<Database.SaveResult> results = EventBus.publish(events);

        for (Database.SaveResult sr: results) {

            System.debug(sr);

            if (sr.isSuccess()) {
                System.debug('Successfully published event.');
            } else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Error returned: ' +
                        err.getStatusCode() +
                        ' - ' +
                        err.getMessage());
                }
            }
        }

        try{
            if(!ordersToUpdate.isEmpty()){
                update ordersToUpdate;
            }
        }
        catch(Exception e){
            System.debug('Error updating orders: ' + e.getMessage());
        }
    }
}