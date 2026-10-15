// Generates 07-Technical-Documents/Metadata-Inventory.md from force-app/main/default and rebuilds DOCUMENT-INDEX.md.
// Reads local files only. Usage: node scripts/build-inventory.js
const fs = require('fs');
const path = require('path');
const { ROOT } = require('./lib/org');

const SRC = path.join(ROOT, 'force-app', 'main', 'default');
const rel = p => path.relative(ROOT, p).split(path.sep).join('/');
const ls = d => (fs.existsSync(d) ? fs.readdirSync(d).sort() : []);
const read = p => fs.readFileSync(p, 'utf8');
const tag = (x, t) => { const m = x.match(new RegExp(`<${t}>([\\s\\S]*?)</${t}>`)); return m ? m[1].trim() : ''; };
const tags = (x, t) => [...x.matchAll(new RegExp(`<${t}>([\\s\\S]*?)</${t}>`, 'g'))].map(m => m[1].trim());
const cell = s => String(s ?? '').replace(/\|/g, '\\|').replace(/\r?\n/g, ' ');
const link = (label, p) => `[${label}](../${rel(p)})`;
const table = (head, rows) => rows.length
  ? `| ${head.join(' | ')} |\n|${head.map(() => '---').join('|')}|\n${rows.map(r => `| ${r.map(cell).join(' | ')} |`).join('\n')}\n`
  : '_None retrieved._\n';

const out = [];
const counts = {};
const section = (title, n, body) => { counts[title] = n; out.push(`## ${title} (${n})\n\n${body}`); };

