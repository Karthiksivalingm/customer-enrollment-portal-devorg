public class CaseSurveyQueueable 
    implements Queueable {

    private Set<Id> caseIds;

    @TestVisible private static Id      surveyId;
    @TestVisible private static Id      communityId;
    @TestVisible private static Boolean skipDmlForTest = false;

    private class InvitationWrapper {
        Id     caseId;
        String invitationLink;
        InvitationWrapper(
            Id caseId,
            String invitationLink
        ) {
            this.caseId         = caseId;
            this.invitationLink = invitationLink;
        }
    }

    public CaseSurveyQueueable(Set<Id> caseIds) {
        this.caseIds = caseIds;
    }

    private static void loadSettings() {
        if (surveyId != null &&
            communityId != null) {
            return;
        }

        List<Survey> surveys = [
            SELECT Id FROM Survey
            WHERE Name = 'CSAT'
            LIMIT 1
        ];
        surveyId = surveys.isEmpty() ?
            null : surveys[0].Id;

        List<Network> networks = [
            SELECT Id FROM Network
            WHERE Name = 'GoodR'
            LIMIT 1
        ];
        communityId = networks.isEmpty() ?
            null : networks[0].Id;
    }

    public void execute(QueueableContext context) {
        loadSettings();

        if (surveyId == null ||
            communityId == null) return;

        Map<Id, Case> caseMap =
            new Map<Id, Case>([
                SELECT Id,
                       CaseNumber,
                       ContactId,
                       Contact.Email,
                       Contact.Name
                FROM Case
                WHERE Id IN :caseIds
                AND Contact.Email != null
            ]);

        if (caseMap.isEmpty()) return;

        EmailTemplate template = [
            SELECT Id
            FROM EmailTemplate
            WHERE Name = 'Case Survey Template'
            LIMIT 1
        ];

        // ── Step 1: Expire existing active ───────
        // ── invitations for these cases     ───────
        // ── Handles reopen + reclose        ───────
        // ── Uses InviteExpiryDateTime field ───────
        // ── Confirmed from org field list   ───────
        if (!skipDmlForTest) {
            try {
                List<SurveyInvitation> oldInvs = [
                    SELECT Id,
                           Name,
                           InviteExpiryDateTime
                    FROM SurveyInvitation
                    WHERE Case__c 
                          IN :caseMap.keySet()
                    AND SurveyId = :surveyId
                ];

                if (!oldInvs.isEmpty()) {
                    for(SurveyInvitation si : 
                        oldInvs) {
                        // Set to past = expired
                        si.InviteExpiryDateTime =
                            DateTime.now()
                            .addYears(-1);
                    }

                    Database.SaveResult[] expireRes =
                        Database.update(
                            oldInvs, false
                        );

                    Integer expOk   = 0;
                    Integer expFail = 0;
                    for(Database.SaveResult r : 
                        expireRes) {
                        if(r.isSuccess()) expOk++;
                        else {
                            expFail++;
                            System.debug(
                                '>>> Expire failed: ' +
                                r.getErrors()[0]
                                .getMessage()
                            );
                        }
                    }
                    System.debug(
                        '>>> Old invitations: ' +
                        ' Expired: ' + expOk +
                        ' Failed: '  + expFail
                    );
                }
            } catch(Exception e) {
                // Non fatal - continue
                System.debug(
                    '>>> Expire error: ' +
                    e.getMessage()
                );
            }
        }

        // ── Step 2: Create fresh invitations ─────
        List<SurveyInvitation> invitations =
            new List<SurveyInvitation>();

        for (Case c : caseMap.values()) {
            invitations.add(
                new SurveyInvitation(
                    Name    = 'Case Survey - ' +
                              c.CaseNumber,
                    SurveyId = surveyId,
                    Case__c  = c.Id,
                    OptionsAllowGuestUserResponse
                             = true,
                    CommunityId = communityId
                )
            );
        }

        // ── Step 3: Build wrappers ────────────────
        List<InvitationWrapper> wrappers =
            new List<InvitationWrapper>();

        if (!skipDmlForTest) {
            insert invitations;

            for (SurveyInvitation si : [
                SELECT Id,
                       InvitationLink,
                       Case__c
                FROM SurveyInvitation
                WHERE Id IN :invitations
            ]) {
                wrappers.add(
                    new InvitationWrapper(
                        si.Case__c,
                        si.InvitationLink
                    )
                );
            }
        } else {
            for (Case c : caseMap.values()) {
                wrappers.add(
                    new InvitationWrapper(
                        c.Id,
                        'https://mock-survey-link.com/'
                        + c.Id
                    )
                );
            }
        }

        // ── Step 4: Update Cases with new link ───
        List<Case> casesToUpdate =
            new List<Case>();

        for (InvitationWrapper w : wrappers) {
            if (String.isBlank(w.invitationLink)){
                continue;
            }
            casesToUpdate.add(new Case(
                Id             = w.caseId,
                Survey_Link__c = w.invitationLink
            ));
        }
        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }

        // ── Step 5: Send Email ────────────────────
        List<Messaging.SingleEmailMessage> emails
            = new List<Messaging.SingleEmailMessage>();

        for (Case c : caseMap.values()) {
            Messaging.SingleEmailMessage mail =
                new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(c.ContactId);
            mail.setWhatId(c.Id);
            mail.setTemplateId(template.Id);
            mail.setSaveAsActivity(false);
            emails.add(mail);
        }
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
}