# 01 — Automated Testing

One report per requirement: `ATR-###_<Requirement>.md`.

## Report structure
1. **Header**: ATR ID, requirement (REQ), change record (CR), org, date, tester.
2. **Scope**: components under test.
3. **Scenario results** table:

| Test ID | Scenario | Type (Apex test / API save / data check) | Run as | Input / test data | Expected result | Actual result | Result |
|---|---|---|---|---|---|---|---|

4. **Evidence**: deploy IDs, Apex test run results and coverage, query output.
5. **Cleanup**: test records and temporary components created and removed.
6. **Defects found**: none, or each with its fix.
