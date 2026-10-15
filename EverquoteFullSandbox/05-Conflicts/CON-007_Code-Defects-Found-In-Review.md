# CON-007: Code defects found in the documentation review

| Field | Value |
|---|---|
| Status | ⚠ Open: re-verify against the current source |
| Severity | 🟡 Low to 🟠 Medium |
| Found | 2026-10-13, against the snapshot from before the org refactor |
| Related | [TECH-001](../07-Technical/TECH-001_Apex-Class-Index.md) · [CR-002](../04-Change-Records/CR-002_Move-To-SFDC-Repo-And-Full-Retrieve.md) |

| Class | Defect | Check against the 2026-10-15 source |
|---|---|---|
| `AutoPopulateContactOnVoiceCall` | `FromPhoneNumber.substring(2)` has no null check | Likely **fixed**: the refactored version adds null and length guards |
| `AssignLeadToCadencesBatch` | Reads `carrierList[0]` before checking the list is non-empty | Re-check |
| `EmailServiceToFindMatchingCase` | `Integer.valueOf` overflows on long numbers in the subject | Re-check |
| `unsubscribe` | Throws a null error on an empty subject | Re-check |
| `OpportunityCheatsheetController` | A null-check (old line 154) never works | Re-check, since the class was refactored |
| `ODARequestCallout.get()` | Discards its query string and always sends POST | Re-check |
| ODA request builders | Throw a null error when `Gender__c`, `Major_Condition_Past_Year__c` or `Date_of_Birth__c` is blank | Re-check |
| Lead automation | `IMHeld__c` is still set, but its auto-convert trigger is inactive | Open |
