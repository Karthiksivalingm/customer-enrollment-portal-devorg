# Web-to-Lead enrollment form (second enrollment channel)

A static HTML/JavaScript version of the Customer Enrollment form. It posts to the
**standard Salesforce Web-to-Lead endpoint** and creates one Lead that looks and
behaves exactly like an Experience Cloud enrollment Lead: same Contacts panel,
path, Convert Lead modal and conversion.

It is an **embeddable form**: no site header, hero or footer. It is meant to sit
inside the client's existing page (in an iframe), below their own navigation, and
it adapts to the width it is given. It also works on its own for testing.

These files are **not Salesforce metadata** and are never deployed. The client
hosts them as static files.

```
Client web page
  -> <iframe> with this form (index.html)
  -> https://webto.salesforce.com/servlet/servlet.WebToLead   (posted from the browser)
  -> EnrollmentWebToLeadTrigger (before insert)
  -> EnrollmentWebToLeadService: validates, rebuilds Enrollment_People__c (schema v1)
  -> one standard Lead
  -> Salesforce redirects the iframe to thank-you.html
```

## Files

| File | Purpose |
| --- | --- |
| `index.html` | The form: 3-step progress (Company, Contacts, Review) and the form card only |
| `styles.css` | Styles based on the Experience Cloud enrollment LWCs, compact and fluid |
| `app.js` | Steps, validation, 2-25 Contact cards, review, and the Web-to-Lead post |
| `embed.js` | Iframe support: reports the form height and step to the host page |
| `countries.js` | Country and state/province list generated from the org's picklists |
| `thank-you.html` | Confirmation shown after Salesforce accepts the post (`retURL`) |
| `embed-demo.html` | Demo of a client page embedding the form (not part of the form) |

## Run locally

From the repository root:

```
npx http-server web-to-lead -p 8080
```

- **Form on its own:** open http://localhost:8080/. After Submit, the browser
  goes to Salesforce and then back to `http://127.0.0.1:8080/thank-you.html`.
- **Embedded demo:** start a second server so the host page has a different
  origin, like a real client site:

  ```
  npx http-server web-to-lead -p 8081
  ```

  Then open
  http://localhost:8081/embed-demo.html?formUrl=http%3A%2F%2F127.0.0.1%3A8080%2Findex.html
  (`?formUrl=` overrides the placeholder iframe address; demo only).

The return URL uses `127.0.0.1` on purpose. Salesforce returns an empty page with
no redirect when `retURL` uses the host `localhost`; this was verified in
EnrollmentDev. A real website domain is used unchanged.

**Local iframe limitation:** when the form is submitted **inside an iframe**
locally, the Lead is saved, but Chrome shows "127.0.0.1 is blocked" instead of the
thank-you page. Chrome's local-network protection stops a public site
(webto.salesforce.com) from sending an embedded frame to a local address. This
does not apply when `thank-you.html` is hosted on a public HTTPS domain. Submit
from the stand-alone page to test the thank-you redirect locally.

## Host the form

1. Copy `index.html`, `styles.css`, `app.js`, `embed.js`, `countries.js` and
   `thank-you.html` to one folder on any static web host or CDN, served over
   **HTTPS** (for example `https://forms.client.com/enrollment/`). No server code
   is needed.
2. Keep the files together: `thank-you.html` must sit next to `index.html`,
   because the return URL is built from the form's own address.
3. The form host must **allow framing** by the client site. Do not send
   `X-Frame-Options: DENY`/`SAMEORIGIN`; if a `Content-Security-Policy` is used,
   set `frame-ancestors https://www.client.com`.
4. If the client site has a `Content-Security-Policy`, its `frame-src` must
   allow the form host.
5. Do not include `embed-demo.html` in production.

The URL the client embeds is the hosted `index.html`, for example
`https://forms.client.com/enrollment/index.html`.

## Embed it with an iframe

