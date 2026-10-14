# Pre-Deployment Checklist

Copy this list into the deployment ticket and tick each item.

## Approval and scope
- [ ] REQ document exists in `03-Requirements/`
- [ ] Component list final (`Deployment-Documents/ChangeSet_Component_List.xlsx` or package `package.xml`)
- [ ] Written approval received: "Deploy to Sandbox" for the sandbox, separate sign-off for production
- [ ] Deployment window agreed; users told if pages or automation change

## Build
- [ ] Latest version retrieved from the **target** org (for production, build from production's files)
- [ ] Before-snapshot saved in `04-Change-Records/Before-Snapshots/<date>_<Change>/`
- [ ] Rollback package built and placed next to the package (`_ROLLBACK`)
- [ ] No unapproved sandbox-only work in the package (R12, Fulfillment, YTD/inactivity, Tiers fields)
- [ ] No secrets in the package (NetSuite credentials, tokens)

## Dependencies
- [ ] Picklist values exist and are active in the target org (pages and filters fail otherwise)
- [ ] New values added to the record types that need them
- [ ] Referenced users are active (team records)
- [ ] Classes and objects referenced by the package exist in the target (e.g. `ShopifyAssociationRetryBatch` isn't in production)
- [ ] Order agreed for metadata vs data: in production, load the data **before** the cluster fix, or plan to restore manual clusters (see `05-Conflicts` CON-021)

## Validation
- [ ] Check-only deploy passed (`--dry-run` / `deploy validate`)
- [ ] Production: `RunSpecifiedTests`, with each test class in its own `--tests` flag
- [ ] Code coverage ≥ 75% for every changed class
- [ ] Validation job ID recorded (it's used for quick deploy)

## Data (only if data is in scope)
- [ ] Full export / DWH download taken
- [ ] V1 backup fields filled
- [ ] Pilot file ready (one record per mapping)
- [ ] Rollback file ready
