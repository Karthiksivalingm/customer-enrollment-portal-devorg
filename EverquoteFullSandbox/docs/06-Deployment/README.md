# Deployment

| File | Use |
|---|---|
| [Pre-Deployment-Checklist.md](Pre-Deployment-Checklist.md) | Before every validate or deploy |
| [Post-Deployment-Checklist.md](Post-Deployment-Checklist.md) | After every deploy |
| [Deployment-Commands.md](Deployment-Commands.md) | `sf` CLI commands for retrieve, validate, deploy, test and scheduled jobs |
| [Deployment-Log-Template.md](Deployment-Log-Template.md) | Copy into `Deployment-Logs/DEP-YYYY-MM-DD-nn.md` for each deployment |
| [Deployment-Logs/](Deployment-Logs/) | History of deployments |

**Deployment path:** feature branch → validate in the target org → approval → quick deploy → post-deployment checks → merge to `main` and tag the release.
