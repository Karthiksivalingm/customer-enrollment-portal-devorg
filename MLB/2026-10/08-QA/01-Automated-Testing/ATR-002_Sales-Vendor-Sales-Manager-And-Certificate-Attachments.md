# ATR-002 — Sales Vendor, Sales Manager checkbox and certificate-only attachments

| | |
|---|---|
| **Report ID** | ATR-002 |
| **Requirements** | [REQ-015](../../03-Requirements/REQ-015_Account-Sales-Vendor-Type-Value.md) · [REQ-016](../../03-Requirements/REQ-016_Contact-Sales-Vendor-Record-Type.md) · [REQ-017](../../03-Requirements/REQ-017_User-Sales-Manager-Checkbox.md) · [REQ-018](../../03-Requirements/REQ-018_Certificate-Only-Agreement-Attachments.md) |
| **Manual test cases** | [MTC-002](../02-Manual-Testing/MTC-002_Sales-Vendor-Sales-Manager-And-Certificate-Attachments.md) |
| **Org** | Sandbox (UTDEV) |
| **Run date** | 2026-10-21 |
| **Run as** | System Administrator (Billy Marlin); Ticket Sales user in the Apex no-access test |
| **Result** | **16 of 16 scenarios passed**; retested on 2026-10-23 after the vendor features were limited to Sales Vendor and more Sales Managers were ticked (section 7: 5 of 5 passed) |

## 1. Scope
| Component | Type | Version tested |
|---|---|---|
| `Account.Sales_Vendor` | Record type | — |
| `Contact.Sales_Vendor` | Record type | — |
| `Admin`, `Ticket Sales` profiles, `MLB_Sales_Manager_Access` | Access | — |
| `Contact_Record_Page_Three_Column`, `certificateReminder` | Page, LWC | — |
| `Contact_Set_Certificate_Document_Status` / `Adobe_Agreement_Update_Contact_Status` | Flows | v4 / v4 |
| `User.Sales_Manager__c`, `Vendor_Activation_Food_and_Beverage_Agreement` | Field, flow | v9 |
| `CertificateAttachmentService`, `Upload_Certificate` | Apex, flow | v11 |
| Adobe template "Vendor Activation Agreement", row 0000031 | Configuration | Attachments |

## 2. How the tests were run
Apex tests deployed with the class; UI API and SOQL checks; a temporary Sales Vendor contact, agreement and file created through the API and deleted afterwards; the Contact Create Agreement flow and the Contact page opened in Chrome (closed without saving); one Send Agreement draft created and deleted unsent.

## 3. Scenario results
| Test ID | Scenario | Type | Input / test data | Expected result | Actual result | Result |
|---|---|---|---|---|---|---|
| TC-015-01 | Sales Vendor Account Type values | UI API | Account RT Sales_Vendor, field Type | No "Sales Vendor" | 13 values, no "Sales Vendor" | Pass |
| TC-015-02 | Other Account record types keep the value | UI API | Account RT Vendor | "Sales Vendor" still offered | Offered (Business Account never had it) | Pass |
| TC-016-01 | Contact Sales Vendor record type exists | SOQL | RecordType Contact.Sales_Vendor | Active | Active, label "Sales Vendor" | Pass |
| TC-016-02 | Same picklist values as Vendor Contact | UI API | Agreement_Status__c on both record types | Identical | Identical, 13 values | Pass |
| TC-016-03 | Sales reps and administrators can use it | Metadata retrieve | Profiles Admin, Ticket Sales | Visible, not default, Contact-Vendor layout | Both: visible=true, default=false, layout Contact-Vendor | Pass |
| TC-016-04 | Sales Managers can use it | Deploy + assignment check | MLB_Sales_Manager_Access | Record type in the permission set; held by the Sales Managers | Deployed; 18 users hold the set | Pass |
| TC-016-05 | Status set from certificates | API | New Sales Vendor contact, Non-Profit account | Document Pending | Document Pending | Pass |
| TC-016-06 | Banner and Upload Certificate button | UI | Same contact | Banner "COI pending, W-9 optional" with Upload Certificate | Shown, with the reminder pop-up | Pass |
| TC-016-07 | Status follows the Adobe agreement | API | Agreement with status Draft, recipient = the contact | Contact status Draft | Draft | Pass |
| TC-017-01 | Sales Manager checkbox | SOQL | User.Sales_Manager__c | Billy Marlin and Ruben Smith ticked | Both ticked | Pass |
| TC-017-02 | Dropdown uses the checkbox | UI | Contact Create Agreement flow, Sales Manager field | Exactly the ticked active users | "Ruben Smith, Billy Marlin" | Pass |
| TC-017-03 | Unticked users disappear | UI + data | Ruben Smith unticked, then ticked again | Only Billy Marlin listed | "Billy Marlin" only; Ruben ticked again | Pass |
| TC-018-01 | Copy logic | Apex (5 tests) | Copy, direct file not copied, replace same category, 200 files, Ticket Sales user | All pass with real assertions | 5 of 5, coverage 100% (deploy `0AfiV000000Ao8PSAS`) | Pass |
| TC-018-02 | Upload step creates the attachment | API (invocable) | Temp contact, file with category COI | "[COI] QA COI.pdf" on the contact | Created | Pass |
| TC-018-03 | Send Agreement attaches certificates only | UI + SOQL | "Vendor Contact": W-9 from the component, signed PDF added to Files | Draft holds the generated agreement and the W-9 only | "Marlins Sales Vendor Agreement_10-21-2026" and "[W-9] walletlicense9021623_3834.pdf" | Pass |
| TC-018-04 | Existing certificates kept | Backfill | 18 Vendor / Sales Vendor contacts | Categorised files copied | 29 attachments created | Pass |

