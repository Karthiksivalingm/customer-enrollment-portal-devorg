# CON-014 — Sales Managers role: inconsistent access, and a Marlins Sales page gap

| | |
|---|---|
| **ID** | CON-014 |
| **Status** | ✅ Resolved 2026-10-09 ([CR-023](../04-Change-Records/CR-023_MLB-Sales-Manager-Access-Permission-Set.md), [CR-024](../04-Change-Records/CR-024_Marlins-Sales-App-Contact-Page.md), [CR-025](../04-Change-Records/CR-025_Adobe-Sign-Permission-Sets-For-Sales-Managers.md)) |

## Findings
| # | Finding | Effect |
|---|---|---|
| 1 | Marlins Sales Leadership and President profiles allow **only** the Business Contact record type | New Contact skipped the chooser and opened Business Contact |
| 2 | Neither profile has **Run Flows**, and no permission set gave it | Upload Certificate, Create Agreement and the Agreement Flow couldn't run for these users |
| 3 | The **Marlins Sales** app (console) had **no Contact record page** set | It fell back to `Contact_Record_Page2`, without the certificate banner, vendor buttons or Vendor Information built for the Sales app's page |
| 4 | **Sonja Colon and Caroline O'Connor** lacked Adobe Sign User, Adobe Access and Document Builder User, which the other 9 active Sales Managers had | Hidden Agreements list; "Insufficient Privileges" on Send; `adobesign__DocumentId__c` query error |

## Lessons
- For a new Sales Manager, give **all four** permission sets: MLB Sales Manager Access, Adobe Sign User, Adobe Access, Acrobat Sign Document Builder User. See [TECH-007](../07-Technical/TECH-007_Sales-Manager-Access-Model.md).
- When a page is built for one app, check every app the users actually work in. Page assignments are per app.
- Adobe Sign has **two** managed packages (`echosign_dev1` and `adobesign`), each with its own user permission set.
