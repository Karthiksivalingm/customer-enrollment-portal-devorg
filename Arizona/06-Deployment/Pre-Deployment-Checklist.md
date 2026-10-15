# Pre-Deployment Checklist

| # | Check | How |
|---|---|---|
| 1 | Target is the Arizona sandbox | `node scripts/verify-org.js` passes; command uses `--target-org Arizona` (never `PROD`) |
| 2 | Approved REQ and DEP exist | Links in the DEP record |
| 3 | Org version not changed since the last retrieve | Retrieve the components and compare with `git diff` |
| 4 | Dependencies included | Fields, permission sets, custom metadata, labels referenced by the change |
| 5 | Tests identified | Test classes covering every changed class/trigger and other automation on the same objects |
| 6 | Active Flows and triggers on affected objects reviewed | [Automation-and-Processes.md](../02-Knowledge-Base/Automation-and-Processes.md) |
| 7 | No secrets in the deployment files | `node scripts/secret-scan.js <paths>` |
| 8 | Backup retrieved | `.arizona-state/backup/DEP-NNN` |
| 9 | Manual steps listed | In the DEP record |
| 10 | Explicit user approval recorded | DEP "Approval" status |
