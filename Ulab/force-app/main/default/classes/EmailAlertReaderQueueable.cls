public class EmailAlertReaderQueueable implements Queueable, Database.AllowsCallouts {

    private Set<Id>  recordIds;
    private String   alertDeveloperName;
    private String   templateDevName;
    private String   objectName;

    private static final String METADATA_API_VERSION = '59.0';

    public EmailAlertReaderQueueable(
        Set<Id> recordIds,
        String  alertDeveloperName,
        String  templateDevName,
        String  objectName
    ) {
        this.recordIds          = recordIds;
        this.alertDeveloperName = alertDeveloperName;
        this.templateDevName    = templateDevName;
        this.objectName         = objectName;
    }

    // ======================================================================
    // EXECUTE
    // ======================================================================

    public void execute(QueueableContext ctx) {

        EmailAlertDetails alertDetails = readEmailAlert(alertDeveloperName);
        if (alertDetails == null) {
            System.debug(LoggingLevel.ERROR,
                'EmailAlertReaderQueueable: failed to read alert: ' + alertDeveloperName);
            return;
        }

        // ── Resolve the template and its FolderId ─────────────────────────
        // We store Folder.Id (not name) in Suppressed_Folders__c so matching
        // is just a Set.contains() on EmailTemplate.FolderId.
        List<EmailTemplate> templates = [
            SELECT Id, FolderId, FolderName
            FROM   EmailTemplate
            WHERE  DeveloperName = :templateDevName
            LIMIT  1
        ];
        if (templates.isEmpty()) {
            System.debug(LoggingLevel.ERROR,
                'EmailAlertReaderQueueable: template not found: ' + templateDevName);
            return;
        }
        Id     templateId         = templates[0].Id;
        String templateFolderId   = templates[0].FolderId != null
            ? String.valueOf(templates[0].FolderId)
            : '';
        String templateFolderName = templates[0].FolderName != null
            ? templates[0].FolderName
            : '(no folder)';

        System.debug(LoggingLevel.INFO,
            'EmailAlertReaderQueueable: template folder = "' + templateFolderName
            + '" | FolderId = ' + templateFolderId);

        Id orgWideEmailId = null;
        if (String.isNotBlank(alertDetails.senderAddress)) {
            List<OrgWideEmailAddress> owas = [
                SELECT Id FROM OrgWideEmailAddress
                WHERE Address = :alertDetails.senderAddress LIMIT 1
            ];
            if (!owas.isEmpty()) orgWideEmailId = owas[0].Id;
        }

        Set<String> resolvedEmails = resolveRecipients(alertDetails);

        System.debug(LoggingLevel.INFO, '╔══════════════════════════════════════════════════');
        System.debug(LoggingLevel.INFO, '║  EmailAlertReaderQueueable — Recipient Resolution');
        System.debug(LoggingLevel.INFO, '╠══════════════════════════════════════════════════');
        System.debug(LoggingLevel.INFO, '║  Alert        : ' + alertDeveloperName);
        System.debug(LoggingLevel.INFO, '║  Object       : ' + objectName);
        System.debug(LoggingLevel.INFO, '║  Template     : ' + templateDevName);
        System.debug(LoggingLevel.INFO, '║  Folder Name  : ' + templateFolderName);
        System.debug(LoggingLevel.INFO, '║  Folder Id    : ' + templateFolderId);
        System.debug(LoggingLevel.INFO, '║  Users        : ' + alertDetails.recipientUsers);
        System.debug(LoggingLevel.INFO, '║  Roles        : ' + alertDetails.recipientRoles);
        System.debug(LoggingLevel.INFO, '║  Groups       : ' + alertDetails.recipientGroups);
        System.debug(LoggingLevel.INFO, '║  Emails       : ' + alertDetails.additionalEmails);
        System.debug(LoggingLevel.INFO, '║  Resolved     : ' + resolvedEmails.size());
        for (String e : resolvedEmails) System.debug(LoggingLevel.INFO, '║     → ' + e);
        System.debug(LoggingLevel.INFO, '╚══════════════════════════════════════════════════');

        List<uLab_Order__c> records = [
            SELECT Id, uAssist_Status__c
            FROM   uLab_Order__c
            WHERE  Id IN :recordIds
        ];

        for (uLab_Order__c rec : records) {

            Set<String> candidateEmails = mergeRecordEmailFields(rec.Id, new Set<String>(resolvedEmails));

            System.debug(LoggingLevel.INFO, '┌─────────────────────────────────────────────────');
            System.debug(LoggingLevel.INFO, '│  Suppression Filter — Record: ' + rec.Id);
            System.debug(LoggingLevel.INFO, '│  BEFORE (' + candidateEmails.size() + '):');
            for (String e : candidateEmails) System.debug(LoggingLevel.INFO, '│     ▶ ' + e);

            FilterResult filterResult = applySuppressionRules(
                rec.Id, candidateEmails, templateFolderId);

            List<String> afterFilter = filterResult.recipientEmails;
            List<String> suppressed  = filterResult.suppressedEmails;

            System.debug(LoggingLevel.INFO, '│  AFTER (' + afterFilter.size() + '):');
            for (String e : afterFilter) System.debug(LoggingLevel.INFO, '│     ✓ ' + e);
            System.debug(LoggingLevel.INFO, '│  SUPPRESSED (' + suppressed.size() + '):');
            for (String e : suppressed)  System.debug(LoggingLevel.INFO, '│     ✗ ' + e);
            System.debug(LoggingLevel.INFO, '└─────────────────────────────────────────────────');

            if (afterFilter.isEmpty()) continue;

            Set<String> suppressedSet = new Set<String>(suppressed);
            List<String> toAddresses  = new List<String>();
            for (String e : afterFilter) {
                if (!suppressedSet.contains(e)) toAddresses.add(e);
            }

            if (toAddresses.isEmpty()) continue;

            try {
                Messaging.SingleEmailMessage mail =
                    Messaging.renderStoredEmailTemplate(templateId, null, rec.Id);

                mail.setToAddresses(toAddresses);
                mail.setSaveAsActivity(false);
                if (orgWideEmailId != null) mail.setOrgWideEmailAddressId(orgWideEmailId);

                List<Messaging.SendEmailResult> results =
                    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail }, false);

                for (Messaging.SendEmailResult r : results) {
                    if (r.isSuccess()) {
                        System.debug(LoggingLevel.INFO,
                            'EmailAlertReaderQueueable: SENT OK | Alert: ' + alertDeveloperName
                            + ' | Record: ' + rec.Id + ' | To: ' + toAddresses);
                    } else {
                        System.debug(LoggingLevel.ERROR,
                            'EmailAlertReaderQueueable: SEND FAILED → '
                            + r.getErrors()[0].getMessage() + ' | Record: ' + rec.Id);
                    }
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR,
                    'EmailAlertReaderQueueable: EXCEPTION → ' + e.getMessage()
                    + ' | Record: ' + rec.Id);
            }

            System.debug(LoggingLevel.INFO, '╔══════════════════════════════════════════════════');
            System.debug(LoggingLevel.INFO, '║  Email Log | Record: ' + rec.Id);
            System.debug(LoggingLevel.INFO, '║  Alert: ' + alertDeveloperName + ' | Template: ' + templateDevName);
            System.debug(LoggingLevel.INFO, '║  Folder: "' + templateFolderName + '" (' + templateFolderId + ')');
            System.debug(LoggingLevel.INFO, '║  Sender: ' + alertDetails.senderAddress);
            System.debug(LoggingLevel.INFO, '║  ── SENT ──');
            for (String e : toAddresses) System.debug(LoggingLevel.INFO, '║     ✓ ' + e);
            System.debug(LoggingLevel.INFO, '║  ── SUPPRESSED ──');
            if (suppressed.isEmpty()) {
                System.debug(LoggingLevel.INFO, '║     (none)');
            } else {
                for (String e : suppressed) System.debug(LoggingLevel.INFO, '║     ✗ ' + e);
            }
            System.debug(LoggingLevel.INFO, '╚══════════════════════════════════════════════════');
        }
    }

    // ======================================================================
    // READ EMAIL ALERT VIA METADATA SOAP API
    // ======================================================================

    private EmailAlertDetails readEmailAlert(String developerName) {
        try {
            String orgUrl   = URL.getOrgDomainUrl().toExternalForm();
            String endpoint = orgUrl + '/services/Soap/m/' + METADATA_API_VERSION;
            String fullName = objectName + '.' + developerName;

            String soapBody =
                '<?xml version="1.0" encoding="UTF-8"?>'
              + '<soapenv:Envelope'
              + '  xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"'
              + '  xmlns:met="http://soap.sforce.com/2006/04/metadata">'
              + '  <soapenv:Header>'
              + '    <met:CallOptions/>'
              + '    <met:SessionHeader>'
              + '      <met:sessionId>' + UserInfo.getSessionId() + '</met:sessionId>'
              + '    </met:SessionHeader>'
              + '  </soapenv:Header>'
              + '  <soapenv:Body>'
              + '    <met:readMetadata>'
              + '      <met:type>WorkflowAlert</met:type>'
              + '      <met:fullNames>' + fullName + '</met:fullNames>'
              + '    </met:readMetadata>'
              + '  </soapenv:Body>'
              + '</soapenv:Envelope>';

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'text/xml; charset=UTF-8');
            req.setHeader('SOAPAction', '""');
            req.setBody(soapBody);

            HttpResponse res = new Http().send(req);

            if (res.getStatusCode() != 200) {
                System.debug(LoggingLevel.ERROR,
                    'EmailAlertReaderQueueable: Metadata SOAP API error '
                    + res.getStatusCode() + ' → ' + res.getBody());
                return null;
            }

            return parseAlertResponse(res.getBody());

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'EmailAlertReaderQueueable: callout exception → ' + e.getMessage());
            return null;
        }
    }

    // ======================================================================
    // PARSE METADATA XML
    // ======================================================================

    private EmailAlertDetails parseAlertResponse(String xmlBody) {
        EmailAlertDetails details = new EmailAlertDetails();
        details.recipientUsers   = new List<String>();
        details.recipientRoles   = new List<String>();
        details.recipientGroups  = new List<String>();
        details.additionalEmails = new List<String>();

        try {
            Dom.Document doc = new Dom.Document();
            doc.load(xmlBody);

            Dom.XmlNode envelope = doc.getRootElement();
            Dom.XmlNode body = envelope.getChildElement(
                'Body', 'http://schemas.xmlsoap.org/soap/envelope/');
            if (body == null) return null;

            Dom.XmlNode readResp = body.getChildElement(
                'readMetadataResponse', 'http://soap.sforce.com/2006/04/metadata');
            if (readResp == null) return null;

            Dom.XmlNode result = readResp.getChildElement(
                'result', 'http://soap.sforce.com/2006/04/metadata');
            if (result == null) return null;

            Dom.XmlNode records = result.getChildElement(
                'records', 'http://soap.sforce.com/2006/04/metadata');
            if (records == null) return null;

            details.senderAddress = getXmlText(records, 'senderAddress');
            details.senderType    = getXmlText(records, 'senderType');

            for (Dom.XmlNode child : records.getChildElements()) {
                if (child.getName() != 'recipients') continue;
                String rType  = getXmlText(child, 'type');
                String rField = getXmlText(child, 'field');
                String rEmail = getXmlText(child, 'email');
                if      (rType == 'user'  && String.isNotBlank(rEmail))  details.recipientUsers.add(rEmail.trim().toLowerCase());
                else if (rType == 'role'  && String.isNotBlank(rField))  details.recipientRoles.add(rField);
                else if (rType == 'group' && String.isNotBlank(rField))  details.recipientGroups.add(rField);
                else if (rType == 'email' && String.isNotBlank(rEmail))  details.additionalEmails.add(rEmail.trim().toLowerCase());
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'EmailAlertReaderQueueable: XML parse error → ' + e.getMessage());
            return null;
        }

        return details;
    }

    // ======================================================================
    // XML HELPER
    // ======================================================================

    private String getXmlText(Dom.XmlNode node, String tagName) {
        Dom.XmlNode child = node.getChildElement(tagName, null);
        if (child == null) child = node.getChildElement(
            tagName, 'http://soap.sforce.com/2006/04/metadata');
        return (child != null) ? child.getText() : null;
    }

    // ======================================================================
    // RESOLVE RECIPIENTS → EMAILS
    // ======================================================================

    private Set<String> resolveRecipients(EmailAlertDetails details) {
        Set<String> emails = new Set<String>();

        for (String e : details.recipientUsers)   { if (String.isNotBlank(e)) emails.add(e.trim().toLowerCase()); }
        for (String e : details.additionalEmails) { if (String.isNotBlank(e)) emails.add(e.trim().toLowerCase()); }

        if (!details.recipientRoles.isEmpty()) {
            for (User u : [
                SELECT Email FROM User
                WHERE IsActive = true AND UserRole.DeveloperName IN :details.recipientRoles
            ]) {
                if (String.isNotBlank(u.Email)) emails.add(u.Email.trim().toLowerCase());
            }
        }

        if (!details.recipientGroups.isEmpty()) {
            List<Group> groups = [
                SELECT Id FROM Group
                WHERE DeveloperName IN :details.recipientGroups AND Type = 'Regular'
            ];

            if (!groups.isEmpty()) {
                Set<Id> groupIds = new Set<Id>();
                Set<Id> userIds  = new Set<Id>();
                Set<Id> toExpand = new Set<Id>();

                for (Group g : groups) { groupIds.add(g.Id); toExpand.add(g.Id); }

                while (!toExpand.isEmpty()) {
                    Set<Id> nextGroups = new Set<Id>();
                    for (GroupMember gm : [
                        SELECT UserOrGroupId FROM GroupMember WHERE GroupId IN :toExpand
                    ]) {
                        String prefix = String.valueOf(gm.UserOrGroupId).substring(0, 3);
                        if (prefix == '005') {
                            userIds.add(gm.UserOrGroupId);
                        } else if (!groupIds.contains(gm.UserOrGroupId)) {
                            groupIds.add(gm.UserOrGroupId);
                            nextGroups.add(gm.UserOrGroupId);
                        }
                    }
                    toExpand = nextGroups;
                }

                for (User u : [
                    SELECT Email FROM User WHERE Id IN :userIds AND IsActive = true
                ]) {
                    if (String.isNotBlank(u.Email)) emails.add(u.Email.trim().toLowerCase());
                }
            }
        }

        return emails;
    }

    // ======================================================================
    // MERGE RECORD EMAIL-TYPE FIELDS
    // ======================================================================

    private Set<String> mergeRecordEmailFields(Id recordId, Set<String> existing) {
        Set<String> merged = new Set<String>(existing);

        Set<String> emailFields = new Set<String>();
        try {
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
            if (objType != null) {
                for (Schema.SObjectField f : objType.getDescribe().fields.getMap().values()) {
                    Schema.DescribeFieldResult dfr = f.getDescribe();
                    if (dfr.getType() == Schema.DisplayType.Email && dfr.isAccessible()) {
                        emailFields.add(dfr.getName());
                    }
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'EmailAlertReaderQueueable: email field discovery error → ' + e.getMessage());
        }

        if (emailFields.isEmpty()) return merged;

        Set<String> fieldsToFetch = new Set<String>(emailFields);
        fieldsToFetch.add('OwnerId');

        Map<String, Object> recordValues = fetchRecordFields(
            String.valueOf(recordId), objectName, fieldsToFetch);

        Object ownerId = recordValues.get('ownerid');
        if (ownerId != null) {
            List<User> owners = [
                SELECT Email FROM User WHERE Id = :(Id)ownerId AND IsActive = true LIMIT 1
            ];
            if (!owners.isEmpty() && String.isNotBlank(owners[0].Email)) {
                merged.add(owners[0].Email.trim().toLowerCase());
            }
        }

        for (String field : emailFields) {
            Object val = recordValues.get(field.toLowerCase());
            if (val != null && String.isNotBlank(String.valueOf(val))) {
                merged.add(String.valueOf(val).trim().toLowerCase());
            }
        }

        return merged;
    }

    // ======================================================================
    // APPLY SUPPRESSION RULES
    //
    // templateFolderId — the FolderId of the email template being sent.
    //   This is matched against Suppressed_Folders__c, which stores a
    //   comma-separated list of Folder.Id values selected by the user.
    //
    // Contact suppression logic:
    //   Suppressed_Folders__c blank  → suppress ALL emails to this contact
    //   Suppressed_Folders__c set    → suppress ONLY if templateFolderId
    //                                  is in the comma-separated Id list
    // ======================================================================

    private FilterResult applySuppressionRules(
        Id          recordId,
        Set<String> candidateEmails,
        String      templateFolderId
    ) {
        FilterResult result     = new FilterResult();
        result.recipientEmails  = new List<String>();
        result.suppressedEmails = new List<String>();

        if (candidateEmails.isEmpty()) return result;

        // ── Resolve emails → User Ids ──────────────────────────────────────
        Map<String, Id> emailToUserId = new Map<String, Id>();
        for (User u : [
            SELECT Id, Email FROM User WHERE Email IN :candidateEmails AND IsActive = true
        ]) {
            if (u.Email != null) emailToUserId.put(u.Email.trim().toLowerCase(), u.Id);
        }

        // ── Resolve emails → Contact Ids ───────────────────────────────────
        Map<String, Id> emailToContactId = new Map<String, Id>();
        for (Contact c : [
            SELECT Id, Email FROM Contact WHERE Email IN :candidateEmails
        ]) {
            if (c.Email != null) emailToContactId.put(c.Email.trim().toLowerCase(), c.Id);
        }

        Set<Id> userIdSet    = new Set<Id>(emailToUserId.values());
        Set<Id> contactIdSet = new Set<Id>(emailToContactId.values());

        // ── USER Rule 1 — global suppression ──────────────────────────────
        Set<Id> globalSuppressedUsers = new Set<Id>();
        if (!userIdSet.isEmpty()) {
            for (User u : [
                SELECT Id FROM User
                WHERE Id IN :userIdSet AND Disable_All_Emails__c = true
            ]) {
                globalSuppressedUsers.add(u.Id);
            }
        }

        // ── USER Rule 2 — account-level suppression ────────────────────────
        Map<Id, Set<Id>> userAcctSupp = new Map<Id, Set<Id>>();
        if (!userIdSet.isEmpty()) {
            for (User_Account_Notification__c r : [
                SELECT User__c, Company__c FROM User_Account_Notification__c
                WHERE  User__c IN :userIdSet AND Disable_Email__c = true
            ]) {
                if (!userAcctSupp.containsKey(r.User__c))
                    userAcctSupp.put(r.User__c, new Set<Id>());
                userAcctSupp.get(r.User__c).add(r.Company__c);
            }
        }

        // ── USER Rule 3 — field-level suppression ──────────────────────────
        Map<Id, List<User_Notification_Preference__c>> userFieldRules =
            new Map<Id, List<User_Notification_Preference__c>>();
        if (!userIdSet.isEmpty()) {
            String objectNameLower = objectName != null ? objectName.toLowerCase() : '';
            for (User_Notification_Preference__c p : [
                SELECT User__c, Object_Name__c, Field_Name__c, Field_Value__c
                FROM   User_Notification_Preference__c
                WHERE  User__c IN :userIdSet
            ]) {
                if (p.Object_Name__c == null) continue;
                if (p.Object_Name__c.toLowerCase() != objectNameLower) continue;
                if (!userFieldRules.containsKey(p.User__c))
                    userFieldRules.put(p.User__c, new List<User_Notification_Preference__c>());
                userFieldRules.get(p.User__c).add(p);
            }
        }

        // ── CONTACT Rule 1 — global suppression via HasOptedOutOfEmail ─────
        Set<Id> globalSuppressedContacts = new Set<Id>();
        if (!contactIdSet.isEmpty()) {
            for (Contact c : [
                SELECT Id FROM Contact
                WHERE Id IN :contactIdSet AND HasOptedOutOfEmail = true
            ]) {
                globalSuppressedContacts.add(c.Id);
            }
        }

        // ── CONTACT Rule 2 — folder-aware suppression ──────────────────────
        // Suppressed_Folders__c = comma-separated Folder.Id strings
        // blank  → suppress ALL emails to this contact
        // set    → suppress only when templateFolderId is in the list
        Set<Id>         suppressedContactIds     = new Set<Id>();
        Map<Id, String> contactSuppressedFolders = new Map<Id, String>();

        if (!contactIdSet.isEmpty()) {
            for (Contact_Notification__c r : [
                SELECT Contact__c, Disable_Email__c, Suppressed_Folders__c
                FROM   Contact_Notification__c
                WHERE  Contact__c IN :contactIdSet AND Disable_Email__c = true
            ]) {
                suppressedContactIds.add(r.Contact__c);
                contactSuppressedFolders.put(r.Contact__c, r.Suppressed_Folders__c);
            }
        }

        // ── CONTACT Rule 3 — field-level suppression ──────────────────────
        Map<Id, List<User_Notification_Preference__c>> contactFieldRules =
            new Map<Id, List<User_Notification_Preference__c>>();
        if (!contactIdSet.isEmpty()) {
            String objectNameLower = objectName != null ? objectName.toLowerCase() : '';
            for (User_Notification_Preference__c p : [
                SELECT User__c, Object_Name__c, Field_Name__c, Field_Value__c
                FROM   User_Notification_Preference__c
                WHERE  User__c IN :contactIdSet
            ]) {
                if (p.Object_Name__c == null) continue;
                if (p.Object_Name__c.toLowerCase() != objectNameLower) continue;
                if (!contactFieldRules.containsKey(p.User__c))
                    contactFieldRules.put(p.User__c, new List<User_Notification_Preference__c>());
                contactFieldRules.get(p.User__c).add(p);
            }
        }

        // ── Shared: triggering account + record field values ───────────────
        Id triggeringAccountId = resolveTriggeringAccount(String.valueOf(recordId));

        Map<String, String> recFieldValues = new Map<String, String>();
        Set<String> allRuleFields = new Set<String>();
        for (List<User_Notification_Preference__c> rList : userFieldRules.values()) {
            for (User_Notification_Preference__c r : rList) allRuleFields.add(r.Field_Name__c);
        }
        for (List<User_Notification_Preference__c> rList : contactFieldRules.values()) {
            for (User_Notification_Preference__c r : rList) allRuleFields.add(r.Field_Name__c);
        }
        if (!allRuleFields.isEmpty()) {
            Map<String, Object> raw = fetchRecordFields(
                String.valueOf(recordId), objectName, allRuleFields);
            for (String f : raw.keySet()) {
                Object v = raw.get(f);
                recFieldValues.put(f.toLowerCase(), v != null ? String.valueOf(v) : '');
            }
        }

        // ── Classify each candidate ────────────────────────────────────────
        for (String email : candidateEmails) {
            if (String.isBlank(email)) continue;

            Boolean suppress = false;

            // ── Check User suppression ─────────────────────────────────────
            Id userId = emailToUserId.get(email);
            if (userId != null) {

                // User Rule 1 — global
                if (globalSuppressedUsers.contains(userId)) {
                    suppress = true;
                    System.debug(LoggingLevel.INFO,
                        'EmailAlertReaderQueueable: USER globally suppressed → ' + email);
                }

                // User Rule 2 — account
                if (!suppress && triggeringAccountId != null
                        && userAcctSupp.containsKey(userId)
                        && userAcctSupp.get(userId).contains(triggeringAccountId)) {
                    suppress = true;
                    System.debug(LoggingLevel.INFO,
                        'EmailAlertReaderQueueable: USER account-suppressed → ' + email);
                }

                // User Rule 3 — field
                if (!suppress && userFieldRules.containsKey(userId)) {
                    for (User_Notification_Preference__c rule : userFieldRules.get(userId)) {
                        String actual = recFieldValues.get(rule.Field_Name__c.toLowerCase());
                        if (String.isNotBlank(actual)
                                && actual.equalsIgnoreCase(rule.Field_Value__c)) {
                            suppress = true;
                            System.debug(LoggingLevel.INFO,
                                'EmailAlertReaderQueueable: USER field-rule suppressed'
                                + ' field=' + rule.Field_Name__c + ' → ' + email);
                            break;
                        }
                    }
                }
            }

            // ── Check Contact suppression (only if not already suppressed) ──
            if (!suppress) {
                Id contactId = emailToContactId.get(email);
                if (contactId != null) {

                    // Contact Rule 1 — HasOptedOutOfEmail (standard field)
                    if (globalSuppressedContacts.contains(contactId)) {
                        suppress = true;
                        System.debug(LoggingLevel.INFO,
                            'EmailAlertReaderQueueable: CONTACT opted out (HasOptedOutOfEmail) → ' + email);
                    }

                    // Contact Rule 2 — folder-aware suppression
                    if (!suppress && suppressedContactIds.contains(contactId)) {
                        String storedFolders = contactSuppressedFolders.get(contactId);

                        if (String.isBlank(storedFolders)) {
                            // No folders configured → suppress ALL emails to this contact
                            suppress = true;
                            System.debug(LoggingLevel.INFO,
                                'EmailAlertReaderQueueable: CONTACT suppressed (all — no folder filter) → ' + email);
                        } else {
                            // Build set of stored Folder Ids and check membership
                            Set<String> folderIdSet = new Set<String>();
                            for (String fid : storedFolders.split(',')) {
                                String trimmed = fid.trim();
                                if (String.isNotBlank(trimmed)) folderIdSet.add(trimmed);
                            }
                            if (String.isNotBlank(templateFolderId)
                                    && folderIdSet.contains(templateFolderId)) {
                                suppress = true;
                                System.debug(LoggingLevel.INFO,
                                    'EmailAlertReaderQueueable: CONTACT suppressed — folderId "'
                                    + templateFolderId + '" matched → ' + email);
                            } else {
                                System.debug(LoggingLevel.INFO,
                                    'EmailAlertReaderQueueable: CONTACT NOT suppressed — folderId "'
                                    + templateFolderId + '" not in suppressed list → ' + email);
                            }
                        }
                    }

                    // Contact Rule 3 — field-level
                    if (!suppress && contactFieldRules.containsKey(contactId)) {
                        for (User_Notification_Preference__c rule : contactFieldRules.get(contactId)) {
                            String actual = recFieldValues.get(rule.Field_Name__c.toLowerCase());
                            if (String.isNotBlank(actual)
                                    && actual.equalsIgnoreCase(rule.Field_Value__c)) {
                                suppress = true;
                                System.debug(LoggingLevel.INFO,
                                    'EmailAlertReaderQueueable: CONTACT field-rule suppressed'
                                    + ' field=' + rule.Field_Name__c + ' → ' + email);
                                break;
                            }
                        }
                    }
                }
            }

            if (suppress) {
                result.suppressedEmails.add(email);
            } else {
                result.recipientEmails.add(email);
            }
        }

        return result;
    }

    // ======================================================================
    // RESOLVE TRIGGERING ACCOUNT
    // ======================================================================

    private Id resolveTriggeringAccount(String recordId) {
        if (objectName.equalsIgnoreCase('Account')) {
            try { return (Id) recordId; } catch (Exception e) { return null; }
        }

        Map<String, Schema.SObjectField> fieldMap;
        try {
            fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        } catch (Exception e) { return null; }

        Set<String> accountLookupFields = new Set<String>();
        Set<String> accountNameFields   = new Set<String>();

        for (String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();
            Schema.DisplayType dtype = dfr.getType();
            if (dtype == Schema.DisplayType.Reference) {
                for (Schema.SObjectType ref : dfr.getReferenceTo()) {
                    if (ref.getDescribe().getName() == 'Account') {
                        accountLookupFields.add(dfr.getName());
                        break;
                    }
                }
            } else if ((dtype == Schema.DisplayType.String || dtype == Schema.DisplayType.TextArea)
                       && (dfr.getName().toLowerCase().contains('account')
                           || dfr.getName().toLowerCase().contains('company'))) {
                accountNameFields.add(dfr.getName());
            }
        }

        if (!accountLookupFields.isEmpty()) {
            try {
                String soql = 'SELECT ' + String.join(new List<String>(accountLookupFields), ', ')
                            + ' FROM ' + objectName + ' WHERE Id = :recordId LIMIT 1';
                List<SObject> rows = Database.query(soql);
                if (!rows.isEmpty()) {
                    for (String f : accountLookupFields) {
                        Object val = rows[0].get(f);
                        if (val != null) { try { return (Id) val; } catch (Exception e) {} }
                    }
                }
            } catch (Exception e) {}
        }

        if (!accountNameFields.isEmpty()) {
            try {
                String soql = 'SELECT ' + String.join(new List<String>(accountNameFields), ', ')
                            + ' FROM ' + objectName + ' WHERE Id = :recordId LIMIT 1';
                List<SObject> rows = Database.query(soql);
                if (!rows.isEmpty()) {
                    for (String f : accountNameFields) {
                        Object val = rows[0].get(f);
                        if (val == null) continue;
                        String accountName = String.valueOf(val).trim();
                        if (String.isBlank(accountName)) continue;
                        List<Account> accts = [
                            SELECT Id FROM Account WHERE Name = :accountName LIMIT 1
                        ];
                        if (!accts.isEmpty()) return accts[0].Id;
                    }
                }
            } catch (Exception e) {}
        }

        return null;
    }

    // ======================================================================
    // FETCH RECORD FIELDS
    // ======================================================================

    private static Map<String, Object> fetchRecordFields(
        String recordId, String objectName, Set<String> fieldNames
    ) {
        Map<String, Object> result = new Map<String, Object>();
        if (fieldNames.isEmpty() || String.isBlank(recordId)) return result;

        Map<String, Schema.SObjectField> fieldMap;
        try {
            fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        } catch (Exception e) { return result; }

        Set<String> valid = new Set<String>();
        for (String f : fieldNames) {
            if (String.isNotBlank(f)
                    && fieldMap.containsKey(f.toLowerCase())
                    && fieldMap.get(f.toLowerCase()).getDescribe().isAccessible()) {
                valid.add(f);
            }
        }
        if (valid.isEmpty()) return result;

        try {
            String soql = 'SELECT ' + String.join(new List<String>(valid), ', ')
                        + ' FROM ' + objectName + ' WHERE Id = :recordId LIMIT 1';
            List<SObject> rows = Database.query(soql);
            if (!rows.isEmpty()) {
                for (String f : valid) result.put(f.toLowerCase(), rows[0].get(f));
            }
        } catch (Exception e) {}

        return result;
    }

    // ======================================================================
    // INNER CLASSES
    // ======================================================================

    public class EmailAlertDetails {
        public String       senderAddress;
        public String       senderType;
        public List<String> recipientUsers;
        public List<String> recipientRoles;
        public List<String> recipientGroups;
        public List<String> additionalEmails;
    }

    private class FilterResult {
        public List<String> recipientEmails;
        public List<String> suppressedEmails;
    }
}