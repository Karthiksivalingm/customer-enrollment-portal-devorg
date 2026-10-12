public class StopAndRollbackException extends Exception {}
List<String> out = new List<String>();
// LIVE TRANSACTION TEST - everything is ROLLED BACK by the forced error on the last line.
// Inserts records so real triggers / flows run, reads results, then fails on purpose:
// no records, emails or queued jobs are committed.
Integer seq = Integer.valueOf(Math.mod(Datetime.now().getTime(), 1000000));
Id companyRt = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Company').getRecordTypeId();

// ---------- T4a: Typeform flow - Canada and US forms ----------
try {
    typeform__Form__c fCan = new typeform__Form__c(typeform__FormId__c = 'ZpuPvJtA');
    typeform__Form__c fUs  = new typeform__Form__c(typeform__FormId__c = 'S0t1jVLc');
    insert new List<typeform__Form__c>{ fCan, fUs };
    typeform__Form_Mapping__c mCan = new typeform__Form_Mapping__c(typeform__Form__c = fCan.Id);
    typeform__Form_Mapping__c mUs  = new typeform__Form_Mapping__c(typeform__Form__c = fUs.Id);
    insert new List<typeform__Form_Mapping__c>{ mCan, mUs };
    Lead lc = new Lead(FirstName = 'Flow', LastName = 'CanadaTest', Company = 'Flow Canada Test Co', Email = 'flowcan' + seq + '@testdomain.com',
        Tax_ID__c = String.valueOf(100000000 + seq), Terms_of_Service_Agreement__c = 'I agree', Has_Physical_Store__c = true,
        Resale_Certificate_Status__c = 'Yes, I do.', Status = 'New', typeform__Typeform_Form_Mapping__c = mCan.Id);
    Lead lu = new Lead(FirstName = 'Flow', LastName = 'USTest', Company = 'Flow US Test Co', Email = 'flowus' + seq + '@testdomain.com',
        Tax_ID__c = String.valueOf(200000000 + seq), Terms_of_Service_Agreement__c = 'I agree', Has_Physical_Store__c = true,
        Resale_Certificate_Status__c = 'Yes, I do.', Status = 'New', typeform__Typeform_Form_Mapping__c = mUs.Id);
    insert new List<Lead>{ lc, lu };
    for (Lead l : [SELECT LastName, Sales_Channel__c, Owner.Name, Cluster__c FROM Lead WHERE Id IN :new List<Id>{ lc.Id, lu.Id }]) {
        out.add('T4A~' + l.LastName + '~' + l.Sales_Channel__c + '~' + l.Owner.Name + '~' + l.Cluster__c);
    }
} catch (Exception e) { out.add('T4A~ERROR~' + e.getMessage()); }

// ---------- T4b: Lead cluster on insert - old vs new values ----------
List<List<String>> leadScen = new List<List<String>>{
    new List<String>{'Specialty','Sellgoodr USA'}, new List<String>{'Specialty','Self Service'},
    new List<String>{'Specialty','Bridge'}, new List<String>{'Specialty','Planned'},
    new List<String>{'Specialty CAN','Sellgoodr CAN'}, new List<String>{'Specialty CAN','Bridge'},
    new List<String>{'Key Account','Core'}, new List<String>{'Key Account','Enterprise'},
    new List<String>{'Global','Global'}, new List<String>{'Global','Distributor'} };
try {
    List<Lead> leads = new List<Lead>(); Integer i = 0;
    for (List<String> s : leadScen) { i++;
        leads.add(new Lead(FirstName = 'Clu', LastName = 'L' + i, Company = 'Cluster Lead ' + i, Email = 'clu' + i + '_' + seq + '@testdomain.com',
            Tax_ID__c = String.valueOf(300000000 + seq * 10 + i), Terms_of_Service_Agreement__c = 'I agree', Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.', Status = 'New', Sales_Channel__c = s[0], Sector__c = s[1])); }
    insert leads;
    Map<Id, Lead> res = new Map<Id, Lead>([SELECT Id, Sales_Channel__c, Sector__c, Cluster__c FROM Lead WHERE Id IN :leads]);
    for (Lead l : leads) { Lead r = res.get(l.Id); out.add('T4B~' + r.Sales_Channel__c + '~' + r.Sector__c + '~' + r.Cluster__c); }
} catch (Exception e) { out.add('T4B~ERROR~' + e.getMessage()); }

// ---------- T4c: Account cluster + team on insert; T4d: Opportunity copy flow ----------
try {
    List<Account> accs = new List<Account>(); Integer i = 0;
    for (List<String> s : leadScen) { i++;
        accs.add(new Account(Name = 'Cluster Acc ' + i + ' ' + seq, RecordTypeId = companyRt, Tax_Id__c = String.valueOf(400000000 + seq * 10 + i),
            BillingStreet = '1 Test St', BillingCity = 'Los Angeles', BillingState = 'CA', BillingPostalCode = '90001', BillingCountry = 'US',
            Sales_Channel__c = s[0], Sector__c = s[1])); }
    insert accs;
    Map<Id, Integer> teamCount = new Map<Id, Integer>();
    for (AggregateResult ar : [SELECT AccountId a, COUNT(Id) n FROM AccountTeamMember WHERE AccountId IN :accs GROUP BY AccountId]) { teamCount.put((Id) ar.get('a'), (Integer) ar.get('n')); }
    Map<Id, Account> res = new Map<Id, Account>([SELECT Id, Sales_Channel__c, Sector__c, Cluster__c FROM Account WHERE Id IN :accs]);
    for (Account a : accs) { Account r = res.get(a.Id); out.add('T4C~' + r.Sales_Channel__c + '~' + r.Sector__c + '~' + r.Cluster__c + '~' + (teamCount.containsKey(a.Id) ? teamCount.get(a.Id) : 0)); }
    List<Opportunity> opps = new List<Opportunity>();
    for (Account a : accs) { if (res.get(a.Id).Sales_Channel__c == 'Specialty CAN') continue; opps.add(new Opportunity(Name = 'Copy Test ' + a.Name, AccountId = a.Id, StageName = 'Summary', CloseDate = Date.today().addDays(30))); }
    insert opps;
    for (Opportunity o : [SELECT Account.Sales_Channel__c, Account.Sector__c, Sales_Channel__c, Sector__c, Cluster__c FROM Opportunity WHERE Id IN :opps]) {
        out.add('T4D~' + o.Account.Sales_Channel__c + '~' + o.Account.Sector__c + '~' + o.Sales_Channel__c + '~' + o.Sector__c + '~' + o.Cluster__c);
    }
} catch (Exception e) { out.add('T4C~ERROR~' + e.getMessage()); }

// ---------- FORCE ROLLBACK OF EVERYTHING ABOVE ----------
out.add('T4~ROLLBACK~forcing error so nothing is saved');
throw new StopAndRollbackException('RESULTS>>' + String.join(out, '||') + '<<');
