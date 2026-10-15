# Pre-Deployment Checklist

Copy this list into the deployment log (`Deployment-Logs/DEP-YYYY-MM-DD-nn.md`) and tick each item.

## Scope and approvals
- [ ] Requirement (REQ) and change record (CR) exist and are linked.
- [ ] The component list is final. Use a dedicated manifest (`manifest/<release>.xml`), not the wildcard `manifest/package.xml`.
- [ ] Business or QA sign-off is recorded.
- [ ] The deployment window is agreed. Avoid business hours for changes to Lead or Opportunity automation.
- [ ] Approval to deploy is recorded, with who approved it and when.

## Source and code quality
- [ ] The branch is up to date with `main`, and merge conflicts are resolved (see [05-Conflicts](../DOCUMENT-INDEX.md)).
- [ ] `npm run prettier:verify` and `npm run lint` pass.
- [ ] There are no hardcoded record, user or queue Ids, and no hardcoded endpoints, in changed code.
- [ ] Every changed trigger or object has been checked against [Known-Conflicts](../DOCUMENT-INDEX.md), including multiple triggers, workflow field updates and flows on the same field.

## Dependencies and target org
- [ ] Retrieve the target org's current version of each component as a **backup**: `sf project retrieve start -x manifest/<release>.xml -o <target> -r backup/<date>`
- [ ] Compare the target org with the repo for drift. Did someone change it directly in the org?
- [ ] Dependent metadata exists in the target org: fields, record types, queues, custom settings and metadata, and Named Credentials or Remote Site Settings for ODA and other callouts.
- [ ] Scheduled or batch Apex that will change is identified. Abort its scheduled jobs before deploying, or the deployment will fail.
- [ ] Flows: the new version is ready, and you know which version to activate.
- [ ] Profiles and permission sets: deploy only the relevant permissions, because deploying a full profile overwrites it.

## Validation
- [ ] Run a validate-only deploy with tests:
  `sf project deploy validate -x manifest/<release>.xml -o <target> -l RunSpecifiedTests -t <TestClass1> -t <TestClass2>`
  (use `-l RunLocalTests` for production when required)
- [ ] Coverage is at least 75% org-wide and per trigger, with a target of 85% or more for changed classes.
- [ ] Save the validation Id for a quick deploy.
- [ ] The rollback plan is written in the CR.
