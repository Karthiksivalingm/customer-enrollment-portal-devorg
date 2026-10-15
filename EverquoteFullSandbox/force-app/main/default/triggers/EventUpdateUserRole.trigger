// Update User Role and User Profile with the current role and profile of the owner

trigger EventUpdateUserRole on Event (before insert) {
    List<Event> change_events = Trigger.new;

    for (Event change_event: change_events){
        List<User> users = [SELECT Id, UserRole.Name, Profile.Name 
                            FROM User WHERE Id = :change_event.OwnerId];
        if(users.size() == 0)
            continue;
        User user = users[0]; 
        
        change_event.User_Role__c = user.UserRole.Name;
        change_event.User_Profile__c = user.Profile.Name;
    }
}