# Opportunity

Trigger status in source:

| Trigger | Object | Status | Calls |
|---|---|---|---|
| OpportunityTrigger | Opportunity | **Inactive** | `OpportunityTriggerHandler.createNewOppWhenClose()` (onboarding methods commented out) |
| CreateNewOppWhenClose | Opportunity (after update) | Active | Body fully commented out (no-op) |
| OpportunityLineTrigger | OpportunityLineItem (after insert/update/delete) | Active | `OpportunityLineItemHandler.recalculateOpportunityAmounts` |
| OpportunityLineItemTrigger | OpportunityLineItem | Inactive | Same logic inline (pre-consolidation duplicate) |

---

## OpportunityTriggerHandler

- **Purpose:** When an **Enrichment** opportunity changes stage to Closed Won / Closed Lost, create a follow-up opp for the same Account if no other open Enrichment opp exists. `with sharing`. (OpFocus, Feb 2018.)
- **Entry point:** `public static void createNewOppWhenClose()` – reads `Trigger.new` / `Trigger.oldMap` directly.
- **Record types:** Opportunity `Enrichment` (by Name, `getRecordTypeInfosByName`).
- **Reads:** Opportunity `RecordTypeId`, `StageName`, `AccountId` (1 SOQL for open Enrichment opps on the accounts).
- **Writes (insert new Opportunity):** `Type`, `Name`, `LeadSource`, `RecordTypeId`, `OwnerId`, `AccountId`, `Estimated_Lift__c`, `Account_in_Extended_Pause__c`, `Trigger_Ranking__c`, `Pro_Dunning_Success_Time__c`, `Initial_CC_Failure_Date__c`, `StageName='Inactive'`, `CloseDate = today+14`, `Notes_from_Last_Opp__c = Notes_for_Next_Opp__c`.
- **Commented-out code:** `enterOnboardingProcess` (`OnboardingSettings__c.Onboard_Next_Opp__c`, `RecordType__c`, `Onboarding_Treatment__c`, `Carrier__r.Exclude_from_Onboarding__c`) and `assignOnboardingOwner` (`Customer_Success_Rep__c`, `Onboarding_Owner__c`, `Account.Support_Rep__c`, `User.Life_Buyer__c`, carrier names Farmers / Allstate).
- **Risks / conflicts:** `OpportunityTrigger` is **Inactive** in source and `CreateNewOppWhenClose` is a no-op, so this logic does not run from source metadata; `OpportunityTriggerHandlerTest.testCreateNewOppWhenClosed` asserts 2 opps and would fail unless the trigger is active in the org. Two closures for the same account in one transaction would each create a new opp (no de-dup within batch). Inserted opp re-fires Opportunity triggers.
- **Tests:** OpportunityTriggerHandlerTest (uses DataFactory; sets `of_Apps__c`), TestCreateNewOppWhenClose (hardcoded RecordTypeId `0121a000000RNO1AAO`, L13; no assertions).

## OpportunityLineItemHandler

- **Purpose:** Roll up line-item totals to parent Opportunity.
- **Entry point:** `public static void recalculateOpportunityAmounts(List<OpportunityLineItem> newLineItems, List<OpportunityLineItem> oldLineItems)`.
- **Logic:** For affected opps, re-query all OLIs (`TotalPrice`, `Product2.Name`); sum Product2.Name = `'Ad spend'` → `DOCUSIGN_Ad_Spend_Amount__c`; `'Search Boost'`, `'Social Media Mgmt'`, `'Multi-Channel Max'` → `DOCUSIGN_Marketing_Services_Products__c`. Product names are hardcoded.
- **SOQL/DML:** 1 SOQL, 1 update (bulk-safe).
- **Risk:** The update of Opportunity re-fires Opportunity triggers/flows on each OLI change.
- **Test:** OpportunityLineItemTriggerTest – `SeeAllData=true` and hardcoded Opportunity Id `0064z00002BsuUiAAJ` (L6); expects ≥4 existing OLIs – will fail in any org without that record.

## OpportuntiyClosedWonAlert

- **Purpose:** Send welcome email to an opp's primary contact on close-won (class name misspelled "Opportuntiy").
- **Entry point:** `@InvocableMethod(label='Send Eamil To Primary Contact') sendEmailAlert(List<Id> contactId)`.
- **Uses:** EmailTemplate Name `'Starter IA CSA Outreach'`; OrgWideEmailAddress `customersupport@everquote.com`.
- **Risks:** Only `contactId[0]` is processed – bulk flow invocations email only the first contact. Queries throw if template/OWEA missing. Email suppressed in tests.
- **Test:** OpportuntiyClosedWonAlertTest.

## CrossUpsellInfoController

- **Purpose:** Standard-controller extension for an Opportunity page showing Auto / Home / Life `Upsell__c` metrics.
- **Entry points:** constructor `(ApexPages.StandardController)`; getters `getAutoUpsell()`, `getHomeUpsell()`, `getLifeUpsell()`.
- **Record types:** `Upsell__c` record types `Auto`, `Home`, `Life` (queried by Name).
- **Reads `Upsell__c`** (filter `Master_Opportunity__c = opp.Id`, LIMIT 1): lift fields (`Premium_Lift__c`, `Preferred_Lift__c`, `Standard_Lift__c`, `Non_Standard_Lift__c`, `Home_Premium_Lift__c`, `Home_Basic_Lift__c`, `Weekday_Cap_Expansion_Lift__c`, `Sat_Cap_Expansion_Lift__c`, `Sun_Cap_Expansion_Lift__c`), radius (`X10/X25/X50_mi_Radius_Lift__c`, `X10/X25/X50_mi_Radius_Zip__c`, `Whole_State_Lift__c`, `Whole_State_Zip__c`), cap fill per day (`Cap_Filled_Rate_Monday__c`…`Cap_Filled_Rate_Sun__c`, `Weekday_Cap_Filled_Rate__c`, `Hour_Hit_Cap_By_Mon__c`…`_Sun__c`), active hours (`Active_Hour_Rate_Mon__c`…`_Sun__c`, `Monday_Biz_Hour_Expansion__c`…, `Monday_Off_Hour_Expansion__c`…, `Saturday_Hour_Expansion__c`, `Sunday_Hour_Expansion__c`), availability (`Taking_Premium__c`, `Taking_Preferred__c`, `Taking_Standard__c`, `Taking_Non_Standard__c`, `Taking_Basic__c`, `Taking_Home__c`, `Premium_/Preferred_/Standard_/Non_standard_/Basic_/Home_Exclusive_Available__c`), schedule (`Add_Day_Mon__c`…`Add_Day_Sun__c`, `Monday_Hours__c`…`Sunday_Hours__c`), `Number_of_Campaigns__c`, `Paused_At__c`, `Resume_At__c`.
- Read-only; 1 RecordType SOQL + up to 3 Upsell SOQL per page render.
- **Test:** **None found** in source – class has no test coverage.
