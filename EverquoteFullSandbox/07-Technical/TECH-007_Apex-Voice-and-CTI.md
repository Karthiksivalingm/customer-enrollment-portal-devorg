# Voice & CTI

## NotifyCTI

- **Purpose:** Tell the external agent CTI picker to refresh activity data.
- **Entry point:** `global class`; `@future(callout=true) public static void sendUpdate(String activity)`.
- **Callout:**

| Item | Value |
|---|---|
| Endpoint (prod) | `https://agents-cti-picker-prod.adh8.com/refreshactivity/{activity}` |
| Endpoint (sandbox) | `https://agents-cti-picker-staging.adh8.com/refreshactivity/{activity}` – chosen when `URL.getSalesforceBaseUrl().getHost()` starts with `cs` |
| Method / timeout | POST, 10 s, no body |
| Auth | `Authorization: BASIC base64('[REDACTED – see NotifyCTI.cls:16]')` – **credentials hardcoded in code**; no Named Credential |

- **Callers:** `TaskHandler.notifyCTI()` (`'task'`). `EventNotifyCTI` trigger call to `'event'` is commented out.
- **Risks:** Sandbox detection by `cs` host prefix is obsolete for enhanced-domain sandboxes (`*.sandbox.my.salesforce.com`) – sandboxes may call the **prod** endpoint. `URL.getSalesforceBaseUrl()` is deprecated. Response not checked. Requires Remote Site Setting for `adh8.com` hosts (not in this source).
- **Test:** covered via TaskHandlerTest (mock).

## AutoPopulateContactOnVoiceCall

- **Purpose:** Link `VoiceCall` records to the matching Contact/Account by phone. (June 2024.)
- **Trigger:** `VoiceCallTrigger` (Active) – before insert → `searchContactThroughRecipientNumber`; before update → `searchContactThroughRecipientNumberAfterUpdate` (only when To/From number changed).
- **Public methods:** `comparePhoneNumber(List<VoiceCall>)`, `searchContactThroughRecipientNumber`, `searchContactThroughRecipientNumberAfterUpdate(List, Map)`.
- **Logic:** strips the first 2 chars (e.g. `+1`) of `ToPhoneNumber` and `FromPhoneNumber`, queries Contacts where `Phone` or `MobilePhone` in those values, sets `VoiceCall.Contact__c` and `VoiceCall.Account__c`.
- **Objects/fields:** VoiceCall `Contact__c`, `Account__c`, `ToPhoneNumber`, `FromPhoneNumber`; Contact `Phone`, `MobilePhone`, `AccountId`.
- **Risks:** `FromPhoneNumber.substring(2)` has no null check (NPE if blank while To is set). If a Contact matches by MobilePhone but also has a non-matching Phone, `map.get(Phone)` returns null → NPE. Exact-string match only (formatted numbers like `(555) 555-1234` won't match). Multiple Contacts per number: last wins.
- **Test:** TestAutoPopulateContactOnVoiceCall (no assertions).

## SendEmailForMissedCallAlertVC

Documented in Case-and-Email.md.
