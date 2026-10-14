## What and why
<!-- One or two sentences. Link the requirement: REQ-0xx in DOCUMENT-INDEX.md#03--requirements -->

## Components changed
<!-- e.g. ApexClass:ClusterRuleEngine, FlexiPage:Account_Company_Record_Page -->

## Checklist
- [ ] Retrieved the latest version from the org first (manifest `<version>68.0</version>`)
- [ ] Before-snapshot saved in `04-Change-Records/Before-Snapshots/<date>_<change>/`
- [ ] Check-only deploy passed. Dry-run ID:
- [ ] Deployed after approval ("Deploy to Sandbox"). Deploy ID:
- [ ] Verified after the deploy (`06-Deployment/Post-Deployment-Checklist.md`); evidence saved
- [ ] CR-0xx change record added in `04-Change-Records/` and listed in `DOCUMENT-INDEX.md`
- [ ] Conflicts / requirements / technical docs updated if affected
- [ ] No credentials in the change (the pre-commit hook passed)
- [ ] Existing working logic unchanged
