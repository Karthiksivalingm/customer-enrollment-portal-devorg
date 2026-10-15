@istest
public class NIPRforFlow_Test {
    
       @isTest static void NiprContacthttpclass(){
     
         NIPRforFlow.FlowInputs fl = new NIPRforFlow.FlowInputs();
           
        String AgentRecordType = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Agent').getRecordTypeId();
           
           fl.Firstname ='Carmen';
           fl.Lastname='FREIRE';
           fl.ssn='593496845';
           fl.recordType = 'Agent';
           NIPRforFlow.FlowInputs[] Inputs = new NIPRforFlow.FlowInputs[]{fl};
                Test.startTest();
           Test.setMock(HttpCalloutMock.class, new NIPRforFlowHttp());
            Test.stopTest(); 
          NIPRforFlow.invokeThisMethod(Inputs); 
     }
   public class FlowInputs{
        public string ssn;
         public string Firstname;
        public string email;
         public string phone;
         public string Lastname;
        public string recordId;
         public string recordType;
    }

}