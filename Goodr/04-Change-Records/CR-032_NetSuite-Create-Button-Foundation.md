# CR-032 — Create NetSuite button: foundation (fields, NetSuite Information section, value map, client, Shopify skip guard)

| | |
|---|---|
| **Change ID** | CR-032 |
| **Date** | 2026-10-26 |
| **Requirement** | Create NetSuite button on the Lead (requirement document to follow once the build is confirmed working) |
| **Org** | GDRSAND |
| **Deploy IDs** | Fields `0Afdx00000GU5CLCA1` (13/13) · Pages + Is Saved Record `0Afdx00000GU6JhCAL` (6/6) · Value map, logger, client `0Afdx00000GUCtmCAH` (28/28, check-only `0Afdx00000GUDOPCA5`) · Login helper debug lines `0Afdx00000GUKPtCAP` · Shopify skip guard `0Afdx00000GUR6PCAX` (check-only `0Afdx00000GUQiDCAX`) |
| **By** | Assistant (VS Code deploy); removal of unused NetSuite items done by the user |
| **Status** | Done in sandbox |

## What changed
| Component | Type | Change |
|---|---|---|
| `Lead.NetSuite_Created__c`, `NetSuite_Created_Date__c`, `NetSuite_Status__c`, `NetSuite_Error__c`, `NetSuite_Id__c`, `NetSuite_Account__c`, `NetSuite_Contact__c`, `Created_In__c` | Fields (8 new) | Where the Lead was created (Shopify / NetSuite / both), sync status, error, NetSuite ID, NetSuite-side account and contact. Shopify fields and Related Account/Contact are untouched |
| `Contact.NetSuite_Id__c` (External ID), `Contact.Skip_Shopify_Sync__c`, `Account.Skip_Shopify_Sync__c` | Fields (3 new) | NetSuite ID write-back; flag that keeps Create NetSuite records out of Shopify (default unticked) |
| `Store__c.Default_Shipping__c` | Field (new) | Chooses the default shipping address in NetSuite |
| `API_Log__c.Integration__c` | Field (new) | Picklist Shopify / NetSuite, default Shopify, so existing Shopify logging is unchanged |
| `Lead.Is_Saved_Record__c`, `Contact.Is_Saved_Record__c` | Fields (2 new) | `NOT(ISBLANK(Id))`, same as the Account field; used only by section filters |
| All profiles that can read each object | Field access | Read on all new fields; edit where the profile can edit the object; formulas read-only. 175 + 29 field permissions; profiles with View All Fields already see them |
| `Account_Company_Record_Page`, `Account_Store_Location_Record_Page1`, `Contact_Record_Page`, `Lead_Record_Page` | Lightning pages | New **NetSuite Information** section above Address Information, hidden on New (`Is_Saved_Record__c = true`). Company page: `NetSuite_Id__c` moved from Account Information into the section. Account pages: obsolete hidden tabset `label` property removed (required for the save; not visible) |
| `NetSuite_Value_Map__mdt` + 18 records | Custom Metadata (new) | Salesforce → NetSuite values (form, category, terms, price level, taxable, contact role, Boomi source, subsidiary, currency) and eligible Sales Channel / Sector pairs. NetSuite internal IDs blank until NetSuite access works |
| `NetSuiteLogger`, `NetSuiteClient` + tests | Apex (new) | Logger writes NetSuite errors to API Log (Integration = NetSuite); client = Tax ID duplicate check, create Customer, create Contact, reusing the existing login helper and `NetSuite_Sandbox` |
| `NetSuiteOAuth2HelperES256` | Apex (changed) | Two debug lines added earlier that day (logged the full token and doubled login calls) removed; 53 safe `NetSuiteAuth |` debug lines added (no token, key or JWT logged). No existing line changed |
| `AccountTriggerHandler`, `ContactTriggerHandler` | Apex (changed, approved by the user) | Skip Shopify when `Skip_Shopify_Sync__c` is ticked: Company insert, Store Location update, Contact insert, Contact update. 4 conditions added, nothing else changed |
| `ShopifySkipGuardTest` | Apex test (new) | Proves flagged records are not queued for Shopify and normal records still are |
| `NetSuiteOAuth2Helper`, `NetSuiteOAuthHelper`, `NetSuite_Credential__mdt` (+ record), remote site `NetSuite_JWT_Signer_Site`, external credential `Netsuite_Sync`, named credential `NetSuite_JWT_Signer` | Removed by the user | Not used by any class, trigger, flow, component, schedule or credential (verified before and after removal). Repository copies of the two classes and the credential layout removed to match |

## Pre-check
- Pages and both trigger handlers were retrieved from the sandbox before editing; the sandbox versions (newer than the repository) were used and backed up.
- Baseline: 434 of 434 tests in the 37 Account / Contact / Lead / Shopify test classes passed before the guard.

## Verification
- Fields, access, formula (`Created In` = Shopify / Not created on existing Leads) and section order confirmed by query and by retrieving the deployed pages.
- `NetSuiteClientTest` + `NetSuiteLoggerTest`: 11/11, coverage 99% / 100%.
- Guard: 418/418 tests passed in the check-only deploy (37 existing classes + `ShopifySkipGuardTest`); coverage `AccountTriggerHandler` 98%, `ContactTriggerHandler` 100%.
- All NetSuite classes compile. 5 methods in `NetSuiteOAuth2HelperES256Test` fail in the sandbox with the production code too: the sandbox config Scope lacks `rest_platform` and the Platform Cache partition `NetSuite` does not exist (environment, not code).
- NetSuite login still returns HTTP 500 `server_error` (NetSuite-side M2M setup after the NetSuite sandbox refresh); the new debug trail shows Salesforce completes every step up to the token request.

## Rollback
Redeploy the previous `AccountTriggerHandler`, `ContactTriggerHandler`, `NetSuiteOAuth2HelperES256` and the four pages from git history; delete `ShopifySkipGuardTest`, `NetSuiteClient(Test)`, `NetSuiteLogger(Test)`, `NetSuite_Value_Map__mdt` and the 15 new fields (none hold data yet). The removed unused NetSuite items can be restored from git history if ever needed.
