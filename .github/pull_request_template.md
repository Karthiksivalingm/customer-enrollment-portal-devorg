## What and why
<!-- One or two sentences. Link the requirement: REQ-0xx in 03_Requirements/Requirements_Log.md -->

## Components changed
<!-- e.g. ApexClass:ClusterRuleEngine, FlexiPage:Account_Company_Record_Page -->

## Checklist
- [ ] Retrieved the latest version from the org first (manifest `<version>68.0</version>`)
- [ ] Before-snapshot saved in `04_Change_Records/Metadata_Before_Snapshots/<date>_<change>/`
- [ ] Check-only deploy passed. Dry-run ID:
- [ ] Deployed after approval ("Deploy to Sandbox"). Deploy ID:
- [ ] Verified after the deploy (`06_Deployment/Post_Deployment_Checklist.md`); evidence saved
- [ ] CHG entry added to `04_Change_Records/Change_Log.md`
- [ ] Conflicts / requirements / technical docs updated if affected
- [ ] No credentials in the change (the pre-commit hook passed)
- [ ] Existing working logic unchanged
