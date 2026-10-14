// LIVE CHECK - everything is ROLLED BACK by the exception thrown at the end (nothing is saved).
public class StopAndRollbackException extends Exception {}
List<String> out = new List<String>();
Integer seq = Integer.valueOf(Math.mod(Datetime.now().getTime(), 100000));
Id companyRt = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Company').getRecordTypeId();


List<List<String>> scen = new List<List<String>>{
    new List<String>{'Specialty','Self Service'}, new List<String>{'Specialty','Planned'},
    new List<String>{'Key Account','Enterprise'}, new List<String>{'Key Account','Strategic'},
    new List<String>{'Key Account','Development'}, new List<String>{'Key Account','Discount'},
    new List<String>{'Global','Distributor'}, new List<String>{'Partnerships','Partnerships'} };

// ---------------- CREATE: Account -> Contact -> Opportunity ----------------
List<Account> accs = new List<Account>(); Integer i = 0;
for (List<String> s : scen) { i++;
    accs.add(new Account(Name = 'QA CHK Acc ' + i + ' ' + seq, RecordTypeId = companyRt, Tax_Id__c = String.valueOf(500000000 + seq * 10 + i),
        BillingStreet = '1 Test St', BillingCity = 'Los Angeles', BillingState = 'CA', BillingPostalCode = '90001', BillingCountry = 'US',
        Sales_Channel__c = s[0], Sector__c = s[1])); }
insert accs;
List<Contact> cons = new List<Contact>(); List<Opportunity> opps = new List<Opportunity>(); i = 0;
for (Account a : accs) { i++;
    cons.add(new Contact(FirstName = 'QA', LastName = 'CHK Con ' + i, AccountId = a.Id, Email = 'qachk' + i + '_' + seq + '@testdomain.com'));
    opps.add(new Opportunity(Name = 'QA CHK Opp ' + i, AccountId = a.Id, StageName = 'Summary', CloseDate = Date.today().addDays(30))); }
insert cons; insert opps;
List<Lead> leads = new List<Lead>(); i = 0;
for (List<String> s : scen) { i++;
    leads.add(new Lead(FirstName = 'QA', LastName = 'CHK Lead ' + i, Company = 'QA CHK Lead Co ' + i, Email = 'qachklead' + i + '_' + seq + '@testdomain.com',
        Tax_ID__c = String.valueOf(600000000 + seq * 10 + i), Terms_of_Service_Agreement__c = 'I agree', Has_Physical_Store__c = true,
        Resale_Certificate_Status__c = 'Yes, I do.', Status = 'New', Sales_Channel__c = s[0], Sector__c = s[1])); }
insert leads;



// helper: read state of everything
Map<Id, Account> aMap = new Map<Id, Account>([SELECT Id, Sales_Channel__c, Sector__c, Cluster__c FROM Account WHERE Id IN :accs]);
Map<Id, List<String>> aTeam = new Map<Id, List<String>>();
for (AccountTeamMember m : [SELECT AccountId, User.Username FROM AccountTeamMember WHERE AccountId IN :accs]) { if (!aTeam.containsKey(m.AccountId)) aTeam.put(m.AccountId, new List<String>()); aTeam.get(m.AccountId).add(m.User.Username.substringBefore('@')); }
Map<Id, List<String>> cTeam = new Map<Id, List<String>>();
for (Contact_Team__c m : [SELECT Contact__c, Team_Member__r.Username FROM Contact_Team__c WHERE Contact__c IN :cons]) { if (!cTeam.containsKey(m.Contact__c)) cTeam.put(m.Contact__c, new List<String>()); cTeam.get(m.Contact__c).add(m.Team_Member__r.Username.substringBefore('@')); }
Map<Id, List<String>> oTeam = new Map<Id, List<String>>();
for (OpportunityTeamMember m : [SELECT OpportunityId, User.Username FROM OpportunityTeamMember WHERE OpportunityId IN :opps]) { if (!oTeam.containsKey(m.OpportunityId)) oTeam.put(m.OpportunityId, new List<String>()); oTeam.get(m.OpportunityId).add(m.User.Username.substringBefore('@')); }
Map<Id, List<String>> lTeam = new Map<Id, List<String>>();
for (Lead_Team__c m : [SELECT Lead__c, Team_Member__r.Username FROM Lead_Team__c WHERE Lead__c IN :leads]) { if (!lTeam.containsKey(m.Lead__c)) lTeam.put(m.Lead__c, new List<String>()); lTeam.get(m.Lead__c).add(m.Team_Member__r.Username.substringBefore('@')); }
Map<Id, Contact> cMap = new Map<Id, Contact>([SELECT Id, AccountId, Sales_Channel__c, Cluster__c FROM Contact WHERE Id IN :cons]);
Map<Id, Opportunity> oMap = new Map<Id, Opportunity>([SELECT Id, AccountId, Sales_Channel__c, Sector__c, Cluster__c FROM Opportunity WHERE Id IN :opps]);
Map<Id, Lead> lMap = new Map<Id, Lead>([SELECT Id, Sales_Channel__c, Sector__c, Cluster__c FROM Lead WHERE Id IN :leads]);
for (Integer k = 0; k < accs.size(); k++) {
    Account a = aMap.get(accs[k].Id); Contact c = cMap.get(cons[k].Id); Opportunity o = oMap.get(opps[k].Id); Lead l = lMap.get(leads[k].Id);
    List<String> at = aTeam.containsKey(a.Id) ? aTeam.get(a.Id) : new List<String>(); at.sort();
    List<String> ct = cTeam.containsKey(c.Id) ? cTeam.get(c.Id) : new List<String>(); ct.sort();
    List<String> ot = oTeam.containsKey(o.Id) ? oTeam.get(o.Id) : new List<String>(); ot.sort();
    List<String> lt = lTeam.containsKey(l.Id) ? lTeam.get(l.Id) : new List<String>(); lt.sort();
    out.add('CREATE~Account~' + a.Sales_Channel__c + '~' + a.Sector__c + '~' + a.Cluster__c + '~' + String.join(at, ','));
    out.add('CREATE~Contact~' + c.Sales_Channel__c + '~' + a.Sector__c + '~' + c.Cluster__c + '~' + String.join(ct, ','));
    out.add('CREATE~Opportunity~' + o.Sales_Channel__c + '~' + o.Sector__c + '~' + o.Cluster__c + '~' + String.join(ot, ','));
    out.add('CREATE~Lead~' + l.Sales_Channel__c + '~' + l.Sector__c + '~' + l.Cluster__c + '~' + String.join(lt, ','));
}

