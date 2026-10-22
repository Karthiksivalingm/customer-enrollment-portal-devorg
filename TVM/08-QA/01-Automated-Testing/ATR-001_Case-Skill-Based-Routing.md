# ATR-001 — Case skill-based routing

| | |
|---|---|
| **Report ID** | ATR-001 |
| **Requirement** | [REQ-001](../../03-Requirements/REQ-001_Case-Skill-Based-Routing.md) Case skill-based routing (existing behaviour, QA requested by the project lead) |
| **Manual test cases** | [MTC-001](../02-Manual-Testing/MTC-001_Case-Skill-Based-Routing.md) |
| **Open issues** | [CON-001](../../05-Conflicts/CON-001_Case-Skill-Router-Inactive.md) |
| **Org** | Sandbox (Fullsandbox) |
| **Run date** | 2026-10-22 |
| **Run as** | System Administrator (validate-only test run); General Support profile (test user created inside the test, TC-001-09) |
| **Result** | **14 of 14 scenarios passed.** 10 backend Apex scenarios and 4 configuration checks. Finding: the Omni-Channel skills router `Skill_Based_Routing_For_Case` is **inactive**. Routing Skill is set on Cases, but Cases are **not** routed to agents by skill in this sandbox (CON-001). |

## 1. Scope
| Component | Type | Version tested |
|---|---|---|
| `Case_Skill_Mapping_for_same_request_types` | Record-triggered Flow (Case, before save, create and update) | v2 (active) |
| `Case.Routing_Skill__c` | Picklist (General, Inventory) | — |
| `Skill_Based_Routing_For_Case` | Omni-Channel routing Flow (skills-based, by Routing Skill and Priority) | v3, **Obsolete**; no active version |
| `Skilled_Based_Omni_Flow_for_Cases` | Omni-Channel routing Flow | v1–v4, all Obsolete |
| Skills `General`, `Inventory` | Omni-Channel skills | — |
| `High/Medium/Low_Priority_Case_Routing_Config` | Routing configurations used by the skills router | Most Available, priority 1 / 2 / 3 |

Mapping set by the Flow (Case Category = General Support):

| Case Subcategory | Case Request | Routing Skill |
|---|---|---|
| Inventory | Other | Inventory |
| Inventory | VDV Issue | Inventory |
| Onboarding | Other | General |
| Websites - Apollo Apps | VDV Issue | General |
| any other combination | | not set (left as it was) |

## 2. How the tests were run
- **Backend (TC-001-01 to 10):** Apex test class [ATR-001_CaseSkillRoutingQaTest.cls](ATR-001_CaseSkillRoutingQaTest.cls), run as a **validate-only deployment**
  with `RunSpecifiedTests`. Salesforce ran the tests in the org and saved nothing: no class and no Case was left behind (TC-001-11).
  The tests create Cases on the Master record type with Case Category "General Support", so all Case automation runs as normal.
- **Configuration (TC-001-11 to 14):** read-only SOQL queries against the sandbox (Flow versions, skills, agent skills).
- **Front end:** not driven in this run. The screens are covered by [MTC-001](../02-Manual-Testing/MTC-001_Case-Skill-Based-Routing.md) for the QA team.
  Screenshots will be added when the manual run is captured.

## 3. Scenario results

### Backend
| Test ID | Scenario | Type | Run as | Input / test data | Expected result | Actual result | Result |
|---|---|---|---|---|---|---|---|
| TC-001-01 | Inventory + Other | Apex | System Administrator | New Case: General Support / Inventory / Other | Routing Skill = Inventory | Inventory | Pass |
| TC-001-02 | Inventory + VDV Issue | Apex | System Administrator | New Case: General Support / Inventory / VDV Issue | Routing Skill = Inventory | Inventory | Pass |
| TC-001-03 | Onboarding + Other | Apex | System Administrator | New Case: General Support / Onboarding / Other | Routing Skill = General | General | Pass |
| TC-001-04 | Websites - Apollo Apps + VDV Issue | Apex | System Administrator | New Case: General Support / Websites - Apollo Apps / VDV Issue | Routing Skill = General | General | Pass |
| TC-001-05 | Unmapped combinations | Apex | System Administrator | Inventory / Feed Export Issue; Websites - Apollo Apps / VDV Setup | Routing Skill blank | Blank on both | Pass |
| TC-001-06 | Update to a mapped combination | Apex | System Administrator | Case created Inventory / Feed Export Issue, then changed to Onboarding / Other | Blank on create; General after the update | Blank, then General | Pass |
| TC-001-07 | Change to an unmapped combination | Apex | System Administrator | Case created Inventory / Other, then Request changed to Feed Export Issue | Skill stays Inventory (the Flow does not clear it) | Stayed Inventory | Pass |
| TC-001-08 | Bulk: 200 Cases | Apex | System Administrator | 50 of each mapped combination in one insert | 100 Inventory, 100 General, 0 wrong | 100 Inventory, 100 General, 0 wrong | Pass |
| TC-001-09 | Case created by a General Support agent | Apex (runAs) | General Support profile | New Case: Onboarding / Other | Routing Skill = General | General | Pass |
| TC-001-10 | Skills used for routing exist | Apex | System Administrator | Skill records | General and Inventory exist | Both found | Pass |

