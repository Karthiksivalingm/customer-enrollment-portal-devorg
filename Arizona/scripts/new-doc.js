// Creates a dated record from config/templates with the next free ID for its type.
// Usage: node scripts/new-doc.js <REQ|CR|CF|DEP> "<title>" [--key <stable-event-key>]
// Returns the existing record instead of a duplicate when the same --key (or same type, date and title) exists.
const fs = require('fs');
const path = require('path');
const { ROOT } = require('./lib/org');

const FOLDERS = { REQ: '03-Requirements', CR: '04-Change-Records', CF: '05-Conflicts', DEP: '06-Deployment' };
const [type, title, ...rest] = process.argv.slice(2);
if (!FOLDERS[type] || !title) {
  console.error('Usage: node scripts/new-doc.js <REQ|CR|CF|DEP> "<title>" [--key <event-key>]');
  process.exit(1);
}
const ki = rest.indexOf('--key');
const key = ki >= 0 ? rest[ki + 1] : '';

const now = new Date();
const pad = n => String(n).padStart(2, '0');
const date = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;
const tz = -now.getTimezoneOffset();
const stamp = `${date} ${pad(now.getHours())}:${pad(now.getMinutes())} UTC${tz >= 0 ? '+' : '-'}${pad(Math.floor(Math.abs(tz) / 60))}:${pad(Math.abs(tz) % 60)}`;
const slug = title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 60);

const dir = path.join(ROOT, FOLDERS[type]);
const re = new RegExp(`^\\d{4}-\\d{2}-\\d{2}-${type}-(\\d{3})-.*\\.md$`);
const existing = fs.readdirSync(dir).filter(f => re.test(f));
for (const f of existing) {
  const text = fs.readFileSync(path.join(dir, f), 'utf8');
  const sameKey = key && text.includes(`event_key: ${key}\n`);
  const sameTitle = f.startsWith(date) && text.includes(`title: ${title}\n`);
  if (sameKey || sameTitle) { console.log(`EXISTS ${FOLDERS[type]}/${f}`); process.exit(0); }
}
const next = Math.max(0, ...existing.map(f => +f.match(re)[1])) + 1;
const id = `${type}-${String(next).padStart(3, '0')}`;
const body = fs.readFileSync(path.join(ROOT, 'config', 'templates', `${type}.md`), 'utf8')
  .replace(/{{ID}}/g, id).replace(/{{DATE}}/g, date).replace(/{{TITLE}}/g, title)
  .replace(/{{TIMESTAMP}}/g, stamp).replace(/{{EVENT_KEY}}/g, key);
const file = `${date}-${id}-${slug}.md`;
fs.writeFileSync(path.join(dir, file), body);
console.log(`CREATED ${FOLDERS[type]}/${file}`);
