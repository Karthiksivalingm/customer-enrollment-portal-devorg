# Contributing to Goodr Salesforce

1. Read [01_Instructions/Developer_Onboarding.md](01_Instructions/Developer_Onboarding.md) and [01_Instructions/Working_Instructions.md](01_Instructions/Working_Instructions.md).
2. Enable the secret-blocking hook once: `git config core.hooksPath scripts/git-hooks`.
3. Work on a branch: `git switch -c feature/REQ-0xx-short-name` (or `fix/...`, `docs/...`).
4. Follow the change process: retrieve → back up → minimal change → dry run → approval → deploy → verify → record.
5. Commit in small steps with imperative messages ("Add Planned to Company page filters").
6. Open a pull request. The template lists everything the reviewer will check. Merge to `main` once it's approved.
7. Tag production releases: `git tag -a prod-YYYY-MM-DD-<name> -m "<what was deployed>"`, then `git push --tags`.

Folder rules are in the [root README](README.md#folders). Never commit credentials. Real values live only in the org
(see [Secure_Config_Templates](07_Technical_Documents/Secure_Config_Templates/README.md)).
