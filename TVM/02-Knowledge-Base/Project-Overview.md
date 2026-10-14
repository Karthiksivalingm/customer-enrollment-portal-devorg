# TVM Project Overview

> Main entry point of the Knowledge Base. It is built from the verified TVM Fullsandbox (`00DVa000006Eh6TMAS`) and the metadata retrieved on
> 2026-10-14. Each statement is labelled **Confirmed** (read in metadata, source or an org query), **Inferred** (interpretation of names
> and structure), or listed under **Not determined**.

## 1. What TVM is

| Statement | Basis |
|---|---|
| The org belongs to **Team Velocity Marketing** and runs on Unlimited Edition. This project works on its full sandbox `fullsando`. | Confirmed (Organization query) |
| TVM sells and delivers **digital marketing services to automotive dealerships**. Evidence: Account record types `Dealership` and `Foundation_Dealership`; OEM programs, enrollments and allocations (`OEM_*__c`, Ford/Lincoln and GM Canada opportunity record types); DMA names; BDC campaigns; creative requests for web banners, email blasts, video, OTT, print ads and landing pages; monthly media budgets; website reviews; Google verification records. | Inferred |
| A second line of business, **Foundation / FNDN** (INFERENCE: "Foundation Direct"), runs in the same org. It has its own record types (Account, Opportunity, Case), onboarding object, financials, credit requests and permission sets. Records are shared with a separate Foundation Direct org through Salesforce-to-Salesforce. | Confirmed for metadata and Flows; business meaning Inferred |
| Work covers the full client lifecycle: sell → contract (DocuSign) → onboard → produce creative and compliance work → run campaigns and budgets → support (Cases, Omni-Channel, voice) → measure and retain. | Inferred from objects and automation ([Architecture](Architecture-and-Dependencies.md)) |

## 2. The org in numbers (unmanaged TVM metadata, Confirmed)

| Area | Count |
|---|---|
| Apex classes (incl. tests) / triggers | See [inventory summary](../07-Technical-Documents/Metadata-Inventory/README.md). About 220 TVM-authored classes; 20 triggers on 12 objects |
| Flows | 620: 483 Active, 220 active record-triggered, 51 scheduled |
| Objects | 133 in source: ~110 custom objects, settings and metadata types, plus 22 customized standard objects. Account (778 fields), Opportunity (802) and Case (465) are the most customized |
| UI | 205 Lightning pages, 152 layouts, 108 tabs, 9 apps, ~17 LWC, ~31 Aura, 35 Visualforce pages |
| Security | 48 permission sets, profiles, roles, groups, sharing rules (see [Security](Security-and-Permissions.md)) |
| Routing | 64 queues, 7 routing configurations, 3 service channels, 102 case-routing metadata records |
| Installed packages | ~50: DocuSign, Pardot, Maps, Slack, Jira, Gong, RingCentral, Amazon Connect, Data Cloud and others ([Org context](Salesforce-Org-Context.md)) |

## 3. How it works: key mechanisms (Confirmed in source)
- **Case routing.** Two mechanisms run side by side:
  - An Apex round-robin, driven by `Case_Routing_Config__mdt`, for Foundation and digital-support requests. It skips out-of-office users, and an hourly batch assigns "Auto" cases.
  - Omni-Channel for support, priority and voice queues.
  - See [Case-Routing-and-Omni-Channel.md](Case-Routing-and-Omni-Channel.md).
- **Automation is mainly Flow-based.** Apex triggers sit beside many record-triggered Flows on Opportunity, Case and Account. There is no single trigger framework. See [Automation-and-Execution-Order.md](Automation-and-Execution-Order.md).
- **The TouchPoint (Quickbase) integration** pushes Account, Contact, group and budget data. Some paths are active, some inactive, and credentials are hardcoded (CF-001). See [Integrations](Integrations-and-External-Systems.md).
- **The data model** centres on the Account (dealership), with about 20 master-detail children. Most custom objects are Public Read/Write or Controlled by Parent. See [Data-Model-and-Relationships.md](Data-Model-and-Relationships.md).

## 4. Knowledge Base map
| Page | Covers |
|---|---|
| [Salesforce-Org-Context.md](Salesforce-Org-Context.md) | Verified org identity, installed packages |
| [Data-Model-and-Relationships.md](Data-Model-and-Relationships.md) | Objects, relationships, record types, settings, custom metadata |
| [Architecture-and-Dependencies.md](Architecture-and-Dependencies.md) | Layers, business flows, critical dependencies |
| [Automation-and-Execution-Order.md](Automation-and-Execution-Order.md) | Triggers, Flows, order of execution, async and scheduled jobs |
| [Case-Routing-and-Omni-Channel.md](Case-Routing-and-Omni-Channel.md) | Case assignment, queues, Omni-Channel, entitlements, email-to-case |
| [Integrations-and-External-Systems.md](Integrations-and-External-Systems.md) | TouchPoint, Salesforce-to-Salesforce, email services, packages |
| [Security-and-Permissions.md](Security-and-Permissions.md) | Org-wide defaults, profiles, permission sets, groups, sharing |
| [Known-Constraints.md](Known-Constraints.md) | Limits, risks, open questions |

## 5. Not determined
- Business goals and priorities of the current development work. No TVM requirements have been received yet (`03-Requirements/` is empty).
- Production configuration and data volumes, because only the sandbox is connected.
- Which reports, dashboards and email templates matter to TVM development.
- Which no-namespace unmanaged-package components are vendor code. See [Known-Constraints.md](Known-Constraints.md).

## History
| Date | Change |
|---|---|
| 2026-10-14 | Created from the baseline retrieval and read-only org queries. |
