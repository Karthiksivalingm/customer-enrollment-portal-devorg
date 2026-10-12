public class SendWarmOffEmail {

    // ══════════════════════════════════════════════════════════════
    // Called by the "Send Shopify At Risk Notice" flow in place of
    // its Send Email element.
    //
    // WHY APEX: the Flow Send Email action does not render custom
    // object merge fields (proven 28 Sep 2026). A Classic template
    // sent with setWhatId(noticeId) does.
    //
    // TEMPLATE BY STAGE (Shopify_At_Risk_Config__mdt, Default)
    //   Month 12         Template_Stage_1__c
    //   Month 15         Template_Stage_2__c
    //   Month 17         Template_Stage_3__c
    //   15-Day Reminder  Template_Stage_4__c
    //   Deactivation     Template_Stage_5__c
    //   (blank stage)    Email_Template_Name__c  — legacy notices
    //
    // Never throws: every failure comes back as success = false with
    // a message, so one bad record cannot roll back the whole batch.
    // Bulk-safe: the flow passes all notices from one insert in one
    // call, which becomes one Messaging.sendEmail call.
    // ══════════════════════════════════════════════════════════════

    public class Request {
        @InvocableVariable(label='Notice Id' required=true)
        public Id noticeId;
    }

    public class Result {
        @InvocableVariable(label='Success')
        public Boolean success = false;
        @InvocableVariable(label='Error Message')
        public String errorMessage;
        @InvocableVariable(label='Email Subject (template)')
        public String subject;
    }

    @TestVisible
    private static Shopify_At_Risk_Config__mdt configOverride;

    private static final String LEGACY = 'LEGACY';

    @InvocableMethod(
        label='Send Warm-Off Email'
        description='Sends the stage template for a Shopify At Risk Notice with the notice as WhatId so its merge fields render, and logs the activity.'
        category='Shopify At Risk'
    )
    public static List<Result> send(List<Request> requests) {

        List<Result> results = new List<Result>();
        Set<Id> ids = new Set<Id>();
        for (Request r : requests) {
            results.add(new Result());
            if (r != null && r.noticeId != null) ids.add(r.noticeId);
        }

        Shopify_At_Risk_Config__mdt cfg = configOverride != null
            ? configOverride
            : Shopify_At_Risk_Config__mdt.getInstance('Default');
        if (cfg == null) return failAll(results, 'Config record Default not found');

        Map<Id, Shopify_At_Risk_Notice__c> notices =
            new Map<Id, Shopify_At_Risk_Notice__c>([
                SELECT Id, Stage__c, Contact__c
                FROM Shopify_At_Risk_Notice__c
                WHERE Id IN :ids
            ]);

        // ── Resolve templates (unique name or name) ───────────────
        Map<String, String> nameByStage = new Map<String, String>{
            ShopifyAtRiskNoticeBatch.STAGE_1 => cfg.Template_Stage_1__c,
            ShopifyAtRiskNoticeBatch.STAGE_2 => cfg.Template_Stage_2__c,
            ShopifyAtRiskNoticeBatch.STAGE_3 => cfg.Template_Stage_3__c,
            ShopifyAtRiskNoticeBatch.STAGE_4 => cfg.Template_Stage_4__c,
            ShopifyAtRiskNoticeBatch.STAGE_5 => cfg.Template_Stage_5__c,
            LEGACY                           => cfg.Email_Template_Name__c
        };
        Set<String> names = new Set<String>();
        for (String n : nameByStage.values()) if (String.isNotBlank(n)) names.add(n);

        Map<String, EmailTemplate> tplByName = new Map<String, EmailTemplate>();
        for (EmailTemplate t : [
            SELECT Id, Name, DeveloperName, Subject
            FROM EmailTemplate
            WHERE (DeveloperName IN :names OR Name IN :names)
            AND   IsActive = true
        ]) {
            tplByName.put(t.DeveloperName, t);
            tplByName.put(t.Name, t);
        }

        Id oweaId;
        if (String.isNotBlank(cfg.Org_Wide_Email__c)) {
            List<OrgWideEmailAddress> o = [
                SELECT Id FROM OrgWideEmailAddress
                WHERE Address = :cfg.Org_Wide_Email__c LIMIT 1
            ];
            if (!o.isEmpty()) oweaId = o[0].Id;
        }

        // ── Daily single-email limit ──────────────────────────────
        try {
            Messaging.reserveSingleEmailCapacity(ids.size());
        } catch (Exception e) {
            return failAll(results, 'Daily email limit reached');
        }

        // ── Build messages ────────────────────────────────────────
        List<Messaging.SingleEmailMessage> msgs =
            new List<Messaging.SingleEmailMessage>();
        List<Integer> msgIndex = new List<Integer>();

        for (Integer i = 0; i < requests.size(); i++) {
            Request r = requests[i];
            Shopify_At_Risk_Notice__c n =
                (r == null || r.noticeId == null) ? null : notices.get(r.noticeId);
            if (n == null) {
                results[i].errorMessage = 'Notice not found';
                continue;
            }
            String stageKey = String.isBlank(n.Stage__c) ? LEGACY : n.Stage__c;
            String tplName  = nameByStage.get(stageKey);
            EmailTemplate tpl = tplName == null ? null : tplByName.get(tplName);
            if (tpl == null) {
                results[i].errorMessage =
                    'No active template configured for stage ' + stageKey;
                continue;
            }

            Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
            m.setTemplateId(tpl.Id);
            m.setTargetObjectId(n.Contact__c);
            m.setWhatId(n.Id);                  // the critical line
            m.setSaveAsActivity(true);
            m.setTreatTargetObjectAsRecipient(true);
            if (oweaId != null) m.setOrgWideEmailAddressId(oweaId);

            msgs.add(m);
            msgIndex.add(i);
            results[i].subject = tpl.Subject;  // raw template subject, groups cleanly in reports
        }

        // ── Send ──────────────────────────────────────────────────
        if (!msgs.isEmpty()) {
            try {
                Messaging.SendEmailResult[] sr = Messaging.sendEmail(msgs, false);
                for (Integer j = 0; j < sr.size(); j++) {
                    Result res = results[msgIndex[j]];
                    if (sr[j].isSuccess()) {
                        res.success = true;
                    } else {
                        res.errorMessage =
                            sr[j].getErrors()[0].getMessage().left(255);
                    }
                }
            } catch (Exception e) {
                for (Integer j : msgIndex) {
                    results[j].errorMessage = e.getMessage().left(255);
                }
            }
        }
        return results;
    }

    private static List<Result> failAll(List<Result> results, String msg) {
        for (Result r : results) r.errorMessage = msg;
        return results;
    }
}