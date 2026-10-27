# REQ-039 — Sales Channel and Sector required before a Lead is Qualified

| | |
|---|---|
| **ID** | REQ-039 |
| **Status** | ✅ Done in the sandbox (2026-10-27) |
| **Requested** | 2026-10-27 (client, through the project lead) |
| **Related** | [CR-033](../04-Change-Records/CR-033_Lead-Qualify-Validation-Rule.md) · [CON-038](../05-Conflicts/CON-038_Qualify-Rule-And-Existing-Qualified-Leads.md) · [ATR-004](../08-QA/01-Automated-Testing/ATR-004_Lead-Qualify-Validation-Rule.md) · [MTC-005](../08-QA/02-Manual-Testing/MTC-005_Lead-Qualify-Validation-Rule.md) |

## Business need
The client asked that an Account and Contact cannot be created from a Lead (**Create Shopify**) unless **Sales Channel** and **Sector** are both filled in, and that the user gets an error asking them to fill these in.

Without both values the new Account gets no Cluster and therefore no Account Team.

## How Create Shopify works today
- The **Create Shopify** button (`convertLeadButton` → `LeadConversionService`) only works when the Lead is **Qualified** and has a Parent Vertical.
- It does not use standard Salesforce Lead conversion: it creates the Company, Store Location and Contact itself and then ticks **Shopify Created** on the Lead.

So the simplest control is on the step before: **a Lead cannot be set to Qualified while Sales Channel or Sector is blank.**

## Scope
- **In:** a validation rule on Lead that blocks the change to Qualified, from any route: edit, the Status path, the **Approve** button, data loads.
- **Out:**
  - creating Leads (web, Typeform, manual) and editing Leads, which stay as they are;
  - standard Salesforce conversion, where Status also becomes Qualified;
  - Leads that are already Qualified (see [CON-038](../05-Conflicts/CON-038_Qualify-Rule-And-Existing-Qualified-Leads.md)).

## Acceptance criteria
1. Changing a Lead to Qualified with Sales Channel or Sector blank shows: *"Please fill in Sales Channel and Sector before setting this Lead to Qualified."* The Lead keeps its old Status.
2. With both filled, the Lead is Qualified and Create Shopify is enabled.
3. Creating and editing Leads, and moving to any other Status, still works with the fields blank.
4. Existing Apex tests and classes keep working (no test failures caused by the rule).

## Open questions
- What should happen to Leads that are already Qualified with a blank Sales Channel or Sector? See [CON-038](../05-Conflicts/CON-038_Qualify-Rule-And-Existing-Qualified-Leads.md).