// ---------------- UPDATE 1: Sector-only change Planned -> Self Service (Account idx 1, Lead idx 1, Opp idx 1) ----------------
Account ua = new Account(Id = accs[1].Id, Sector__c = 'Self Service'); update ua;
Lead ul = new Lead(Id = leads[1].Id, Sector__c = 'Self Service'); update ul;
Opportunity uo = new Opportunity(Id = opps[1].Id, Sector__c = 'Self Service'); update uo;
Account ra = [SELECT Sales_Channel__c, Sector__c, Cluster__c FROM Account WHERE Id = :ua.Id];
Lead rl = [SELECT Sales_Channel__c, Sector__c, Cluster__c FROM Lead WHERE Id = :ul.Id];
Opportunity ro = [SELECT Sales_Channel__c, Sector__c, Cluster__c FROM Opportunity WHERE Id = :uo.Id];
Contact rc = [SELECT Cluster__c FROM Contact WHERE Id = :cons[1].Id];
Opportunity ro2 = [SELECT Cluster__c FROM Opportunity WHERE Id = :opps[1].Id];
out.add('UPD_SECTOR_ONLY~Account~' + ra.Sales_Channel__c + '~Planned->' + ra.Sector__c + '~' + ra.Cluster__c + '~expected Cluster 6');
out.add('UPD_SECTOR_ONLY~Lead~' + rl.Sales_Channel__c + '~Planned->' + rl.Sector__c + '~' + rl.Cluster__c + '~expected Cluster 6');
out.add('UPD_SECTOR_ONLY~Opportunity~' + ro.Sales_Channel__c + '~Planned->' + ro.Sector__c + '~' + ro.Cluster__c + '~expected Cluster 6');
out.add('UPD_SECTOR_ONLY~Contact(of Account)~-~-~' + rc.Cluster__c + '~follows Account');

// ---------------- UPDATE 2: Sales Channel + Sector change together (Account idx 2 KA/Enterprise -> Specialty/Self Service) ----------------
Account ua2 = new Account(Id = accs[2].Id, Sales_Channel__c = 'Specialty', Sector__c = 'Self Service'); Savepoint spx = Database.setSavepoint(); try { update ua2; } catch (Exception e) { out.add('UPD_CHANNEL_WITH_OPEN_OPP~Account~FAILED~' + e.getMessage().substringAfter('first error: ').left(160)); Database.rollback(spx); delete [SELECT Id FROM Opportunity WHERE Id = :opps[2].Id]; update ua2; out.add('UPD_CHANNEL_NO_OPP~Account~retried after removing its open Opportunity'); }
Account ra2 = [SELECT Sales_Channel__c, Sector__c, Cluster__c FROM Account WHERE Id = :ua2.Id];
List<String> t2 = new List<String>(); for (AccountTeamMember m : [SELECT User.Username FROM AccountTeamMember WHERE AccountId = :ua2.Id]) t2.add(m.User.Username.substringBefore('@')); t2.sort();
List<Opportunity> ro3l = [SELECT Sales_Channel__c, Sector__c, Cluster__c FROM Opportunity WHERE Id = :opps[2].Id]; Opportunity ro3 = ro3l.isEmpty() ? new Opportunity() : ro3l[0];
out.add('UPD_CHANNEL~Account~Key Account->' + ra2.Sales_Channel__c + '~Enterprise->' + ra2.Sector__c + '~' + ra2.Cluster__c + '~' + String.join(t2, ','));
out.add('UPD_CHANNEL~Opportunity(open, cascaded)~' + ro3.Sales_Channel__c + '~' + ro3.Sector__c + '~' + ro3.Cluster__c + '~');

throw new StopAndRollbackException('RESULTS>>' + String.join(out, '||') + '<<');
