# 06-Deployment

Standing procedures plus one dated record per validation or deployment: `YYYY-MM-DD-DEP-NNN-<slug>.md`
(`node scripts/new-doc.js DEP "<title>"`, template [config/templates/DEP.md](../config/templates/DEP.md)).
A DEP record or plan is **not** an approval. Production is never a target from this repository.

| Document | Purpose |
|---|---|
| [Deployment-Procedure.md](Deployment-Procedure.md) | Steps from approved requirement to verified deployment in the Arizona sandbox |
| [Pre-Deployment-Checklist.md](Pre-Deployment-Checklist.md) | Checks before any validation or deployment |
| [Post-Deployment-Verification.md](Post-Deployment-Verification.md) | Checks after a deployment |
| [Rollback-Procedures.md](Rollback-Procedures.md) | How to back out a deployment (only with approval) |
| [Deployment-History.md](Deployment-History.md) | One row per validation or deployment actually run |
