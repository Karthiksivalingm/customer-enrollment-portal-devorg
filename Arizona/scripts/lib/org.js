// Shared helpers: project paths, config, and the Arizona org guard. Never prints tokens.
const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const CONFIG = JSON.parse(fs.readFileSync(path.join(ROOT, 'config', 'arizona-project.json'), 'utf8'));
const STATE = path.join(ROOT, '.arizona-state');

// Run an sf command with --json and return .result. Retries transient failures.
function sf(args, { retries = 3 } = {}) {
  let last;
  for (let i = 0; i < retries; i++) {
    try {
      const out = execFileSync('sf', [...args, '--json'], {
        cwd: ROOT, encoding: 'utf8', maxBuffer: 1 << 28, shell: true, stdio: ['ignore', 'pipe', 'ignore'],
      });
      return JSON.parse(out).result;
    } catch (e) {
      last = e;
      try { const j = JSON.parse(e.stdout); if (j && j.message) last = new Error(j.message); } catch (_) {}
    }
  }
  throw last;
}

// Stop unless the alias resolves to the expected sandbox. Returns the verified identity.
function verifyOrg() {
  const o = CONFIG.org;
  const d = sf(['org', 'display', '--target-org', o.alias]);
  if (d.id !== o.orgId || d.username !== o.username) {
    throw new Error(`Alias ${o.alias} resolves to ${d.id} / ${d.username}, expected ${o.orgId} / ${o.username}. Stop.`);
  }
  const q = sf(['data', 'query', '--target-org', o.alias, '--query', '"SELECT Id, Name, IsSandbox FROM Organization"']);
  const org = q.records[0];
  if (org.IsSandbox !== true) throw new Error(`Org ${org.Id} is not a sandbox. Stop.`);
  return { alias: o.alias, orgId: d.id, username: d.username, instanceUrl: d.instanceUrl, name: org.Name, isSandbox: org.IsSandbox };
}

module.exports = { ROOT, CONFIG, STATE, sf, verifyOrg };
