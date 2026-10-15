# Manual Configuration Checklist

Settings that the Metadata API does not deploy (or that this project does not deploy) must be listed in the DEP record and done by hand,
then verified. Common items:

- [ ] Named / external credential **secrets** and principal access (entered in Setup; never in source).
- [ ] Queue membership, public group membership, role assignments.
- [ ] Permission set assignments to users.
- [ ] Flow activation, when the DEP record says so.
- [ ] Scheduled Apex jobs (`System.schedule`) and their schedules.
- [ ] Email deliverability, org-wide email addresses, email services addresses.
- [ ] Remote site / CSP settings for new endpoints.
- [ ] Any Setup change made by hand in the sandbox during the build (record each one in the REQ).

Record each item as *Done by <person> on <date>* with evidence, or *Not needed*.
