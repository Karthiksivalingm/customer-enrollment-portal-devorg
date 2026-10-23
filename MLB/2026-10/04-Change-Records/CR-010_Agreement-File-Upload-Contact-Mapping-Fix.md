# CR-010 — Adobe data mapping "Agreement File Upload - Contact" fix

| | |
|---|---|
| **Change ID** | CR-010 |
| **Date** | 2026-10-06 |
| **Related** | [CON-008](../05-Conflicts/CON-008_Agreement-File-Upload-Contact-Mapping.md) |
| **Org** | utdev sandbox |
| **Method** | Data record update (not deployable metadata) |

## What changed
Record **a1EiV0000000Kd3UAE** in `echosign_dev1__SIGN_Object_Mapping__c` (the "Contact" object mapping of data mapping *Agreement File Upload - Contact*):

| Field | Before | After |
|---|---|---|
| `echosign_dev1__Field_API_Name__c` | Recipient2__c | **Recipient__c** |
| `echosign_dev1__Fully_Qualified_API__c` | echosign_dev1__Recipient2__r | **echosign_dev1__Recipient__r** |

## Verification
The user confirmed the signed PDF is now stored on the Contact.

## Production note
Check the same mapping in production. Use the Adobe mapping editor; the target object must be the agreement's **Recipient (Contact)**.
