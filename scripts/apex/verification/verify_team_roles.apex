// LIVE CHECK - all changes ROLLED BACK by the exception at the end (nothing is saved).
public class StopAndRollbackException extends Exception {}
List<String> out = new List<String>();
Integer seq = Integer.valueOf(Math.mod(Datetime.now().getTime(), 100000));
Id companyRt = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Company').getRecordTypeId();
List<List<String>> scen = new List<List<String>>{
    new List<String>{'Key Account','Enterprise'}, new List<String>{'Key Account','Strategic'},
    new List<String>{'Key Account','Development'}, new List<String>{'Key Account','Discount'},
    new List<String>{'Specialty','Planned'}, new List<String>{'Specialty','Self Service'},
    new List<String>{'Partnerships','Partnerships'}, new List<String>{'Global','Distributor'} };
List<Account> accs = new List<Account>(); List<Lead> leads = new List<Lead>(); Integer i = 0;
for (List<String> s : scen) { i++;
    accs.add(new Account(Name = 'QA MAP Acc ' + i + ' ' + seq, RecordTypeId = companyRt, Tax_Id__c = String.valueOf(700000000 + seq * 10 + i),
        BillingStreet = '1 Test St', BillingCity = 'Los Angeles', BillingState = 'CA', BillingPostalCode = '90001', BillingCountry = 'US',
        Sales_Channel__c = s[0], Sector__c = s[1]));
    leads.add(new Lead(FirstName = 'QA', LastName = 'MAP Lead ' + i, Company = 'QA MAP Lead Co ' + i, Email = 'qamap' + i + '_' + seq + '@testdomain.com',
        Tax_ID__c = String.valueOf(800000000 + seq * 10 + i), Terms_of_Service_Agreement__c = 'I agree', Has_Physical_Store__c = true,
        Resale_Certificate_Status__c = 'Yes, I do.', Status = 'New', Sales_Channel__c = s[0], Sector__c = s[1])); }
insert accs; insert leads;
List<Contact> cons = new List<Contact>(); List<Opportunity> opps = new List<Opportunity>(); i = 0;
for (Account a : accs) { i++;
    cons.add(new Contact(FirstName = 'QA', LastName = 'MAP Con ' + i, AccountId = a.Id, Email = 'qamapc' + i + '_' + seq + '@testdomain.com'));
    opps.add(new Opportunity(Name = 'QA MAP Opp ' + i, AccountId = a.Id, StageName = 'Summary', CloseDate = Date.today().addDays(30))); }
insert cons; insert opps;
Map<Id, List<String>> team = new Map<Id, List<String>>();
for (AccountTeamMember m : [SELECT AccountId, TeamMemberRole, User.Username FROM AccountTeamMember WHERE AccountId IN :accs]) { if (!team.containsKey(m.AccountId)) team.put(m.AccountId, new List<String>()); team.get(m.AccountId).add(m.TeamMemberRole + '=' + m.User.Username); }
for (Contact_Team__c m : [SELECT Contact__c, TeamMemberRole__c, Team_Member__r.Username FROM Contact_Team__c WHERE Contact__c IN :cons]) { if (!team.containsKey(m.Contact__c)) team.put(m.Contact__c, new List<String>()); team.get(m.Contact__c).add(m.TeamMemberRole__c + '=' + m.Team_Member__r.Username); }
for (Lead_Team__c m : [SELECT Lead__c, TeamMemberRole__c, Team_Member__r.Username FROM Lead_Team__c WHERE Lead__c IN :leads]) { if (!team.containsKey(m.Lead__c)) team.put(m.Lead__c, new List<String>()); team.get(m.Lead__c).add(m.TeamMemberRole__c + '=' + m.Team_Member__r.Username); }
for (OpportunityTeamMember m : [SELECT OpportunityId, TeamMemberRole, User.Username FROM OpportunityTeamMember WHERE OpportunityId IN :opps]) { if (!team.containsKey(m.OpportunityId)) team.put(m.OpportunityId, new List<String>()); team.get(m.OpportunityId).add(m.TeamMemberRole + '=' + m.User.Username); }
Map<Id, Account> am = new Map<Id, Account>([SELECT Id, Cluster__c FROM Account WHERE Id IN :accs]);
Map<Id, Contact> cm = new Map<Id, Contact>([SELECT Id, Cluster__c, Sales_Channel__c FROM Contact WHERE Id IN :cons]);
Map<Id, Lead> lm = new Map<Id, Lead>([SELECT Id, Cluster__c FROM Lead WHERE Id IN :leads]);
Map<Id, Opportunity> om = new Map<Id, Opportunity>([SELECT Id, Cluster__c, Sales_Channel__c, Sector__c FROM Opportunity WHERE Id IN :opps]);
for (Integer k = 0; k < scen.size(); k++) {
    String key = scen[k][0] + '~' + scen[k][1];
    List<SObject> recs = new List<SObject>{ am.get(accs[k].Id), cm.get(cons[k].Id), lm.get(leads[k].Id), om.get(opps[k].Id) };
    List<String> objs = new List<String>{ 'Account', 'Contact', 'Lead', 'Opportunity' };
    for (Integer j = 0; j < 4; j++) {
        List<String> t = team.containsKey(recs[j].Id) ? team.get(recs[j].Id) : new List<String>(); t.sort();
        String extra = (j == 3) ? (' [Opp copied: ' + om.get(opps[k].Id).Sales_Channel__c + '/' + om.get(opps[k].Id).Sector__c + ']') : '';
        out.add(objs[j] + '~' + key + '~' + recs[j].get('Cluster__c') + '~' + String.join(t, ';') + '~' + extra);
    }
}
throw new StopAndRollbackException('RESULTS>>' + String.join(out, '||') + '<<');
