# REQ-001 — Case skill-based routing (QA of existing behaviour)

| | |
|---|---|
| **ID** | REQ-001 |
| **Requested** | 2026-10-22, by the project lead: "do a test for skill-based routing for cases in the TVM sandbox" |
| **Type** | QA of existing functionality. Nothing is built or changed |
| **Status** | Tested: [ATR-001](../08-QA/01-Automated-Testing/ATR-001_Case-Skill-Based-Routing.md), 14 of 14 passed. [MTC-001](../08-QA/02-Manual-Testing/MTC-001_Case-Skill-Based-Routing.md) is ready for the QA team |
| **Related** | [CON-001](../05-Conflicts/CON-001_Case-Skill-Router-Inactive.md) · [Case routing (KB)](../../02-Knowledge-Base/Case-Routing-and-Omni-Channel.md) |

## Business need
Support Cases should reach agents who have the right skill: Inventory issues to agents with the Inventory skill, and general website and
onboarding issues to agents with the General skill.

## Behaviour under test (as built in the sandbox)
1. When a Case with Case Category **General Support** is created or edited, the Flow `Case_Skill_Mapping_for_same_request_types` sets
   **Routing Skill** from Case Subcategory and Case Request:

   | Case Subcategory | Case Request | Routing Skill |
   |---|---|---|
   | Inventory | Other | Inventory |
   | Inventory | VDV Issue | Inventory |
   | Onboarding | Other | General |
   | Websites - Apollo Apps | VDV Issue | General |

   Other combinations leave Routing Skill unchanged.
2. The Omni-Channel Flow `Skill_Based_Routing_For_Case` is built to route Cases to agents with the matching skill, using the High, Medium or
   Low priority routing configuration. **It is not active in the sandbox.**

## Acceptance criteria (for the QA run)
1. Each mapped combination sets the expected Routing Skill, on create and on update.
2. Unmapped combinations leave Routing Skill blank.
3. 200 Cases saved together are all mapped correctly.
4. A General Support agent gets the same result.
5. The skills exist and agents hold them.

## Open questions
- Should `Skill_Based_Routing_For_Case` be active, here and in production? Should Routing Skill be cleared when a Case moves to an unmapped
  combination? (CON-001)
