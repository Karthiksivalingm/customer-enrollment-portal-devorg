# Flow Catalog

All 22 Flows (2026-10-15). Generated details: [Metadata-Inventory/Flows.md](../Metadata-Inventory/Flows.md).

| Flow | Type / trigger | Status | Does |
|---|---|---|---|
| Agency name Assignment | Account before-save (create) | Active | Sets agency name |
| NPN Sync internal | Account before-save | Active | Syncs NPN fields |
| Create NPN from Account | Account after-save | Active | Creates `NAICProducerCode__c` (fires NIPR targets) |
| Delete NAIC from account | Account before-delete | Active | Deletes `NAICProducerCode__c` |
| Agent Code Assignment | Contact before-save | Active | Sets agent code |
| Contact Sync Internal | Contact before-save | Active | Internal field sync |
| Contact - dob add | Contact after-save | Active | Updates `DOI__c` |
| Auto Certifications Creation | Contact after-save (update) | Active | Creates `Certification__c`; writes `Error_Log__c` |
| Create NPN record from contact | Contact after-save | Active | Creates `NAICProducerCode__c` |
| Delete NAIC record from contact | Contact before-delete | Active | Deletes NAIC record |
| Certifications → Contact Sync | Certification__c after-save | Active | Updates Contact |
| Payment Batch Approval - Commission Records | Payment_Batch__c after-save (update) | Active | Updates the batch's `Commission_Record__c`; writes `Error_Log__c` |
| Update Carrier Name | Upline_Policy__c before-save | Active | Resolves carrier through `Carrier_Alias__c` |
| Upline Policy Key Auto-Populate | Upline_Policy__c before-save | Active | Builds the policy key |
| Update Carrier Name - Commission Record object | Commission_Record__c before-save | Active | Carrier name |
| Account - Agent Onboarding | Screen | Active | Onboarding wizard; Apex action `NIPRforFlow` |
| Add Commission Records to Payment Batch | Screen | Active | Batch assembly |
| Note - Add Note | Screen | Active | Creates `Notes__c` |
| Appointment - Adding Product | Screen | Active | Adds products to an appointment |
| Appointment - Add Product; Add Product Template; Adding Product (Debug) | Screen | Draft | Work in progress |

No scheduled-trigger Flows and no subflows.

## History
| Date | Change | Record |
|---|---|---|
| 2026-10-15 | Created from the baseline retrieval | — |
