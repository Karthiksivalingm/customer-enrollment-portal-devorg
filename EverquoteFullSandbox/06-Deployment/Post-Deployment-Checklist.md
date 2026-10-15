# Post-Deployment Checklist

## Immediately after deployment
- [ ] The deployment status is **Succeeded**. Record the deployment Id in the log.
- [ ] Re-schedule any scheduled Apex that was aborted before the deployment (see [Deployment-Commands](Deployment-Commands.md)).
- [ ] Activate the correct flow versions and deactivate the old ones if needed.
- [ ] Complete manual steps that can't be deployed: Custom Settings and Metadata values, Named Credential secrets, queue members, email service addresses, picklist value assignments to record types, and permission set assignments.

## Smoke test (in the target org)
- [ ] Create or update a test record for each affected object and confirm the expected automation ran.
- [ ] Check Lead assignment and round robin, plus owner sync to Odie, if Lead automation changed.
- [ ] Check an ODA quote or rate request for the affected carriers if ODA classes changed.
- [ ] Check CTI and Voice Call linking if Task, Event or VoiceCall automation changed.
- [ ] Look in **Setup → Apex Jobs** and the debug logs for new errors.
- [ ] Check **Setup → Email → Deliverability** settings and the Apex exception emails.

## Monitoring (24 to 48 hours)
- [ ] There are no new Apex exception emails or failed batch jobs.
- [ ] Users report no issues. Record any issues in the [Conflict Log](../DOCUMENT-INDEX.md).

## Close-out
- [ ] Update the requirement status to **Deployed** and fill in "Deployed on".
- [ ] Update the change record with the deployment Id.
- [ ] Merge the branch to `main` and tag the release: `git tag release-YYYY-MM-DD`.
- [ ] Update the [Technical Documents](../DOCUMENT-INDEX.md) for every changed component.
