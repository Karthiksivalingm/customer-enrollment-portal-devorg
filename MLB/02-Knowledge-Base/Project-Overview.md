# Project Overview

| | |
|---|---|
| **Document ID** | KB-001 |
| **Client** | Miami Marlins (MLB) |
| **Delivery** | United Techno (UTIS) |
| **Salesforce org worked in** | MLB Sandbox `utdev` (see [KB-004](KB-004_Salesforce-Environment.md)) |
| **Production** | Not touched. Nothing in this project has been deployed to production yet. |
| **Last updated** | 2026-10-21 |

## What the project covers

The work so far extends the Marlins ticket-sales and vendor processes in Salesforce, centred on **Adobe Acrobat Sign agreements**:

1. **Agreement Flow (Opportunity screen flow).** Reps capture agreement details for four agreement types: Membership, Multi-Product, Flex and Suite Lease. A common **Ticket Office Comments** field was added. See [REQ-001](../03-Requirements/REQ-001_Ticket-Office-Comments-Field.md).
2. **Ticket Office notifications.** Salesforce emails the Ticket Office and Sales Manager when an Opportunity agreement is sent at $50k or more, approved or declined by the Sales Manager, or signed or declined by the customer. The signed email carries the signed PDF. See REQ-002 to REQ-005.
3. **Vendor Contact certificates and agreement status.** Vendor contacts must upload certificates (COI, W-9, Food Service) by Account Type before an agreement is created. The Contact's Agreement Status tracks the documents and then the latest Adobe agreement. See REQ-006 to REQ-010.
4. **Sales Managers role access.** All three Contact record types, the Marlins Sales Contact page and the Adobe Sign permission sets for every Sales Manager. See [REQ-012](../03-Requirements/REQ-012_Sales-Managers-Role-Access.md).
5. **Agreement Flow: create and edit, locked agreement details.** One flow behind the Create Agreement and Edit Agreement buttons; an existing agreement opens prefilled. Agreement fields on the Opportunity and Membership Agreement rows can only change through it. See [REQ-014](../03-Requirements/REQ-014_Agreement-Flow-Create-Edit-And-Locked-Agreement-Fields.md).
6. **Sales Vendors.** Sales Vendor record types on Account and Contact; Sales Vendor contacts follow the vendor certificate process. A Sales Manager checkbox on User drives the Sales Manager list on vendor agreements; only certificate files are attached to vendor agreements. See REQ-015 to REQ-018.
7. **Ticketing Engagement on Opportunity.** Built, then **reverted and on hold** at the client's request. See [REQ-011](../03-Requirements/REQ-011_Ticketing-Engagement-Fields-and-Opportunity-Link.md).

## Key business objects

| Object | API name | Role in this project |
|---|---|---|
| Opportunity | `Opportunity` | Ticket sales deal; holds agreement details captured by the Agreement Flow |
| Membership Agreement | `Membership_Agreement__c` | Seat and parking rows for Membership agreements (child of Opportunity via `Opportunity_LUR__c`) |
| Adobe Sign Agreement | `echosign_dev1__SIGN_Agreement__c` | The agreement sent through Adobe Sign; its `echosign_dev1__Status__c` drives notifications and Contact status |
| Contact (Vendor Contact and Sales Vendor record types) | `Contact` / `Vendor_Contact`, `Sales_Vendor` | Vendor whose certificates and agreement status are tracked |
| Account | `Account` | `Type` decides which certificates a vendor needs; `ProVenue_ID__c` identifies the customer |
| Ticketing Engagement | `Ticketing_Engagement__c` | Customer ticketing history (GCP sync). Linked to Contact via `PVID1_Lookup__c` / `PVID2_Lookup__c` |

## Where to find things

| Folder | What it holds |
|---|---|
| `01-Instructions` | How AI tools must be used, plus coding standards. **Read-only; do not edit.** |
| `02-Knowledge-Base` | Project background: this overview, business process, integrations, environment, users |
| `03-Requirements` | One document per requirement (`REQ-###`) |
| `04-Change-Records` | One record per change made to the org (`CR-###`) |
| `05-Conflicts` | Problems, clashes and open risks found while building (`CON-###`) |
| `06-Deployment` | Deployment documents (`DEP-###`), created only when something is actually deployed. **None yet.** |
| `07-Technical` | Technical design and component detail (`TECH-###`) |
| `08-QA` | Automated test reports (ATR) and manual test cases (MTC) |
| `force-app/` | Salesforce metadata source |
| `email-preview/` | Rendered preview of the Ticket Office email |

The full list of documents is in [DOCUMENT-INDEX.md](../DOCUMENT-INDEX.md).