## 4. Defects found
None in the delivered design. The first design (Adobe runtime variables) failed testing and was replaced: see [CON-016](../../05-Conflicts/CON-016_Adobe-Runtime-Variable-Limits.md).

## 5. Evidence
| Item | Value |
|---|---|
| Apex deploy with tests | `0AfiV000000Ao8PSAS` (5 of 5, 100%) |
| Sales Vendor page, flows, LWC deploy | `0AfiV000000AoI5SAK` |
| Send Agreement test draft | `a15iV000000QyuzQAC` (deleted, never sent) |

## 6. Test data and cleanup
| Record | Used in | Cleanup |
|---|---|---|
| Contact "QA Sales Vendor" and "QA Sales Vendor 2" | TC-016-05 to 07, TC-018-02 | Deleted |
| Agreement "QA status test", file "QA COI" | TC-016-07, TC-018-02 | Deleted |
| Runtime-variable test drafts (3) and template rows (2), temporary button URL | CON-016 trials | Deleted / restored |
| Send Agreement draft a15iV000000QyuzQAC | TC-018-03 | Deleted; "Vendor Contact" status still Ready to Send |
| Ruben Smith Sales Manager tick | TC-017-03 | Ticked again |

## 7. Retest (2026-10-23)
Changes: [CR-036](../../04-Change-Records/CR-036_Contact-Vendor-Features-Sales-Vendor-Only.md) (vendor features on Sales Vendor only) and [CR-037](../../04-Change-Records/CR-037_Sales-Manager-Ticks-And-Sales-User-Access.md) (five Sales Managers ticked; four reps given MLB Sales Manager Access).

| Test ID | Scenario | Type | Input | Expected result | Actual result | Result |
|---|---|---|---|---|---|---|
| TC-016-08 | Vendor Contact gets no vendor features | UI | Vendor Contact "UT Demo 1" | No banner; no Upload Certificate, Create Agreement or Send Agreement buttons | None shown | Pass |
| TC-016-05 (rerun) | Sales Vendor still works | API + UI | New Sales Vendor contact on a Non-Profit account | Document Pending; banner with Upload Certificate | Document Pending; banner and Upload Certificate shown (contact deleted) | Pass |
| TC-018-01 (rerun) | Copy logic on the Sales Vendor record type | Apex | CertificateAttachmentServiceTest now creates Sales Vendor contacts | 5 of 5 | 5 of 5 (deploy `0AfiV000000BLfRSAW`) | Pass |
| TC-017-02 (rerun) | Sales Manager list after the ticks | UI | Contact Create Agreement flow | The seven ticked active users | Jason Liss, Samantha MacIntosh, Nathan Medrano, Ruben Smith, Billy Marlin, Brandon Federico, Pierce Jefferson | Pass |
| TC-017-04 | Ten sales users have every access our features need | SOQL | App, Run Flows, 4 permission sets, 7 objects, 50 fields for 10 users | All present | All 10 hold MLB_Sales_Manager_Access and the three Adobe sets; app, Run Flows, objects and fields present | Pass |