# TECH-007 — Secure Configuration

| | |
|---|---|
| **ID** | TECH-007 |
| **Last updated** | 2026-10-14 |

Integration credentials live **only in the org**. These templates show the structure of the records that hold them, with every value replaced
by `SET_IN_ORG__<field>`. A developer can see which fields exist without seeing any secret.

| Record (in the org) | Template | Secret fields |
|---|---|---|
| `NetSuite_Credential__mdt.NetSuite_Sandbox_Credential` (TBA) | [NetSuite_Credential.NetSuite_Sandbox_Credential.template.xml](Secure-Config-Templates/NetSuite_Credential.NetSuite_Sandbox_Credential.template.xml) | Consumer_Key, Consumer_Secret, Token_Id, Token_Secret |
| `NetSuite_Config__mdt.Default_Config` (OAuth 2.0 M2M) | [NetSuite_Config.Default_Config.template.xml](Secure-Config-Templates/NetSuite_Config.Default_Config.template.xml) | Private_Key, Client_Id, Certificate_Id |
| `Shopify_Configuration__c` records (custom setting / data) | n/a, not metadata | Shopify_Access_Token__c |
| `Typeform_Config__c` org default (custom setting) | n/a, not metadata | Personal_Access_Token__c |

## Protections in this repo
- `.gitignore` stops git from tracking the real NetSuite records.
- `.forceignore` stops the CLI from deploying or retrieving them, so local placeholder files can never overwrite the org.
- `scripts/git-hooks/pre-commit` blocks commits that contain these files or secret-looking values. Enable it once per clone:
  `git config core.hooksPath Goodr/scripts/git-hooks`

## To set or change a credential
Setup → Custom Metadata Types → *NetSuite Credential* / *NetSuite Config* → Manage Records → edit. Never paste values into chat, documents or commits.

## Recommended improvements (org changes, need approval)
1. **Rotate** the NetSuite sandbox keys (Consumer Secret, Token Secret, certificate / private key). They were in this repo's first commits on 12 Oct 2026. Rotation is done by a NetSuite admin.
2. **Move the secrets into Named Credentials / External Credentials.** Salesforce encrypts them there, and they can't be read by SOQL or retrieved as metadata. The NetSuite classes already call `callout:NetSuite_Sandbox`.
3. If they stay in custom metadata for now, mark the records **Protected** (`<protected>true</protected>`, currently `false`) and limit who can see the custom metadata types.
4. `NetSuiteOAuth2Helper` has the NetSuite Client ID and Certificate ID hard-coded. These are identifiers, not secrets, but should move into the same configuration record.
