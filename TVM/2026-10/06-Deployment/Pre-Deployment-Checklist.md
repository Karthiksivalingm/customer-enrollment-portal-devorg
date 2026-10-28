# Pre-Deployment Checklist

Copy into the DEP record and mark each item with the result and evidence.

- [ ] `python scripts/verify_org.py` passes (Org ID `00DVa000006Eh6TMAS`, `IsSandbox = true`).
- [ ] All REQ records in scope are approved for build; acceptance criteria are written.
- [ ] Component inventory is complete, in dependency order, and every API name was checked against the org or source.
- [ ] Release manifest written: `manifest/releases/DEP-NNN-package.xml` (and destructive changes, if any).
- [ ] Every component was retrieved fresh before editing (no stale local copies).
- [ ] Backup of the current target versions saved to `06-Deployment/Backups/DEP-NNN/`.
- [ ] Dependencies exist in the target first (fields, picklist values, permission sets, named credentials, custom metadata types).
- [ ] Automation on the same objects reviewed for conflicts and order of execution.
- [ ] Relevant test classes named; check-only validation passed; validation ID recorded; coverage recorded.
- [ ] Flow activation state for each Flow in scope is stated (activate / leave as is).
- [ ] Manual configuration steps listed ([Manual-Configuration-Checklist.md](Manual-Configuration-Checklist.md)).
- [ ] Rollback steps written for each component, including what cannot be reversed.
- [ ] Secret scan passes (`python scripts/secret_scan.py --all`).
- [ ] Explicit approval of this exact operation and target recorded in the DEP record.
