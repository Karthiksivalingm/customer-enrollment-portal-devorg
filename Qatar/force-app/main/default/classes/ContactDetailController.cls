public class ContactDetailController {
    public Boolean showLastName { get; private set; }
    public Boolean showFirstName { get; private set; }
    public Boolean showAboutIndividual { get; private set; }
    public Boolean showAccountId { get; private set; }
    // Add more fields as needed
    
    public ContactDetailController(ApexPages.StandardController controller) {
        // Get the current user's ID
        String userId = UserInfo.getUserId();
        
        // Check if the current user is in the "System_Admins" group
        Boolean isAdmin = isUserInPublicGroup(userId, 'System_Admins');
        
        // Get the Contact record
        Contact contactRecord = (Contact)controller.getRecord();
        
        // Check if the Contact Type is set to "Private"
        if (contactRecord.Contact_Type__c == 'Private') {
            // If the Contact Type is "Private", show only limited fields
            showLastName = true;
            showFirstName = true;
            showAboutIndividual = false;
            showAccountId = false;
            // Set other fields visibility for private contacts
        } else {
            // If the Contact Type is not "Private", show all fields for "System_Admins"
            if (isAdmin) {
                showLastName = true;
                showFirstName = true;
                showAboutIndividual = true;
                showAccountId = true;
                // Set other fields visibility for "System_Admins"
            } else {
                // If the Contact Type is not "Private" and user is not in "System_Admins", show all fields
                showLastName = true;
                showFirstName = true;
                showAboutIndividual = true;
                showAccountId = true;
                // Set other fields visibility for public contacts
            }
        }
    }
    
    // Method to check if the user is a member of the specified public group
    private Boolean isUserInPublicGroup(String userId, String publicGroupName) {
        // Query to check if the user is a member of the public group
        List<GroupMember> groupMembers = [SELECT UserOrGroupId FROM GroupMember WHERE UserOrGroupId = :userId AND Group.DeveloperName = :publicGroupName];
        return !groupMembers.isEmpty();
    }
}