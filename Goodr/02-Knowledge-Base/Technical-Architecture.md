# KB-005 — Technical Architecture

| | |
|---|---|
| **Document ID** | KB-005 |
| **Last updated** | 2026-10-14 |

The shared [Coding-Standards.md](../01-Instructions/Coding-Standards.md) refers to this document. Its sections follow the same layout as the FD and MLB versions.
Statements marked **(to be confirmed)** haven't been checked against the org yet.

## Authentication and Authorization

### 1. Overview
All Goodr work happens in the sandbox `GDRSAND` ([KB-004](KB-004_Salesforce-Environment.md)), integrated with Shopify, NetSuite, Typeform and Zendesk ([KB-003](Integrations.md)).
Business logic sits in Apex trigger handlers and services, with record-triggered flows alongside them ([TECH-002](../07-Technical/TECH-002_Apex-Classes.md), [TECH-004](../07-Technical/TECH-004_Flows.md)).

### 2. Identity Model
- **Internal users:** sales, account management, marketing and support users. Team membership is driven by cluster ([TECH-001](../07-Technical/TECH-001_Cluster-and-Team-Engine.md)).
- **Integration user:** `integrations@goodr.com` (seen in the sandbox audit trail) (to be confirmed which integrations run as this user).
- **Shared admin login:** `sandipp@goodr.com.partial` (shown as "Ruben Smith") is used for development. Changes made under it are attributed to it in the audit trail.
- **Experience Cloud:** standard community login and self-registration controllers exist (to be confirmed whether a site is live).

### 3. Authentication Patterns
#### User Authentication
Salesforce login with MFA. Authenticator and verification-code events appear in the audit trail.

#### Integration Authentication
| Integration | Mechanism | Where the secret lives |
|---|---|---|
| NetSuite | OAuth 2.0 machine-to-machine (JWT ES256) and token-based auth; named credentials `NetSuite_Sandbox`, `NetSuite_JWT_Signer` | `NetSuite_Config__mdt`, `NetSuite_Credential__mdt`. Org only, not protected ([TECH-007](../07-Technical/TECH-007_Secure-Configuration.md)) |
| Shopify | Admin API access token per channel / country | `Shopify_Configuration__c` records |
| Typeform | Personal access token | `Typeform_Config__c` custom setting |
| Zendesk → Salesforce | Inbound Apex REST `/services/apexrest/zendeskSfWebhook/` | No signature check in `ZendeskWebhookAPI` (to be confirmed how the caller authenticates) |

### 4. Authorization Model
- Profiles and permission sets control object and field access. Example: the V1 backup fields are read/write for System Administrator only ([CR-015](../04-Change-Records/CR-015_V1-Backup-Fields.md)).
- Record access for sales teams comes from Account Team, Opportunity Team and the custom Contact Team / Lead Team objects, which `ClusterTeamEngine` assigns from `Account_Cluster_Team__mdt` (Access_Level per role).
- Apex runs `with sharing` by default. `ClusterTeamEngine` and `CaseReopenHandler` run `without sharing` by design, because they must manage team and case rows the running user may not own.
- Only 3 non-test classes enforce FLS explicitly (`WITH SECURITY_ENFORCED`, `USER_MODE` or `stripInaccessible`). This is a gap against Coding-Standards, to be handled as code is touched.

### 5. Platform Security Controls
- Field history tracking on key Account fields ([CR-004](../04-Change-Records/CR-004_Field-History-Tracking.md)).
- The Setup Audit Trail records Setup changes. Each one made for this project is recorded as a CR document.
- Deliverability and org-wide email addresses control outbound email. The Shopify notices send from the org-wide address.

### 6. Secure API Design
- Outbound callouts use named credentials where they exist (NetSuite). Shopify and Typeform build headers from stored tokens. Moving these to External Credentials is recommended ([TECH-007](../07-Technical/TECH-007_Secure-Configuration.md)).
- All callouts log to `API_Log__c` through `APILogger`. Logs must never contain tokens.
- The inbound Zendesk endpoint should validate a shared secret or signature (to be confirmed / recommended).

### 7. Governance and Operations
- Every change goes through the process in [Project-Rules.md](../01-Instructions/Project-Rules.md) and is recorded as a CR document.
- Secrets are never committed. A pre-commit hook blocks them, and an exposed secret is rotated ([CON-014](../05-Conflicts/CON-014_Security-NetSuite-Credential-Custom-Metadata-Was-Committed-To.md)).
- Changes outside the sandbox follow [Project-Rules.md](../01-Instructions/Project-Rules.md) section 7.
### 8. Recommended Baseline for Goodr
1. Rotate the NetSuite sandbox keys, then move all integration secrets to Named / External Credentials.
2. Mark any remaining secret-bearing custom metadata as Protected.
3. Add signature validation to the Zendesk webhook.
4. Enforce FLS (`WITH USER_MODE`) in classes as they are changed.
5. Use a dedicated integration user per integration, with least-privilege permission sets.
