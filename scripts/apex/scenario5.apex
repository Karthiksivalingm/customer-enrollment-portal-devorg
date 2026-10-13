List<User> existingOwners = [SELECT Id FROM User WHERE IsActive = true AND Id != UserInfo.getUserId() LIMIT 1];
User existingOwner = existingOwners[0];

Lead l = new Lead(
    FirstName = 'QA', LastName = 'RRLA-005', State = 'CA', Phone = '+13017000000',
    Traffic_Source__c = 950, OwnerId = existingOwner.Id
);
insert l;

roundRobinLeadAssigner.RoundRobinLeadAssignment rra = new roundRobinLeadAssigner.RoundRobinLeadAssignment();
rra.groupName = 'QA_RRLA_Group';
rra.leadRecordId = l.Id;
rra.leadState = 'CA';
rra.firstName = l.FirstName;
rra.lastName = l.LastName;
rra.trafficSource = 950;
rra.phone = l.Phone;

roundRobinLeadAssigner.assign(new List<roundRobinLeadAssigner.RoundRobinLeadAssignment>{ rra });

Integer taskCount = [SELECT COUNT() FROM Task WHERE WhoId = :l.Id];
Lead ledCheck = [SELECT OwnerId, OwnerIsUser__c FROM Lead WHERE Id = :l.Id];

Boolean pass = (taskCount == 1 && ledCheck.OwnerId == existingOwner.Id && ledCheck.OwnerIsUser__c == true);
System.debug('SCENARIO 5 RESULT: ' + (pass ? 'PASS' : 'FAIL') +
    ' | taskCount=' + taskCount + ' (expected 1, Task creation is unconditional)' +
    ' | Lead.OwnerId=' + ledCheck.OwnerId + ' (expected unchanged, ' + existingOwner.Id + ')' +
    ' | OwnerIsUser__c=' + ledCheck.OwnerIsUser__c);
