# CON-001 — Case skill router inactive; Routing Skill not cleared

| | |
|---|---|
| **ID** | CON-001 |
| **Status** | Open (decision needed) |
| **Found** | 2026-10-22, during [ATR-001](../08-QA/01-Automated-Testing/ATR-001_Case-Skill-Based-Routing.md) |
| **Area** | Case routing / Omni-Channel |
| **Related** | [REQ-001](../03-Requirements/REQ-001_Case-Skill-Based-Routing.md) · [MTC-001](../08-QA/02-Manual-Testing/MTC-001_Case-Skill-Based-Routing.md) |

## Findings
1. **Skill-based routing is not live in the sandbox.**
   - `Skill_Based_Routing_For_Case` has no active version: v3 has been Obsolete since 2026-07-01.
   - `Skilled_Based_Omni_Flow_for_Cases` v1–v4 are all Obsolete.
   - Omni-Channel Case routing that is active is queue-based (`Case_General_Support_Router`).
   - The Routing Skill field is filled (TC-001-01 to 04) but not used for routing.
2. **Routing Skill is never cleared.** When a Case moves from a mapped combination to an unmapped one, it keeps its old Routing Skill (TC-001-07).
   If skill routing is switched on, such Cases would be routed by their old skill.
3. **Unknown origin of skill requirements.**
   - Seven skill requirements were added between 2026-09-25 and 2026-10-09 to Cases created in May 2025.
   - Those Cases have no Routing Skill, and their Subcategory and Request are not mapped combinations.
   - So something other than these Flows added the requirements. The origin is not determined.

## Options
| Option | Effect |
|---|---|
| A. Leave as is | Routing Skill stays informational. Cases are routed by queue |
| B. Activate `Skill_Based_Routing_For_Case` | Cases route to agents by skill and priority. Retest REQ-001 end to end. Needs approval: it changes automation built by others |
| C. Also clear Routing Skill for unmapped combinations | Prevents routing by an outdated skill. Small Flow change; needs approval |

## Decision
Waiting for the project lead.
