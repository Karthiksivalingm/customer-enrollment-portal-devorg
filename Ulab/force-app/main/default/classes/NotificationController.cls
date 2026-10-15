public with sharing class NotificationController {

    // ======================================================================
    // INNER WRAPPER CLASSES
    // ======================================================================

    public class AccountEntry {
        @AuraEnabled public String  Id;
        @AuraEnabled public String  Name;
        @AuraEnabled public Boolean disableEmail;
    }

    public class ContactEntry {
        @AuraEnabled public String  Id;
        @AuraEnabled public String  Name;
        @AuraEnabled public Boolean disableEmail;
        @AuraEnabled public String  suppressedFolders; // comma-separated FolderId values; blank = suppress ALL
    }

    public class RuleEntry {
        @AuraEnabled public String id;
        @AuraEnabled public String objectName;
        @AuraEnabled public String fieldName;
        @AuraEnabled public String value;
    }

    public class NotificationPayload {
        @AuraEnabled public Boolean            disableAll;
        @AuraEnabled public List<AccountEntry> accounts;
        @AuraEnabled public List<ContactEntry> contacts;
        @AuraEnabled public List<RuleEntry>    rules;
    }

    // ======================================================================
    // METADATA HELPERS
    // ======================================================================

    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getObjects() {
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        List<Map<String,String>> result = new List<Map<String,String>>();

        Schema.DescribeSObjectResult accountDesc = globalDescribe.get('account').getDescribe();
        result.add(new Map<String,String>{
            'label' => accountDesc.getLabel(),
            'value' => accountDesc.getName()
        });

        Set<String> seen = new Set<String>{ 'Account' };

        for (Schema.ChildRelationship rel : accountDesc.getChildRelationships()) {
            Schema.DescribeSObjectResult childDesc = rel.getChildSObject().getDescribe();
            String childName = childDesc.getName();

            if (seen.contains(childName))          continue;
            if (!childDesc.isAccessible())         continue;
            if (childDesc.isDeprecatedAndHidden()) continue;
            if (!childDesc.isQueryable())          continue;

            seen.add(childName);
            result.add(new Map<String,String>{
                'label' => childDesc.getLabel(),
                'value' => childName
            });
        }

        result.sort(new MapLabelComparator());
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static String getAccountName(Id accountId) {
        if (accountId == null) throw new AuraHandledException('accountId is required');
        try {
            Account acc = [SELECT Name FROM Account WHERE Id = :accountId LIMIT 1];
            return acc.Name;
        } catch (QueryException e) {
            throw new AuraHandledException('Account not found: ' + accountId);
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getContactName(Id contactId) {
        if (contactId == null) throw new AuraHandledException('contactId is required');
        try {
            Contact con = [SELECT Name FROM Contact WHERE Id = :contactId LIMIT 1];
            return con.Name;
        } catch (QueryException e) {
            throw new AuraHandledException('Contact not found: ' + contactId);
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String,Object>> getFields(String objectName) {
        if (String.isBlank(objectName)) throw new AuraHandledException('objectName is required');

        Map<String, Schema.SObjectField> fieldMap;
        try {
            fieldMap = Schema.getGlobalDescribe()
                             .get(objectName).getDescribe().fields.getMap();
        } catch (Exception e) {
            throw new AuraHandledException('Unknown object: ' + objectName);
        }

        List<Map<String,Object>> result = new List<Map<String,Object>>();
        for (Schema.SObjectField f : fieldMap.values()) {
            Schema.DescribeFieldResult dfr = f.getDescribe();
            if (!dfr.isAccessible()) continue;

            Schema.DisplayType dtype = dfr.getType();
            Boolean isPicklist = (dtype == Schema.DisplayType.Picklist ||
                                  dtype == Schema.DisplayType.MultiPicklist);

            result.add(new Map<String,Object>{
                'label'      => dfr.getLabel(),
                'value'      => dfr.getName(),
                'isPicklist' => isPicklist
            });
        }

        result.sort(new MapLabelComparatorObj());
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getPicklistValues(String objectName, String fieldName) {
        if (String.isBlank(objectName) || String.isBlank(fieldName)) {
            throw new AuraHandledException('objectName and fieldName are required');
        }

        Map<String, Schema.SObjectField> fieldMap;
        try {
            fieldMap = Schema.getGlobalDescribe()
                             .get(objectName).getDescribe().fields.getMap();
        } catch (Exception e) {
            throw new AuraHandledException('Unknown object: ' + objectName);
        }

        if (!fieldMap.containsKey(fieldName.toLowerCase())) {
            throw new AuraHandledException('Unknown field: ' + fieldName + ' on ' + objectName);
        }

        Schema.DescribeFieldResult dfr = fieldMap.get(fieldName.toLowerCase()).getDescribe();
        List<Map<String,String>> result = new List<Map<String,String>>();

        Schema.DisplayType dtype = dfr.getType();
        if (dtype == Schema.DisplayType.Picklist || dtype == Schema.DisplayType.MultiPicklist) {
            for (Schema.PicklistEntry entry : dfr.getPicklistValues()) {
                if (entry.isActive()) {
                    result.add(new Map<String,String>{
                        'label' => entry.getLabel(),
                        'value' => entry.getValue()
                    });
                }
            }
        }

        return result;
    }

    // ======================================================================
    // EMAIL TEMPLATE FOLDERS
    //
    // Lightning Enhanced Sharing email template folders have:
    //   Type       = 'EmailTemplate'
    //   AccessType = 'Hidden'   ← this is normal for this folder type
    //
    // Previous versions filtered out AccessType = 'Hidden' which removed
    // ALL Lightning folders. We now query Type = 'EmailTemplate' with NO
    // AccessType filter so all Lightning folders are included.
    //
    // Classic email folders (Type = 'Email') are also included for orgs
    // that have not migrated to enhanced sharing.
    //
    // value = Folder.Id   (stable, used for matching in EmailAlertReaderQueueable)
    // label = Folder.Name (human-readable label shown in Lightning UI)
    // ======================================================================

    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getEmailTemplateFolders() {

        List<Map<String,String>> result = new List<Map<String,String>>();

        // Query Type = 'EmailTemplate' (Lightning enhanced sharing folders)
        // with NO AccessType filter — these folders are always AccessType = 'Hidden'
        // which is correct and expected Salesforce behaviour.
        // Also include Type = 'Email' for classic email template folders.
        for (Folder f : [
            SELECT Id, Name
            FROM   Folder
            WHERE  Type IN ('Email', 'EmailTemplate')
            ORDER  BY Name ASC
        ]) {
            result.add(new Map<String,String>{
                'label' => f.Name,
                'value' => String.valueOf(f.Id)
            });
        }

        return result;
    }

    // ======================================================================
    // IMMEDIATE REMOVE
    // ======================================================================

    @AuraEnabled
    public static void removeAccountNotification(Id accountId) {
        if (accountId == null) throw new AuraHandledException('accountId is required');
        Id userId = UserInfo.getUserId();
        List<User_Account_Notification__c> toDelete = [
            SELECT Id FROM User_Account_Notification__c
            WHERE  User__c    = :userId
            AND    Company__c = :accountId
            LIMIT  1
        ];
        if (!toDelete.isEmpty()) delete toDelete;
    }

    @AuraEnabled
    public static void removeContactNotification(Id contactId) {
        if (contactId == null) throw new AuraHandledException('contactId is required');
        Id userId = UserInfo.getUserId();
        List<Contact_Notification__c> toDelete = [
            SELECT Id FROM Contact_Notification__c
            WHERE  User__c    = :userId
            AND    Contact__c = :contactId
            LIMIT  1
        ];
        if (!toDelete.isEmpty()) delete toDelete;
    }

    // ======================================================================
    // LOAD
    // ======================================================================

    @AuraEnabled
    public static NotificationPayload loadAll() {
        Id userId = UserInfo.getUserId();

        User u = [SELECT Disable_All_Emails__c FROM User WHERE Id = :userId LIMIT 1];

        // Accounts
        List<User_Account_Notification__c> accs = [
            SELECT Company__c, Company__r.Name, Disable_Email__c
            FROM   User_Account_Notification__c
            WHERE  User__c = :userId
        ];

        List<AccountEntry> accountList = new List<AccountEntry>();
        for (User_Account_Notification__c a : accs) {
            AccountEntry ae = new AccountEntry();
            ae.Id           = a.Company__c;
            ae.Name         = a.Company__r.Name;
            ae.disableEmail = a.Disable_Email__c;
            accountList.add(ae);
        }

        // Contacts — includes Suppressed_Folders__c
        List<Contact_Notification__c> cons = [
            SELECT Contact__c, Contact__r.Name, Disable_Email__c, Suppressed_Folders__c
            FROM   Contact_Notification__c
            WHERE  User__c = :userId
        ];

        List<ContactEntry> contactList = new List<ContactEntry>();
        for (Contact_Notification__c c : cons) {
            ContactEntry ce      = new ContactEntry();
            ce.Id                = c.Contact__c;
            ce.Name              = c.Contact__r.Name;
            ce.disableEmail      = c.Disable_Email__c;
            ce.suppressedFolders = c.Suppressed_Folders__c;
            contactList.add(ce);
        }

        // Field rules
        List<User_Notification_Preference__c> prefs = [
            SELECT Id, Object_Name__c, Field_Name__c, Field_Value__c
            FROM   User_Notification_Preference__c
            WHERE  User__c = :userId
        ];

        List<RuleEntry> ruleList = new List<RuleEntry>();
        for (User_Notification_Preference__c p : prefs) {
            RuleEntry re = new RuleEntry();
            re.id         = p.Id;
            re.objectName = p.Object_Name__c;
            re.fieldName  = p.Field_Name__c;
            re.value      = p.Field_Value__c;
            ruleList.add(re);
        }

        NotificationPayload payload = new NotificationPayload();
        payload.disableAll = u.Disable_All_Emails__c;
        payload.accounts   = accountList;
        payload.contacts   = contactList;
        payload.rules      = ruleList;
        return payload;
    }

    // ======================================================================
    // SAVE
    // ======================================================================

    @AuraEnabled
    public static void saveAll(
        Boolean disableAll,
        String  accountsJson,
        String  contactsJson,
        String  rulesJson
    ) {
        Id userId = UserInfo.getUserId();

        // User global flag
        update new User(Id = userId, Disable_All_Emails__c = disableAll == true);

        // Accounts
        List<AccountEntry> accounts = new List<AccountEntry>();
        if (String.isNotBlank(accountsJson)) {
            accounts = (List<AccountEntry>) JSON.deserialize(accountsJson, List<AccountEntry>.class);
        }

        delete [SELECT Id FROM User_Account_Notification__c WHERE User__c = :userId];
        List<User_Account_Notification__c> accRecords = new List<User_Account_Notification__c>();
        for (AccountEntry ae : accounts) {
            accRecords.add(new User_Account_Notification__c(
                User__c          = userId,
                Company__c       = ae.Id,
                Disable_Email__c = (ae.disableEmail == true)
            ));
        }
        if (!accRecords.isEmpty()) insert accRecords;

        // Contacts — saves Suppressed_Folders__c (comma-separated FolderIds)
        List<ContactEntry> contacts = new List<ContactEntry>();
        if (String.isNotBlank(contactsJson)) {
            contacts = (List<ContactEntry>) JSON.deserialize(contactsJson, List<ContactEntry>.class);
        }

        delete [SELECT Id FROM Contact_Notification__c WHERE User__c = :userId];
        List<Contact_Notification__c> conRecords = new List<Contact_Notification__c>();
        for (ContactEntry ce : contacts) {
            conRecords.add(new Contact_Notification__c(
                User__c               = userId,
                Contact__c            = ce.Id,
                Disable_Email__c      = (ce.disableEmail == true),
                Suppressed_Folders__c = ce.suppressedFolders
            ));
        }
        if (!conRecords.isEmpty()) insert conRecords;

        // Field rules
        List<RuleEntry> rules = new List<RuleEntry>();
        if (String.isNotBlank(rulesJson)) {
            rules = (List<RuleEntry>) JSON.deserialize(rulesJson, List<RuleEntry>.class);
        }

        delete [SELECT Id FROM User_Notification_Preference__c WHERE User__c = :userId];
        List<User_Notification_Preference__c> prefRecords = new List<User_Notification_Preference__c>();
        for (RuleEntry re : rules) {
            prefRecords.add(new User_Notification_Preference__c(
                User__c        = userId,
                Object_Name__c = re.objectName,
                Field_Name__c  = re.fieldName,
                Field_Value__c = re.value
            ));
        }
        if (!prefRecords.isEmpty()) insert prefRecords;
    }

    // ======================================================================
    // SORT COMPARATORS
    // ======================================================================

    private class MapLabelComparator implements Comparator<Map<String,String>> {
        public Integer compare(Map<String,String> a, Map<String,String> b) {
            String la = (a.get('label') != null ? a.get('label') : '').toLowerCase();
            String lb = (b.get('label') != null ? b.get('label') : '').toLowerCase();
            if (la < lb) return -1;
            if (la > lb) return  1;
            return 0;
        }
    }

    private class MapLabelComparatorObj implements Comparator<Map<String,Object>> {
        public Integer compare(Map<String,Object> a, Map<String,Object> b) {
            String la = ((String)(a.get('label') != null ? a.get('label') : '')).toLowerCase();
            String lb = ((String)(b.get('label') != null ? b.get('label') : '')).toLowerCase();
            if (la < lb) return -1;
            if (la > lb) return  1;
            return 0;
        }
    }
}