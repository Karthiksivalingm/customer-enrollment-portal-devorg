public class WrapperContactTenure {
	public Contact contact { get; set; }
    public Account account { get; set; }
    public Integer tenure { get; set; }
    
    public WrapperContactTenure(Contact c, Account a) {
        contact = c;
        account = a;
        if(a.Wizard_Complete_Date__c != null){
	        tenure = (Date.today().year() - a.Wizard_Complete_Date__c.year()) * 12 + Date.today().month() - a.Wizard_Complete_Date__c.month();            
        }
    }
}