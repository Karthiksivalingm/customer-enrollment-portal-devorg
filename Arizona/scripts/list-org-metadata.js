// Lists the org's metadata for the in-scope types and writes .arizona-state/org-listing.json. Read-only.
// Usage: node scripts/list-org-metadata.js
const fs = require('fs');
const path = require('path');
const { CONFIG, STATE, sf, verifyOrg } = require('./lib/org');

const alias = CONFIG.org.alias;
const S = CONFIG.scope;
const types = [...new Set([...S.includeAllUnmanaged, ...S.objectScopedTypes, 'CustomObject', 'CustomField'])]
  .filter(t => t !== 'EmailTemplate');
const folderTypes = [['Report', 'ReportFolder'], ['Dashboard', 'DashboardFolder'], ['EmailTemplate', 'EmailFolder']];

const unmanaged = r => !r.namespacePrefix && (!r.manageableState || r.manageableState === 'unmanaged');
const slim = r => ({ n: r.fullName, created: r.createdDate, modified: r.lastModifiedDate });
const list = (t, folder) => {
  const args = ['org', 'list', 'metadata', '--metadata-type', t, '--target-org', alias];
  if (folder) args.push('--folder', `"${folder}"`);
  const r = sf(args) || [];
  return Array.isArray(r) ? r : [r];
};

verifyOrg();
const out = { listedAt: new Date().toISOString(), orgId: CONFIG.org.orgId, types: {} };
for (const t of types) {
  const r = list(t);
  out.types[t] = { total: r.length, unmanaged: r.filter(unmanaged).map(slim) };
  console.log(`${t}: ${r.length} total, ${out.types[t].unmanaged.length} unmanaged`);
}
const excluded = S.excludedReportFolderPatterns.map(p => new RegExp(p));
for (const [t, ft] of folderTypes) {
  const folders = list(ft).filter(unmanaged).map(f => f.fullName);
  const keepFolders = folders.filter(f => !excluded.some(re => re.test(f)));
  out.types[ft] = { total: folders.length, unmanaged: keepFolders.map(n => ({ n })) };
  const items = [];
  for (const f of keepFolders) items.push(...list(t, f).filter(unmanaged).map(slim));
  out.types[t] = { total: items.length, unmanaged: items };
  console.log(`${t}: ${items.length} in ${keepFolders.length} in-scope folders (${folders.length - keepFolders.length} folders excluded)`);
}
fs.mkdirSync(STATE, { recursive: true });
fs.writeFileSync(path.join(STATE, 'org-listing.json'), JSON.stringify(out, null, 1));
console.log('Wrote .arizona-state/org-listing.json');
