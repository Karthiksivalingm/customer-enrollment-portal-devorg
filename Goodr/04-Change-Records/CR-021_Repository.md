# CR-021 — Repository

| | |
|---|---|
| **Change ID** | CR-021 |
| **Date** | 2026-10-12 → 2026-10-13 (12 → 13 Oct) |
| **Requirement** | [REQ-016](../03-Requirements/REQ-016_Private-GitHub-Repository.md) [REQ-017](../03-Requirements/REQ-017_Organise-Repository-Into-Seven-Sections.md) [REQ-023](../03-Requirements/REQ-023_Record-Every-Org-Change-In-GitHub.md) |
| **Org** | Git |
| **Deploy ID** | n/a |
| **By** | Assistant |
| **Status** | Done |

## What changed
- **10-12 19:27:** private GitHub repo created; commit `c2b6b3e`.
- **10-12 19:36:** organised as the "Goodr" project; commit `d591374`.
- **10-12 19:54:** 7 folders created; NetSuite credential records removed from tracking; commit `b7561dd`.
- **10-13 (repo synced to the org):** every class, trigger, flow, page and custom metadata record, plus the touched objects, fields, value sets and email templates, was retrieved from GDRSAND at API 68.0 (`manifest/retrieve/pkg_full_sync_20261013.xml`). The repo now matches the org.

  Real differences found and now fixed in the repo:
  - Shopify config: new settings in the org.
  - Warm-Off email wording.
  - `Send_Shopify_At_Risk_Notice`: the local file was a newer **undeployed** edit, now replaced by the org's active version. The old local file is still in git history at commit `b7561dd`.
  - Contact pages: fields `Account_Name_for_Email__c` and `Shopify_Company_ID_for_Email__c`.

  New in the repo: global value sets `Sales_Channel`, `Sales_Channel1` and `Sector`; Sales Channel / Sector fields on 4 objects; the `Shopify_At_Risk_Notice__c` object; the Shopify Account fields.


## Rollback
git revert.
