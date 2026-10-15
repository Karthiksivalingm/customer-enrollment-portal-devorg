# Salesforce Environment

## 1. Org

| Item | Value |
|---|---|
| Org name | uLab Systems |
| Org ID | `00D5200000001UeEAI` |
| Type | **Sandbox** (`IsSandbox = true`), Enterprise Edition |
| Sandbox name | `staging` |
| My Domain | `https://ulab--staging.sandbox.my.salesforce.com` |
| Instance | USA432S |
| CLI alias | `Ulab Sandbox` (set in `Ulab/.sf/config.json`; not committed) |
| Locale / language / time zone | en_US / en_US / America/Tijuana (Pacific) |
| Org created | 2020-01-17 |
| Production org | **TO BE CONFIRMED.** It is not connected to this project and must never be used from it |

Verified on 2026-10-15 with `SELECT Id, Name, IsSandbox, OrganizationType, InstanceName FROM Organization`.

## 2. Salesforce DX project

| Item | Value |
|---|---|
| Repository | `https://github.com/sfdcut/SFDC.git`, folder `Ulab/`, branch `main` |
| Source format | Salesforce DX, `force-app/main/default/` |
| `sourceApiVersion` | 67.0 (`sfdx-project.json`) |
| Login URL | `https://login.salesforce.com` in `sfdx-project.json`. Use `https://test.salesforce.com` for sandbox logins |
| Retrieval scope | Team components plus related components. See [Project-Overview.md §5](Project-Overview.md#5-scope-and-limits) |

## 3. Users and licences

| Licence | Total | Used |
|---|---|---|
| Salesforce | 88 | 77 |
| Salesforce Platform | 113 | 75 |
| Identity | 100 | 1 |
| Salesforce Integration | 5 | 0 |
| Cloud Integration User | 1 | 1 |
| Sales Insights Integration User | 1 | 1 |
| Customer Community Plus | 1 | 0 |
| Chatter Free / External | 5,000 / 500 | 0 / 0 |

**Active users by profile (top):**

| Profile | Active users |
|---|---|
| Dot Compliance Basic Profile | 37 |
| uLab uAssist Team | 25 |
| uLab Sales Manager | 19 |
| System Administrator | 17 |
| uLab Clinical Training & Development | 13 |
| MFG DC Basic Profile | 7 |
| uLab SysAdmin | 7 |
| uLab Marketing | 5 |
| uLab uAssist Lead & Sr. Trainer | 4 |
| uLab Client Services | 3 |

Profiles also referenced in automation: "uLab Area Sales Directors", CFO, CS Management, Finance & HR, Ops Management, Sales Executive, `AA_Okta`.

**Integration users** are recognised by alias in the automation: `ApiUser` (Boomi / NetSuite / WebApp) and `Jarvis`.

**Team users in this sandbox:**

| Name | Status |
|---|---|
| Meshak Michel | Active |
| Kaviya Natarajan | Active |
| Sandip Patel | Active |
| Ankit Singh | **Inactive** |

## 4. Installed managed packages

| Area | Packages |
|---|---|
| Marketing | Pardot (`pi`), ActiveCampaign, BeeFree |
| Compliance / quality | Compliance Suite (`CompSuite`; Dot Compliance profiles) |
| Documents / files | DocuSign eSignature (`dsfs`), Dropbox for Salesforce, Magic Mover for Notes and Attachments |
| Maps | Salesforce Maps, WhereAreOnMap, MapPlotter |
| Data / admin tools | Rollup Helper (`rh2`), Declarative Lookup Rollup Summaries (`dlrs`), Data Fetcher, Metadata Glimpser, Profile2PermSet, ZaapIT Tools, MFA Dashboard, Spanning (backup) |
| Telephony / sales | 8x8 integrations, SalesforceIQ Inbox, Sales Insights |
| Learning | Absorb LMS |
| Analytics | Tableau Viz LWC, CRM Dashboards |

Managed-package components are not in this project's source and are not documented here.

## 5. Org-level configuration used by the in-scope automation

| Item | Detail |
|---|---|
| Org-wide email address | `support@ulabsystems.com`, the sender for most customer alerts. Some alerts use individual employees' addresses (see Technical-Architecture risks) |
| Custom permissions | `Bypass_uAssist_Status_Validation`, `Block_InProgress_Update` |
| Custom metadata | `Ulab_Order_Notification__mdt`: one record, `In_Progress` |
| Platform event channel | `SFDC_AWS_Event_Channel__chn`. Members: `sfdc_order_statusChanged__e`, `sfdc_bundle_updated__e`, `sfdc_account_updated__e`, `accountuser_createdSuccess/Failed`, `user_updated` |
| Named credential | `AWS_QA`: AWS EventBridge ARN endpoint, us-west-2 (see [Integrations.md](Integrations.md)) |
| Remote site settings | `SalesforceOrgDomain` (staging My Domain, for the self-callout), `Chatfunction`, `ulabmessage` (Okta CIAM QA), `getmessageapinew` (Okta CIAM prod), `chatfunction1` (AlignerOEM QA API), `getmessageapinew1` (AlignerOEM prod API) |
| Connected app | `Okta` (OAuth scopes Basic, Api, RefreshToken; refresh token valid until revoked) |
| Email template folders used | `unfiled$public`, `uAssist`, `uDesignJan2024`, `X05EmailTemplatesEmailTemplates`, `New_uDesign_Cloud_Templates` |

### Environment-specific values to change per org

These values differ between sandboxes and production. Check each one before deploying.

- **Remote site `SalesforceOrgDomain`:** contains the staging My Domain URL.
- **Named credential `AWS_QA`:** points to the QA AWS account.
- **AlignerOEM QA host:** hard-coded in `Showme.cls`.
- **Okta QA token URL:** stored in Custom Label `tokenapi`.
- **Staging URLs:** hard-coded in `uLab_Case__c.Notes_Attachments__c` and in the lead email template.
- **Hard-coded record type, user and template Ids:** listed in [Technical-Architecture.md §5](Technical-Architecture.md#5-technical-risks-and-recommendations).
- **Named approver** in `Credit_Request_Approval_A`.

## 6. Security findings

| # | Finding | Action taken in this repo | Recommendation |
|---|---|---|---|
| 1 | Custom Label **`Authkey`** holds a Basic-auth client credential for the Okta token endpoint. `Showme.cls` uses it | Label files not committed (`Ulab/.gitignore`). The value is not reproduced anywhere | Move it to a Named / External Credential and rotate the secret |
| 2 | **`showmemockclass.cls`** (test mock) contains a hard-coded access-token value | Not committed (`.gitignore`) | Replace with a dummy value in the org. If the token was real, treat it as exposed |
| 3 | **`Okta.connectedApp-meta.xml`** contains the OAuth consumer key. The refresh token policy is "infinite" and the app is not admin-approved | Not committed (`.gitignore`) | Review the OAuth policies: admin-approved users, a refresh token expiry, IP restrictions |
| 4 | `EmailAlertReaderQueueable` sends the user's session Id to the org's own SOAP API | n/a | Use a Named Credential with OAuth |
| 5 | `NotificationDebugAction` builds SOQL by string concatenation | n/a | Use bind variables, or delete the class |
| 6 | `EmailAlertReaderQueueable` and `Showme` declare no sharing mode. `CreditRequestController` does not enforce FLS | n/a | Declare `with sharing` or `inherited sharing`, and use `WITH USER_MODE` |
| 7 | Personal email addresses are hard-coded in alerts and approval steps (CC lists, named approvers, senders) | n/a | Use roles, queues, public groups or org-wide addresses |

**Rule for this project:** never commit passwords, tokens, keys, session Ids or auth URLs. If you retrieve the excluded files again, they stay local because `.gitignore` already lists them.

## History
| Date | Change |
|---|---|
| 2026-10-15 | Created from Ulab Sandbox queries and metadata. |