### Configuration
| Test ID | Scenario | Type | Run as | Input / test data | Expected result | Actual result | Result |
|---|---|---|---|---|---|---|---|
| TC-001-11 | Nothing left behind by the test run | SOQL | System Administrator | `ApexClass` named CaseSkillRoutingQaTest | 0 rows | 0 rows | Pass |
| TC-001-12 | Skill-mapping Flow is active | SOQL | System Administrator | `FlowVersionView` | One active version | v2 active (last modified 2026-07-21) | Pass |
| TC-001-13 | Omni skills router state | SOQL | System Administrator | `FlowDefinitionView`, `FlowVersionView` | Record the actual state | `Skill_Based_Routing_For_Case` has no active version (v3 Obsolete since 2026-07-01). `Skilled_Based_Omni_Flow_for_Cases` v1–v4 Obsolete | Pass (state recorded; see CON-001) |
| TC-001-14 | Agents hold the routing skills | SOQL | System Administrator | `ServiceResourceSkill` on active service resources | At least one agent per skill | General: 19 active agents · Inventory: 9 active agents (General Support profile, plus a few admins) | Pass |

## 4. Defects found
None in the tested behaviour.

Findings, recorded in [CON-001](../../05-Conflicts/CON-001_Case-Skill-Router-Inactive.md):
1. **Skill routing is not live.** The Routing Skill is set on Cases, but no active Flow routes Cases to agents by skill. Omni-Channel Case routing in the
   sandbox is queue-based (`Case_General_Support_Router`).
2. **The Routing Skill is not cleared** when a Case moves to an unmapped Subcategory or Request (TC-001-07). If the router is reactivated, such
   Cases would still be routed by their old skill.
3. **Origin unknown:** 7 skill requirements exist on older Cases (added 2026-09-25 to 2026-10-09). Those Cases have no Routing Skill and are not
   mapped combinations, so they were not added by these Flows. The origin is not determined.

## 5. Evidence
| Item | Value |
|---|---|
| Backend test run (validate-only, 10 of 10 passed, 0 failures, about 30 s) | `0AfVa00000DtpDhKAJ` (check-only = true, status Succeeded) |
| Test class | [ATR-001_CaseSkillRoutingQaTest.cls](ATR-001_CaseSkillRoutingQaTest.cls), deployed as `CaseSkillRoutingQaTest`. Not saved in the org |
| Skill-mapping Flow | `Case_Skill_Mapping_for_same_request_types` v2, Active |
| Skills router | `Skill_Based_Routing_For_Case` latest v3, Obsolete (`301Va00000yq4UnIAI`), no active version |
| Skills | General `0C5Va000000y9DJKAY`, Inventory `0C5Vb0000007WkjKAE` |
| Cases in the sandbox with a Routing Skill | General 6, Inventory 17 (existing data, not created by this test) |

## 6. Test data and cleanup
| Record | Used in | Restored |
|---|---|---|
| Test Cases (up to 200 per scenario) and one General Support test user | TC-001-01 to 10, inside the validate-only run | Rolled back automatically; nothing saved |
| Existing records | None changed | — |

- No records were created, changed or deleted in the sandbox, and no temporary components remain (TC-001-11).
- No emails, external calls or agreements were sent. Test-context Case automation does not send email or call external systems.
