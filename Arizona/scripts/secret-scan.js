// Scans files for credential-like values. Prints file, line and rule only; never the matched value.
// Usage: node scripts/secret-scan.js [paths...]   (default: the whole Arizona folder, minus ignored state)
// Exit code 1 when a finding is not listed in config/secret-scan-allowlist.json.
const fs = require('fs');
const path = require('path');
const { ROOT } = require('./lib/org');

const RULES = [
  ['private-key', /-----BEGIN [A-Z ]*PRIVATE KEY-----/],
  ['aws-access-key', /\bAKIA[0-9A-Z]{16}\b/],
  ['google-api-key', /\bAIza[0-9A-Za-z_-]{35}\b/],
  ['github-token', /\bgh[pousr]_[A-Za-z0-9]{36,}\b/],
  ['slack-token', /\bxox[abprs]-[A-Za-z0-9-]{10,}/],
  ['sfdx-auth-url', /force:\/\/[^\s'"]+@/],
  ['salesforce-session-id', /\b00D[A-Za-z0-9]{12,15}![A-Za-z0-9._]{40,}/],
  ['bearer-literal', /['"]Bearer [A-Za-z0-9._~+\/-]{20,}=*['"]/],
  ['api-key-header-literal', /['"](api-key|x-api-key|apikey)['"]\s*,\s*['"](?!\{)[A-Za-z0-9._-]{16,}['"]/i],
  ['basic-auth-literal', /['"]Basic [A-Za-z0-9+\/]{16,}=*['"]/],
  ['hardcoded-secret-assignment', /\b(password|passwd|secret|client_secret|api_?key|access_?token|webhook_?key|shared_?key)\w*\s*=\s*['"][^'"\s{]{12,}['"]/i],
  ['xml-secret-element', /<(password|consumerSecret|clientSecret|secret|token|apiKey|privateKey)>[^<{]{8,}<\//i],
  ['jwt', /\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}/],
];
const SKIP_DIRS = new Set(['.git', '.sf', '.sfdx', '.arizona-state', 'node_modules']);
const BINARY = /\.(png|jpe?g|gif|ico|zip|pdf|woff2?|ttf|eot|otf|mp4|resource)$/i;

const allow = (() => {
  try { return JSON.parse(fs.readFileSync(path.join(ROOT, 'config', 'secret-scan-allowlist.json'), 'utf8')).allow || []; }
  catch (_) { return []; }
})();
const allowed = (rel, rule) => allow.some(a => a.file === rel && a.rule === rule);

function* walk(p) {
  const st = fs.statSync(p);
  if (st.isFile()) { yield p; return; }
  for (const e of fs.readdirSync(p, { withFileTypes: true })) {
    if (e.isDirectory() && SKIP_DIRS.has(e.name)) continue;
    yield* walk(path.join(p, e.name));
  }
}

const targets = process.argv.slice(2).map(p => path.resolve(p));
const findings = [];
for (const t of targets.length ? targets : [ROOT]) {
  for (const f of walk(t)) {
    if (BINARY.test(f) || fs.statSync(f).size > 5e6) continue;
    const rel = path.relative(ROOT, f).split(path.sep).join('/');
    if (rel === 'scripts/secret-scan.js') continue;
    fs.readFileSync(f, 'utf8').split(/\r?\n/).forEach((line, i) => {
      for (const [rule, re] of RULES) if (re.test(line)) findings.push({ rel, line: i + 1, rule, ok: allowed(rel, rule) });
    });
  }
}
for (const x of findings) console.log(`${x.ok ? 'ALLOWED' : 'FINDING'} ${x.rel}:${x.line} [${x.rule}]`);
const bad = findings.filter(x => !x.ok);
console.log(bad.length ? `${bad.length} unallowed finding(s).` : 'No unallowed findings.');
process.exit(bad.length ? 1 : 0);
