public class LogisticsPDF {
    public Meeting_Request__c meetingRequest {get;set;}
    Public LogisticsPDF(){
        Id meetingRequestId = ApexPages.currentPage().getParameters().get('id');
       
        meetingRequest=[select Name,Requested_By__c,Meeting__c,MeetingVirtual__c,Car_Plate_Number_1__c,Car_Plate_Number_2__c,Car_Plate_Number_3__c,Car_Plate_Number_4__c,Car_Plate_Number_5__c,Car_Plate_Number_6__c,Car_Plate_Number_7__c,Car_Plate_Number_8__c,Car_Plate_Number_9__c,Car_Plate_Number_10__c from Meeting_Request__c where id=:meetingRequestId];
    }
}