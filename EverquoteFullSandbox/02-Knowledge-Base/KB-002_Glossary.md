# Glossary

| Term | Meaning in this org |
|---|---|
| **ODA** | The life insurance agency workflow in Salesforce: quoting, e-app and policy screens, backed by the `ODA*` / `Oda*` Apex classes |
| **Odie** | External EverQuote platform that Salesforce calls through the `Odie_API_Credential` Named Credential. It handles quotes, rates, e-apps, policies, lead forms, owner and disposition sync, and Twilio recording control. |
| **EqLeadUuid__c** | The Lead's identifier in Odie. It's set when Salesforce creates the Lead in Odie. |
| **Carrier** | An insurance company. Stored in `Carrier__c` (object) and on Lead, User and Account through `Carrier__c` fields. |
| **AIG / Gerber / Lumico (AD, WL) / Reliashield** | Life carriers with dedicated ODA quote and rate request builders |
| **Cadence** | A Sales Engagement outreach sequence (phone, or phone and email). The Ids are in Custom Labels `Only_Phone_Cadence_Id` and `Phone_and_Email_Cadence_Id`. |
| **Round robin (RR)** | Rotating assignment of Leads or Opps to users. There are four implementations: `roundRobinLeadAssigner`, `roundRobinAssigner`, `etcd8_RRLeadAssignment`, and the CSR / onboarding assignment. |
| **BDR / SDR** | Business or Sales Development Rep: outbound reps whose Task activity changes Lead ownership |
| **DM / Gatekeeper** | Decision maker, or the person screening calls. Tracked by `DMCallCount__c` and `GateKeeperCallCount__c`. |
| **IM Held** | Initial Meeting held (`IMHeld__c`). It used to auto-convert the Lead. |
| **Fill rate** | How much of a customer's lead or ad cap is filled. Drives `Uncapped_Fill_Rate__c` and `Low_Fill_Rate_Alert__c` on Account. |
| **Core IO** | Core insertion order: the first core product win, recorded in `Account.Core_IO_Win_Date__c` |
| **CTI Picker** | The agent telephony picker service at `adh8.com`, refreshed by `NotifyCTI` |
| **Cheat Sheet** | An external service that shows familiar names and marketplace stats on Lead and Opportunity pages |
| **Delighted** | The survey tool (CSAT / LCS surveys), reached through Contact outbound messages |
| **Zendesk ID** | Legacy support ticket Id stored on Case, used to match inbound emails |
| **etcd8_ / jrsl_ul_** | Prefixes from installed or unmanaged packages (lead round robin and unsubscribe link) |
| **Migrate to Flow** | The Salesforce tool that converts Workflow Rules and Process Builders into flows. Its records are in `processflowmigrations/`. |
