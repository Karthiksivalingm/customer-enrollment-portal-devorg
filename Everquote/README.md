# EverQuote — Salesforce Project

Salesforce DX project for the **EverQuote Sandbox** org (`yoursage--unitedtech.sandbox.my.salesforce.com`).

## Contents
| Path | What it holds |
|---|---|
| `force-app/` | Metadata retrieved from the EverQuote Sandbox (Apex, triggers, LWC/Aura, flows, objects, layouts, permission sets, profiles, reports, dashboards, email templates and more) |
| `manifest/package.xml` | Retrieve/deploy manifest |
| `01-Instructions` … `08-QA` | Project documentation, organised the same way as the other projects in this repository |
| `DOCUMENT-INDEX.md` | Index of every project document and the next free number per folder |

## Working with the org
```bash
sf org login web --alias "EverQuote Sandbox" --instance-url https://test.salesforce.com
sf project retrieve start --manifest manifest/package.xml --target-org "EverQuote Sandbox"
sf project deploy start --source-dir force-app --target-org "EverQuote Sandbox" --dry-run
```

Run commands from inside the `Everquote/` folder.
