# Contributing to Goodr Salesforce

1. Read [01-Instructions/Developer-Onboarding.md](01-Instructions/Developer-Onboarding.md) and [01-Instructions/Project-Rules.md](01-Instructions/Project-Rules.md).
2. Enable the secret-blocking hook once: `git config core.hooksPath Goodr/scripts/git-hooks`.
3. Work on a branch: `git switch -c goodr/feature/REQ-0xx-short-name` (or `goodr/fix/...`, `goodr/docs/...`).
4. Follow the change process: retrieve → back up → minimal change → dry run → approval → deploy → verify → record.
5. Commit in small steps with imperative messages ("Add Planned to Company page filters").
6. Open a pull request. The template lists everything the reviewer will check. Merge to `main` once it's approved.
7. Tag production releases: `git tag -a goodr-prod-YYYY-MM-DD-<name> -m "<what was deployed>"`, then `git push --tags`.

Folder rules are in the [Goodr README](README.md#folders) and [DOCUMENT-INDEX.md](DOCUMENT-INDEX.md). Never commit credentials. Real values live only in the org
(see [Secure-Config-Templates](07-Technical/TECH-007_Secure-Configuration.md)).
