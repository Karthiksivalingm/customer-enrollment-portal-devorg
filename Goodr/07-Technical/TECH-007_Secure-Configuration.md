# TECH-007 — Secure Configuration

| | |
|---|---|
| **ID** | TECH-007 |
| **Last updated** | 2026-10-19 |

Integration credentials live **only in the org**. They are never stored in this repository.

| Record (in the org) | Purpose | Secret fields | Other fields |
|---|---|---|---|
| `NetSuite_Credential__mdt.NetSuite_Sandbox_Credential` | NetSuite token-based auth | Consumer_Key__c, Consumer_Secret__c, Token_Id__c, Token_Secret__c | Account_Id__c, Realm__c |
| `NetSuite_Config__mdt.Default_Config` | NetSuite OAuth 2.0 machine-to-machine | Private_Key__c, Client_Id__c, Certificate_Id__c | Account_Id__c, Scope__c |
| `Shopify_Configuration__c` records | Shopify Admin API per channel / country | Shopify_Access_Token__c | Name, Shopify_Endpoint__c |
| `Typeform_Config__c` org default | Typeform API | Personal_Access_Token__c | n/a |

## Protections in this repository
- `.gitignore` stops git from tracking the two NetSuite custom metadata records.
- `.forceignore` stops the CLI from deploying or retrieving them, so a local file can never overwrite the values in the org.

## To set or change a credential
Setup → Custom Metadata Types → *NetSuite Credential* / *NetSuite Config* → Manage Records → edit. Never paste values into chat, documents or commits.

## Recommended improvements (org changes, need approval)
1. **Rotate** the NetSuite sandbox keys (Consumer Secret, Token Secret, certificate / private key). They were briefly committed to an earlier repository ([CON-014](../05-Conflicts/CON-014_Security-NetSuite-Credential-Custom-Metadata-Was-Committed-To.md)). Rotation is done by a NetSuite admin.
2. **Move the secrets into Named Credentials / External Credentials.** Salesforce encrypts them there, and they can't be read by SOQL or retrieved as metadata. The NetSuite classes already call `callout:NetSuite_Sandbox`.
3. If they stay in custom metadata for now, mark the records **Protected** (currently not protected) and limit who can see the custom metadata types.
4. `NetSuiteOAuth2Helper` has the NetSuite Client ID and Certificate ID hard-coded. These are identifiers, not secrets, but they belong in the same configuration record.
