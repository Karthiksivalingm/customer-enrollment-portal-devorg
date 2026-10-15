# Deployment Procedure (Arizona sandbox)

1. An approved REQ exists and describes the change. Create a DEP record: `node scripts/new-doc.js DEP "<title>"`.
2. `node scripts/verify-org.js` — stop on failure.
3. Build `manifest/releases/DEP-NNN-package.xml` listing exactly the components to deploy.
4. Back up the current org version:
   `sf project retrieve start --manifest manifest/releases/DEP-NNN-package.xml --target-org Arizona --output-dir .arizona-state/backup/DEP-NNN`.
5. Complete the [Pre-Deployment-Checklist.md](Pre-Deployment-Checklist.md) and record the results in the DEP.
6. Validate (check-only):
   `sf project deploy validate --manifest manifest/releases/DEP-NNN-package.xml --test-level RunSpecifiedTests --tests <Tests> --target-org Arizona`.
   Record the validation ID.
7. **Stop and obtain the user's explicit approval** of this exact deployment and target. Record who, when and where in the DEP.
8. Deploy: `sf project deploy quick --job-id <validationId> --target-org Arizona` (or `deploy start` with the same manifest and tests).
9. Run [Post-Deployment-Verification.md](Post-Deployment-Verification.md). Record the actual results.
10. Update the DEP statuses, [Deployment-History.md](Deployment-History.md), `07-Technical-Documents/Change-History.md` and any affected documents.

Production deployments follow a separate, human-controlled release process and are never run from this repository.
