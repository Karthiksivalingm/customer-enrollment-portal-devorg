# Post-Deployment Verification

Record every check in the DEP record: what was checked, as which user or profile, the expected result, the actual result and evidence.

1. **Deploy result:** `python scripts/sf_safe.py project deploy report --job-id <id>` shows *Succeeded*; component and test counts match the plan.
2. **Components present:** retrieve the deployed components and compare them with source (`git diff` should be empty after retrieval).
3. **Tests:** run the named test classes again (`python scripts/sf_safe.py apex run test --tests <T> --result-format human --code-coverage --wait 30`).
4. **Functional checks:** walk through each acceptance criterion as a user with the affected profile/permission set.
5. **Automation:** confirm the Flows in scope have the intended activation state; check for new errors (Flow error emails,
   Apex exception emails, debug logs) during the verification window.
6. **Security:** confirm the intended users have access and others do not.
7. **Integrations:** if callouts changed, confirm one successful round trip and that errors are logged as designed.
8. **Record** the outcome. A failed check gets a CF record; set the DEP *Verification* status only from evidence.
