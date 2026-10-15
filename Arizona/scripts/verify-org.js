// Verifies that alias Arizona is still the expected Azlionhearts sandbox. Read-only.
// Usage: node scripts/verify-org.js
const { verifyOrg } = require('./lib/org');

try {
  const v = verifyOrg();
  console.log(`OK: ${v.alias} = ${v.name} (${v.orgId}), ${v.username}, ${v.instanceUrl}, IsSandbox=${v.isSandbox}`);
} catch (e) {
  console.error(`ORG VERIFICATION FAILED: ${e.message}`);
  process.exit(1);
}
