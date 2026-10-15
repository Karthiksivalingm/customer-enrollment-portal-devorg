# CON-001: Hardcoded credentials and secrets in metadata

| Field | Value |
|---|---|
| Status | ⚠ Open |
| Severity | 🔴 High |
| Found | 2026-10-13 (classes and workflow), 2026-10-15 (static resource and Named Credential) |
| Related | [TECH-007](../07-Technical/TECH-007_Apex-Voice-and-CTI.md) · [TECH-008](../07-Technical/TECH-008_Apex-Cheatsheets.md) · [TECH-019](../07-Technical/TECH-019_Integrations.md) · [CR-002](../04-Change-Records/CR-002_Move-To-SFDC-Repo-And-Full-Retrieve.md) |

## What
| Where | What is exposed |
|---|---|
| `classes/NotifyCTI.cls` | Basic-auth username and password for the CTI Picker service (`adh8.com`) |
| `classes/LeadCheatsheetController.cls`, `classes/OpportunityCheatsheetController.cls` | The same Basic-auth credential, for the Cheat Sheet service |
| `workflows/Contact.workflow-meta.xml` | Delighted webhook URLs with secret tokens in the path (3 outbound messages) |
| `staticresources/zoom_key.txt` | A 64-character Zoom key, in a static resource with **Public** cache control |
| `namedCredentials/ExecuteAwsService.namedCredential-meta.xml` | AWS access key Id. The secret key isn't in the metadata. |

## Decision
On 2026-10-15 the project owner chose to push the metadata to sfdcut/SFDC **as-is**, so these values are readable by everyone with access to the repository, including in Git history.

## Recommended remediation
1. Ask the owners of the CTI Picker, Cheat Sheet, Delighted, Zoom and AWS integrations to **rotate** each credential.
2. Move the Basic-auth credential into a Named Credential or External Credential, and change the 3 classes to `callout:<name>`.
3. Replace `zoom_key` with a protected Custom Setting or External Credential, and remove the public static resource.
4. Delete the orphaned Delighted outbound messages if they're no longer used.
5. Once rotated, the old values in Git history are harmless. Rewriting history isn't necessary after rotation.
