# Conflicts

| File | Contents |
|---|---|
| [Known-Conflicts.md](Known-Conflicts.md) | **Possible** conflicts found in the current metadata: overlapping automation, order-of-execution risks, hardcoded Ids and integration dependencies |
| [Conflict-Log.md](Conflict-Log.md) | Conflicts **faced** while working, with root cause and resolution |
| [Merge-Conflict-Guide.md](Merge-Conflict-Guide.md) | How to resolve Git and metadata merge conflicts in this repo |

**Kinds of conflict to watch for:**
1. **Automation:** several triggers, flows, workflow rules or processes acting on the same object or field.
2. **Order of execution:** Salesforce doesn't guarantee the order of multiple triggers for the same event.
3. **Metadata and environment:** the sandbox has drifted from production, someone changed the org directly, or deploying a profile overwrote permissions.
4. **Source control:** two people changed the same file. Profiles, permission sets and flows are the most frequent cases.
5. **Data and locking:** `UNABLE_TO_LOCK_ROW`, batches running at the same time, or round-robin assignment races.
6. **Integration:** ODA or Odie callout failures, a missing Named Credential, or callouts made after uncommitted DML.
