// Read-only verification: evaluates the live Sales_Channel_Cluster__mdt rules on IN-MEMORY records.
// No DML is performed - nothing is inserted, updated or deleted.
List<List<String>> scen = new List<List<String>>{
    new List<String>{'Specialty', 'Sellgoodr USA'}, new List<String>{'Specialty', 'Self Service'},
    new List<String>{'Specialty', 'Bridge'},        new List<String>{'Specialty', 'Planned'},
    new List<String>{'Specialty CAN', 'Sellgoodr CAN'}, new List<String>{'Specialty CAN', 'Bridge'},
    new List<String>{'Specialty', 'Sellgoodr CAN'}, new List<String>{'Specialty CAN', ''}, new List<String>{'Specialty', ''},
    new List<String>{'Key Account', 'Core'}, new List<String>{'Key Account', 'Enterprise'},
    new List<String>{'Key Account', 'Mid-Market'}, new List<String>{'Key Account', 'Strategic'}, new List<String>{'Key Account', 'Development'},
    new List<String>{'Key Account', 'Off-Price'}, new List<String>{'Key Account', 'Discount'},
    new List<String>{'Global', 'Global'}, new List<String>{'Global', 'Distributor'},
    new List<String>{'Partnerships', 'Partnerships'}
};
for (String obj : new List<String>{'Account', 'Lead', 'Opportunity'}) {
    List<SObject> recs = new List<SObject>();
    for (List<String> s : scen) {
        SObject r = Schema.getGlobalDescribe().get(obj).newSObject();
        r.put('Sales_Channel__c', s[0]);
        if (String.isNotBlank(s[1])) r.put('Sector__c', s[1]);
        recs.add(r);
    }
    ClusterRuleEngine.evaluate(obj, recs, null);
    for (Integer i = 0; i < recs.size(); i++) {
        System.debug(LoggingLevel.ERROR, 'RESULT|' + obj + '|' + scen[i][0] + '|' + (String.isBlank(scen[i][1]) ? '(blank)' : scen[i][1]) + '|' + recs[i].get('Cluster__c'));
    }
}
