# Rollback Procedures

Rollback is itself a deployment and needs the user's explicit approval of the exact operation and target.

1. Record the problem in a CF record with the evidence.
2. Use the backup retrieved before the deployment (`.arizona-state/backup/DEP-NNN`) or the previous Git commit of the affected source.
3. Validate the rollback package (check-only) against the Arizona sandbox; record the validation ID.
4. After approval, deploy the rollback package. Components introduced by the deployment are removed with a destructive manifest
   (`destructiveChanges.xml`), also only with approval.
5. Flows: re-activate the previous version instead of deleting the new one where possible.
6. Data changes are not rolled back by a metadata deployment; any data correction needs its own CR record and approval.
7. Verify, then update the DEP, the CF and [Deployment-History.md](Deployment-History.md).
