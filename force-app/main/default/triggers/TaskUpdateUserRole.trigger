// Update User Role and User Profile with the current role and profile of the owner

trigger TaskUpdateUserRole on Task (before insert) {

    Set<Id> ownerIds = new Set<Id>();
    for (Task t : Trigger.new) {
        if (t.OwnerId != null && String.valueOf(t.OwnerId).startsWith('005')) {
            ownerIds.add(t.OwnerId);
        }
    }
        Map<Id, User> userMap = new Map<Id, User>(
        [SELECT Id, UserRole.Name, Profile.Name FROM User WHERE Id IN :ownerIds]
    );
    
    for (Task t : Trigger.new) {
        User u = userMap.get(t.OwnerId);
        if (u != null) {
            t.User_Role__c = u.UserRole != null ? u.UserRole.Name : null;
            t.User_Profile__c = u.Profile.Name;
        }
    } 
}