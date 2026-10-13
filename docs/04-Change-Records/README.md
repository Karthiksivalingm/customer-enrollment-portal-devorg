# Change Records

Use a change record for every change made to the org or the repository: metadata, configuration or data. Each record shows exactly what was changed, with **before and after** values, so any change can be reviewed or rolled back.

- **[Change-Log.md](Change-Log.md):** the index of all change records.
- **[Change-Record-Template.md](Change-Record-Template.md):** copy it into `Records/CR-xxxx-YYYY-MM-DD.md`.

**Change types:**
- **Metadata:** Apex, triggers, flows, fields, layouts, permissions and similar.
- **Configuration:** setup changes made in the UI, such as Custom Settings, Named Credentials, queues or users.
- **Data:** record inserts, updates, deletes and mass updates. Attach the before and after export file names, and keep the exports out of Git if they contain personal data.

**Rollback rule:** every record must say how to undo the change. For data changes, take a backup export **before** the change.
