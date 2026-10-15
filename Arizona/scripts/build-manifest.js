// Builds manifest/package.xml (baseline) and manifest/batches/*.xml from .arizona-state/org-listing.json
// and the scope rules in config/arizona-project.json. Explicit member names only, no wildcards.
// Usage: node scripts/build-manifest.js
const fs = require('fs');
const path = require('path');
const { ROOT, CONFIG, STATE } = require('./lib/org');

const S = CONFIG.scope;
const L = JSON.parse(fs.readFileSync(path.join(STATE, 'org-listing.json'), 'utf8')).types;
const names = t => (L[t] ? L[t].unmanaged.map(x => x.n) : []);

const objects = [
  ...names('CustomObject').filter(n => S.customObjectSuffixes.some(s => n.endsWith(s))),
  ...S.standardObjectsWithCustomFields,
];
const objSet = new Set(objects);
const objectOf = n => n.split(/[.-]/)[0];

const members = {};
for (const t of S.includeAllUnmanaged) members[t] = names(t);
members.CustomObject = objects;
// LWR sites are DigitalExperienceBundle "site/<name>"; their ExperienceBundle listing entry cannot be retrieved.
members.DigitalExperienceBundle = members.DigitalExperienceBundle.filter(n => S.digitalExperienceBundlePrefixes.some(p => n.startsWith(p)));
const lwrSites = new Set(members.DigitalExperienceBundle.map(n => n.split('/')[1]));
members.ExperienceBundle = members.ExperienceBundle.filter(n => !lwrSites.has(n));
members.CustomField = names('CustomField').filter(n => S.extraCustomFieldsOnManagedObjects.includes(objectOf(n)));
members.Layout = names('Layout').filter(n => objSet.has(objectOf(n)));
// Global actions have no object prefix; object actions are kept only for in-scope objects.
members.QuickAction = names('QuickAction').filter(n => !n.includes('.') || objSet.has(objectOf(n)));
members.SharingRules = names('SharingRules').filter(n => objSet.has(n));
members.ReportFolder = names('ReportFolder');
members.Report = names('Report');
members.DashboardFolder = names('DashboardFolder');
members.Dashboard = names('Dashboard');
members.EmailFolder = names('EmailFolder');
// Folders are retrieved as their own component types in package.xml (Report/Dashboard/EmailTemplate with folder names).
members.Report = [...members.ReportFolder, ...members.Report];
members.Dashboard = [...members.DashboardFolder, ...members.Dashboard];
members.EmailTemplate = [...members.EmailFolder, ...members.EmailTemplate];
delete members.ReportFolder; delete members.DashboardFolder; delete members.EmailFolder;

const batches = {
  '01-code': ['ApexClass', 'ApexTrigger', 'ApexPage', 'ApexComponent', 'LightningComponentBundle', 'AuraDefinitionBundle', 'StaticResource'],
  '02-data-model': ['CustomObject', 'CustomField', 'GlobalValueSet', 'CustomMetadata', 'Layout', 'QuickAction', 'FlexiPage', 'CustomTab', 'CustomApplication'],
  '03-automation': ['Flow', 'Workflow', 'AssignmentRules', 'AutoResponseRules', 'EscalationRules', 'DuplicateRule', 'MatchingRule', 'PlatformEventChannel', 'Queue'],
  '04-security-integration': ['PermissionSet', 'CustomPermission', 'SharingRules', 'NamedCredential', 'ExternalCredential', 'RemoteSiteSetting', 'CspTrustedSite', 'ConnectedApp'],
  '05-reports-email': ['ReportType', 'Report', 'Dashboard', 'EmailTemplate'],
  '06-experience': ['Network', 'CustomSite', 'ExperienceBundle', 'DigitalExperienceBundle'],
};

const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const xml = types => {
  const body = types.filter(t => members[t] && members[t].length).sort().map(t =>
    '    <types>\n' + [...new Set(members[t])].sort().map(m => `        <members>${esc(m)}</members>\n`).join('') +
    `        <name>${t}</name>\n    </types>\n`).join('');
  return `<?xml version="1.0" encoding="UTF-8"?>\n<Package xmlns="http://soap.sforce.com/2006/04/metadata">\n${body}    <version>68.0</version>\n</Package>\n`;
};

const all = Object.values(batches).flat();
const missing = Object.keys(members).filter(t => !all.includes(t));
if (missing.length) throw new Error('Types without a batch: ' + missing.join(', '));
fs.mkdirSync(path.join(ROOT, 'manifest', 'batches'), { recursive: true });
fs.writeFileSync(path.join(ROOT, 'manifest', 'package.xml'), xml(all));
for (const [b, types] of Object.entries(batches)) fs.writeFileSync(path.join(ROOT, 'manifest', 'batches', `${b}.xml`), xml(types));
for (const t of all) console.log(`${t}: ${(members[t] || []).length}`);
