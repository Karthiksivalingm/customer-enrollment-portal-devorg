# Post-Deployment Checklist

## Immediately after
- [ ] Deploy status is **Succeeded**; deploy ID recorded in a CR document (`04-Change-Records/`)
- [ ] Specified tests passed; note any failures that were already failing before this deployment (e.g. `ShopifyOrderSyncTest`, sandbox only)
- [ ] Changed flows are on the expected version and **Active**

## Functional checks (use `QA-Testing/`)
- [ ] Cluster: create or edit one record per mapping on Account, Lead and Opportunity, and check the Cluster
      (Key Account = 1, Planned = 5, Self Service = 6, Distributor = 7, Partnerships = 8)
- [ ] Sector-only change recalculates the Cluster
- [ ] Team: Account Team, Opportunity Team, Contact Team and Lead Team show the expected roles (`QA_Cluster_Team_Assignment_Reference.xlsx`)
- [ ] Account save cascades Sales Channel / Sector to open Opportunities without errors
- [ ] Record pages show the correct sections for each Sales Channel / Sector (`QA_LRP_Sections_by_SalesChannel_Sector.xlsx`)
- [ ] V1 fields are visible, and only admins can edit them
- [ ] Lead from a Typeform (US and Canada) is created and assigned. Canada gets Specialty
- [ ] Reports that filter on Sales Channel / Sector still return rows (check the where-used workbook)

## Data (if a load ran)
- [ ] Success and error files saved
- [ ] Report comparing V1 fields with the current values shows only the expected changes
- [ ] Error rows fixed or rolled back with the rollback file

## Close-out
- [ ] Evidence saved in `Post-Deployment-Verification/`
- [ ] New issues recorded as CON documents (`05-Conflicts/`)
- [ ] `07-Technical/` updated if behaviour changed (re-run `scripts/doc-builders/build_technical_docs.ps1`)
- [ ] Changes committed and pushed to GitHub
- [ ] Monitor Setup → Apex Jobs and Flow error emails for 24 hours