Minimum embed code (fixed height; the frame scrolls if the form is taller):

```html
<iframe
  src="https://forms.client.com/enrollment/index.html"
  title="Customer Enrollment Form"
  width="100%"
  height="1100"
  frameborder="0"
></iframe>
```

Replace the `src` with the hosted form URL. The form is responsive, so only the
width needs to be `100%`.

### Automatic height (optional, recommended)

The form reports its own height to the host page with `postMessage`
(`embed.js`). Add this script after the iframe to resize it to the content and to
bring the form back into view when the step changes (copy it from
`embed-demo.html`):

```html
<iframe id="enrollment-form" src="https://forms.client.com/enrollment/index.html"
  title="Customer Enrollment Form" width="100%" height="1100" frameborder="0"
  style="display:block;border:0"></iframe>
<script>
  (function () {
    var frame = document.getElementById("enrollment-form");
    var formOrigin = new URL(frame.src, location.href).origin;
    window.addEventListener("message", function (event) {
      if (event.origin !== formOrigin || event.source !== frame.contentWindow) return;
      var data = event.data || {};
      if (data.type === "ep-enrollment-form:height" && data.height > 0) {
        frame.style.height = Math.ceil(data.height) + "px";
      } else if (data.type === "ep-enrollment-form:step" || data.type === "ep-enrollment-form:submitted") {
        if (frame.getBoundingClientRect().top < 0) {
          frame.scrollIntoView({ behavior: "smooth", block: "start" });
        }
      }
    });
  })();
</script>
```

Messages sent by the form (they contain no form data):

| Message `type` | When |
| --- | --- |
| `ep-enrollment-form:height` (`height` in px) | On load and whenever the content height changes (step change, contacts added or removed, errors shown) |
| `ep-enrollment-form:step` (`step`) | When the visitor moves to Company, Contacts or Review |
| `ep-enrollment-form:submitted` | When the thank-you page loads |

### Iframe sizing limitations

- **Without the script:** the iframe stays at its fixed `height`. A tall form
  (many contacts, narrow screens) then scrolls inside the frame. The 3-step form
  with 2 contacts is about 790-1,120 px tall depending on width; each extra
  contact adds roughly 350-450 px.
- **Automatic height needs the client's page to run the script above;** a
  plain iframe cannot size itself.
- **When embedded,** the form does not scroll the host page itself; the script
  scrolls the iframe into view on step changes. Without the script, the visitor
  scrolls the host page to the top of the form.

## Configuration (`app.js`, `CONFIG`)

| Setting | EnrollmentDev value | Notes |
| --- | --- | --- |
| `orgId` | `00Dfj00000LNKYD` | 15-character org id |
| `fieldIds.submissionKey` | `00Nfj00005epNc9` | `Lead.Enrollment_Submission_Key__c` |
| `fieldIds.payload` | `00Nfj00005fnVN4` | `Lead.Enrollment_W2L_Payload__c` |

Custom fields are posted by field id. In another org, read the ids with:

```
sf data query --use-tooling-api --target-org <alias> --query "SELECT Id, DeveloperName FROM CustomField WHERE TableEnumOrId = 'Lead' AND DeveloperName IN ('Enrollment_Submission_Key','Enrollment_W2L_Payload')"
```

Use the first 15 characters of each id.

## What is posted

| Form data | Web-to-Lead parameter | Lead field |
| --- | --- | --- |
| Company name | `company` (and `last_name`) | Company (LastName is set again server-side) |
| Company email | `email` | Email |
| Company phone | `phone` | Phone |
| Website | `URL` | Website |
| Address, City, Postal code | `street`, `city`, `zip` | Street, City, PostalCode |
| Country, State / Province | `country_code`, `state_code` | CountryCode, StateCode |
| UUID generated per page load | custom field id | Enrollment_Submission_Key__c |
| Contacts | custom field id | Enrollment_W2L_Payload__c (temporary) |

