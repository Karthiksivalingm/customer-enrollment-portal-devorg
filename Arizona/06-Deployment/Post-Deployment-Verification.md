# Post-Deployment Verification

| # | Check | Evidence to record |
|---|---|---|
| 1 | Deploy status Succeeded | Deploy ID and `sf project deploy report` output (sanitized) |
| 2 | Tests passed with required coverage | Test run ID, pass/fail counts, coverage |
| 3 | Components present at the expected version | Re-retrieve; `git diff` shows no unexpected difference |
| 4 | Acceptance criteria met | Steps performed and results, per REQ |
| 5 | Related automation unaffected | Spot checks of Flows/triggers on the same objects |
| 6 | Experience sites still render (if site components changed) | Page checked, result |
| 7 | Documentation updated | DEP, Deployment-History, Change-History, technical documents |