// Apex classes
{
  const d = path.join(SRC, 'classes');
  const rows = ls(d).filter(f => f.endsWith('.cls')).map(f => {
    const src = read(path.join(d, f));
    const meta = fs.existsSync(path.join(d, f + '-meta.xml')) ? read(path.join(d, f + '-meta.xml')) : '';
    const sharing = (src.match(/\b(with|without|inherited) sharing\b/i) || ['—'])[0];
    const kind = /@isTest/i.test(src) ? 'Test' : /implements\s+[^{]*Database\.Batchable/i.test(src) ? 'Batch'
      : /implements\s+[^{]*Schedulable/i.test(src) ? 'Schedulable' : /@RestResource/i.test(src) ? 'REST resource'
      : /@InvocableMethod/i.test(src) ? 'Invocable' : /@AuraEnabled/i.test(src) ? 'Aura/LWC controller'
      : /implements\s+[^{]*Queueable/i.test(src) ? 'Queueable' : /HttpRequest|Http\(\)/.test(src) ? 'Callout' : 'Class';
    return [link(f.replace('.cls', ''), path.join(d, f)), kind, sharing, tag(meta, 'apiVersion'), tag(meta, 'status'), src.split('\n').length];
  });
  section('Apex classes', rows.length, table(['Class', 'Kind (heuristic)', 'Sharing', 'API', 'Status', 'Lines'], rows));
}
// Triggers
{
  const d = path.join(SRC, 'triggers');
  const rows = ls(d).filter(f => f.endsWith('.trigger')).map(f => {
    const src = read(path.join(d, f));
    const m = src.match(/trigger\s+\w+\s+on\s+(\w+)\s*\(([^)]*)\)/i) || [];
    const meta = read(path.join(d, f + '-meta.xml'));
    return [link(f.replace('.trigger', ''), path.join(d, f)), m[1] || '', (m[2] || '').replace(/\s+/g, ' '), tag(meta, 'status'), tag(meta, 'apiVersion')];
  });
  section('Apex triggers', rows.length, table(['Trigger', 'Object', 'Events', 'Status', 'API'], rows));
}
// Flows
{
  const d = path.join(SRC, 'flows');
  const rows = ls(d).filter(f => f.endsWith('.flow-meta.xml')).map(f => {
    const x = read(path.join(d, f));
    const start = tag(x, 'start');
    return [link(f.replace('.flow-meta.xml', ''), path.join(d, f)), tag(x, 'label'), tag(x, 'processType'), tag(x, 'status'),
      tag(start, 'object') || '—', [tag(start, 'triggerType'), tag(start, 'recordTriggerType')].filter(Boolean).join(' / ') || '—'];
  });
  section('Flows', rows.length, table(['Flow', 'Label', 'Type', 'Status', 'Object', 'Trigger'], rows));
}
// Objects
{
  const d = path.join(SRC, 'objects');
  const rows = ls(d).filter(o => fs.statSync(path.join(d, o)).isDirectory()).map(o => {
    const od = path.join(d, o);
    const mf = path.join(od, `${o}.object-meta.xml`);
    const x = fs.existsSync(mf) ? read(mf) : '';
    const fields = ls(path.join(od, 'fields'));
    const custom = fields.filter(f => /__c\.field-meta\.xml$/.test(f)).length;
    return [link(o, mf), tag(x, 'label') || '—', fields.length, custom, ls(path.join(od, 'recordTypes')).length,
      ls(path.join(od, 'validationRules')).length, ls(path.join(od, 'listViews')).length, tag(x, 'sharingModel') || '—'];
  });
  section('Objects', rows.length, table(['Object', 'Label', 'Fields (retrieved)', 'Custom fields', 'Record types', 'Validation rules', 'List views', 'Sharing model'], rows));
}
// Validation rules
{
  const d = path.join(SRC, 'objects');
  const rows = [];
  for (const o of ls(d)) for (const f of ls(path.join(d, o, 'validationRules'))) {
    const x = read(path.join(d, o, 'validationRules', f));
    rows.push([link(`${o}.${f.replace('.validationRule-meta.xml', '')}`, path.join(d, o, 'validationRules', f)), tag(x, 'active'), tag(x, 'errorMessage')]);
  }
  section('Validation rules', rows.length, table(['Rule', 'Active', 'Error message'], rows));
}
// Record types
{
  const d = path.join(SRC, 'objects');
  const rows = [];
  for (const o of ls(d)) for (const f of ls(path.join(d, o, 'recordTypes'))) {
    const x = read(path.join(d, o, 'recordTypes', f));
    rows.push([`${o}.${f.replace('.recordType-meta.xml', '')}`, tag(x, 'label'), tag(x, 'active')]);
  }
  section('Record types', rows.length, table(['Record type', 'Label', 'Active'], rows));
}
// LWC and Aura
{
  const d = path.join(SRC, 'lwc');
  const rows = ls(d).filter(b => fs.statSync(path.join(d, b)).isDirectory() && !b.startsWith('.')).map(b => {
    const mf = path.join(d, b, `${b}.js-meta.xml`);
    const x = fs.existsSync(mf) ? read(mf) : '';
    return [link(b, path.join(d, b)), tag(x, 'masterLabel') || '—', tag(x, 'isExposed'), tags(x, 'target').join(', ') || '—'];
  });
  section('Lightning Web Components', rows.length, table(['Bundle', 'Label', 'Exposed', 'Targets'], rows));
  const a = path.join(SRC, 'aura');
  const arows = ls(a).filter(b => fs.statSync(path.join(a, b)).isDirectory()).map(b => [link(b, path.join(a, b)), ls(path.join(a, b)).join(', ')]);
  section('Aura components', arows.length, table(['Bundle', 'Files'], arows));
}
// Permission sets
{
  const d = path.join(SRC, 'permissionsets');
  const rows = ls(d).map(f => {
    const x = read(path.join(d, f));
    return [link(f.replace('.permissionset-meta.xml', ''), path.join(d, f)), tag(x, 'label'), tags(x, 'objectPermissions').length,
      tags(x, 'fieldPermissions').length, tags(x, 'classAccesses').length, tags(x, 'userPermissions').length, tag(x, 'license') || '—'];
  });
  section('Permission sets', rows.length, table(['Permission set', 'Label', 'Object perms', 'Field perms', 'Class access', 'User perms', 'License'], rows));
}
// Everything else: names per folder
const DONE = new Set(['classes', 'triggers', 'flows', 'objects', 'lwc', 'aura', 'permissionsets']);
for (const folder of ls(SRC).filter(f => !DONE.has(f))) {
  const d = path.join(SRC, folder);
  const names = [];
  const walk = (p, prefix) => {
    for (const e of ls(p)) {
      const full = path.join(p, e);
      if (fs.statSync(full).isDirectory()) {
        if (['experiences', 'aura', 'lwc'].includes(folder) || folder === 'staticresources') names.push(prefix + e); else walk(full, prefix + e + '/');
      } else if (/-meta\.xml$/.test(e)) names.push(prefix + e.replace(/\.[^.]+-meta\.xml$/, ''));
    }
  };
  walk(d, '');
  const uniq = [...new Set(names)];
  section(`Folder \`${folder}\``, uniq.length, uniq.map(n => `- ${n}`).join('\n') + '\n');
}

const summary = table(['Section', 'Count'], Object.entries(counts).map(([k, v]) => [k, v]));
const header = `# Metadata Inventory\n\n> Generated by \`node scripts/build-inventory.js\` from \`force-app/main/default\`. Do not edit by hand.\n` +
  `> Reflects the local source, which mirrors the Arizona sandbox as of the last retrieval ` +
  `(see [Retrieval](Retrieval/) and [Change-History.md](Change-History.md)). "Kind" for Apex is a keyword heuristic.\n\n## Summary\n\n${summary}\n`;
fs.writeFileSync(path.join(ROOT, '07-Technical-Documents', 'Metadata-Inventory.md'), header + out.join('\n'));

// DOCUMENT-INDEX.md: every Markdown document outside force-app and generated state.
const docs = [];
const walkDocs = p => {
  for (const e of ls(p)) {
    const full = path.join(p, e);
    if (['force-app', 'node_modules', '.sf', '.sfdx', '.arizona-state', '.git'].includes(e)) continue;
    if (fs.statSync(full).isDirectory()) walkDocs(full);
    else if (e.endsWith('.md') && e !== 'DOCUMENT-INDEX.md') {
      const t = (read(full).match(/^#\s+(.+)$/m) || [, e])[1];
      docs.push([rel(full), t]);
    }
  }
};
walkDocs(ROOT);
const groups = {};
for (const [p, t] of docs) (groups[p.includes('/') ? p.split('/')[0] : '(root)'] ||= []).push(`- [${t}](${p})`);
const index = `# Arizona Document Index\n\n> Generated by \`node scripts/build-inventory.js\`. Lists every Markdown document in the Arizona project.\n\n` +
  Object.keys(groups).sort().map(g => `## ${g}\n\n${groups[g].join('\n')}\n`).join('\n');
fs.writeFileSync(path.join(ROOT, 'DOCUMENT-INDEX.md'), index);
console.log('Inventory:', Object.entries(counts).map(([k, v]) => `${k}=${v}`).join(', '));
console.log(`Index: ${docs.length} documents`);