The Contacts payload uses the existing schema v1 format:

```json
{"schemaVersion":1,"people":[{"firstName":"Asha","lastName":"Rao","email":"asha@example.com","phone":"+91 98765 43210","role":"Primary Contact"}]}
```

Role values are the API values (`AP` is shown as "Account Payable"). IDs P01-P25
are assigned by Salesforce.

## What Salesforce does with it (`EnrollmentWebToLeadService`)

- **Validates everything again** with the same `EnrollmentValidator` as the
  Experience channel: company fields, country/state, 2-25 Contacts, names,
  emails, phones, Roles, duplicate Contact emails, and the UUID.
- **Rebuilds the enrollment fields** with the existing serializer:
  `Enrollment_People__c`, `Enrollment_Person_Count__c`,
  `Enrollment_Submitted_At__c`, the key (lowercased), `LastName`, `LeadSource`.
  Values posted for these fields are ignored. Unknown JSON properties are dropped.
- **Labels the Lead** `Enrollment_Channel__c = Web-to-Lead` (set server-side)
  and clears the payload field.
- **Rejects invalid submissions,** so no Lead is created. Web-to-Lead still shows
  the thank-you page, because it cannot report server-side errors to the
  browser. Salesforce emails a Web-to-Lead failure notice instead.

Existing automation also applies:

- **Duplicate company email:** `LeadHandler` rejects it (no Lead).
- **Follow-up Task:** one is created per Lead.
- **Owner:** the active "Standard" assignment rule assigns the owner. In
  EnrollmentDev that is `epic.03921cf52625@orgfarm.salesforce.com`, which is
  also the Web-to-Lead creator.

## Regenerate `countries.js`

`countries.js` mirrors `EnrollmentAddressOptions`: active values only, with
states grouped by their controlling country. Regenerate it if the org's State
and Country Picklists change.

1. Run `sf sobject describe --sobject Lead --target-org EnrollmentDev --json > lead.json`.
2. Build `window.EP_COUNTRIES` from `CountryCode` and `StateCode` (decode each
   state's base64 `validFor` bitmap, most significant bit first).

## Verified limits (EnrollmentDev, real endpoint)

- **Payload size:**
  - **Accepted intact:** 16,000, 32,000, 32,768, 40,000 and 65,536 characters.
  - **Rejected:** 131,072 characters, with HTTP 400 and no Lead.
  - **Real need:** 25 Contacts with every value at maximum length is 7,630 characters.
- **Daily cap:** Salesforce Web-to-Lead allows 500 submissions per day.

## Before the client hosts it

- **Spam protection:** turn on reCAPTCHA (Setup > Web-to-Lead) and, if wanted,
  the Web-to-Lead spam filter. The browser honeypot and 3-second minimum only
  stop simple bots.
- **Branding:** the form carries no logo or site chrome; colours are set by the
  `--ep-color-*` variables at the top of `styles.css` and can be matched to the
  client's brand.
- **Return URL:** host `thank-you.html` next to `index.html` on a public HTTPS
  domain (`retURL` follows the page automatically). The thank-you redirect
  inside an iframe has not been verified on a public domain yet; do one test
  submission after hosting.
- **Security limitation:** read the note in the technical documentation /
  `EnrollmentWebToLeadService` header about spoofed enrollment fields.

## Change log: embeddable redesign

- **Modified:**
  - `index.html`: removed the header, hero/banner and footer; the form card is all that remains.
  - `thank-you.html`: removed the header and footer; it reports its height to the host page.
  - `styles.css`: removed the header, hero and footer styles; fluid `.ep-embed` wrapper (max 880 px), transparent page background, compact spacing, extra rules for very narrow containers.
  - `app.js`: removed the footer year; when embedded, a step change notifies the host page instead of scrolling. Salesforce submission code is unchanged.
  - `README.md`.
- **Created:** `embed.js`, `embed-demo.html`.
