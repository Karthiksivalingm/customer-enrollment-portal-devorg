//Apex class from FND

public class OrderConfirmationController {
    public String isPDF { get; set; }
    public ID oppId { get; set; }
    public String dealershipName { get; set; }
    public String streetAddress { get; set; }
    public String city { get; set; }
    public String state { get; set; }
    public String ZipCode { get; set; }
    public String contactName { get; set; }
    public String contactEmail { get; set; }
    public String targetLaunchMonth { get; set; }
    public String regionalManager { get; set; }
    public String accountTechnician { get; set; }
    public String franchiseType { get; set; }
    public String addendum { get; set; }
    public String specialNotes { get; set; }
    public Decimal techFee { get; set; }
    public Date orderDate { get; set; }
    public Decimal total { get; set; }    
    public Boolean isError {get; set;}
    public List<OpportunityLineItem> lineItems {get;set;}
   	
    public OrderConfirmationController() {
        isError = false;
        isPDF  = ApexPages.currentPage().getParameters().get('renderAs');
        // Fetch the Opportunity and Product data
        Opportunity opp = [SELECT Id, Account.Name, Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode, 
                           Contract_Signer__c, Contract_Signer_Email__c, Target_Launch_Month__c, Regional_Performance_Manager__r.Name, 
                           Account_Technician__r.Name, OEM__c,Special_contract_notes__c
                           FROM Opportunity 
                           WHERE Id = :ApexPages.currentPage().getParameters().get('id') LIMIT 1];
        oppId=opp.Id;
        dealershipName = opp.Account.Name;
        streetAddress = opp.Account.BillingStreet;
        city = opp.Account.BillingCity;
        state = opp.Account.BillingState;
        ZipCode = opp.Account.BillingPostalCode;
        targetLaunchMonth = opp.Target_Launch_Month__c;
        regionalManager = opp.Regional_Performance_Manager__r.Name;
        accountTechnician = opp.Account_Technician__r.Name;
        franchiseType = opp.OEM__c;
        specialNotes = opp.Special_contract_notes__c;
        
      LIST<Contact> lstcon = [SELECT Id,AccountId, Name, Title__c, Email, Contact_Role__c
                                      from Contact 
                                      Where AccountId=:opp.AccountId AND Contact_Role__c includes ('Foundation Contract Signer') LIMIT 1];
        
       if(lstcon.isEmpty()){
           // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There is no Foundation Contract Signer role on this account. Please add Foundation Contract Signer and try agian'));
            isError = true;
            return;
        }
	

        contactName = lstcon[0].Name;
        contactEmail = lstcon[0].Email;
    
        
        // Fetch the Tech Fee from the related Product
        List<OpportunityLineItem> oplineItems = [SELECT Id, Name, Product2.Name,Contract_Product_Name__c, MRR__c, Product2.Addendum_Language__c FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
        if (!oplineItems.isEmpty()) {
            //techFee = lineItems[0].UnitPrice;
            lineItems = oplineItems;
            total = 0;
            for(OpportunityLineItem oli :oplineItems ){
                total = oli.MRR__c + total ;
            }
        }
        
    }
}