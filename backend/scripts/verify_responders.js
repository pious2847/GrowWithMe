/**
 * Admin tool: review and verify responder registrations.
 *
 * List the review queue:   node scripts/verify_responders.js --env atlas-credentials.env
 * Approve:                 node scripts/verify_responders.js --env atlas-credentials.env --approve 233506294654 [--tier nurse] [--note "checked license"]
 * Reject:                  node scripts/verify_responders.js --env atlas-credentials.env --reject 233506294654 --note "license photo unreadable"
 */
const path = require('path');
const envFile = process.argv.includes('--env')
  ? process.argv[process.argv.indexOf('--env') + 1]
  : '.env';
require('dotenv').config({ path: path.join(__dirname, '..', envFile) });
require('dns').setServers(['8.8.8.8', '1.1.1.1']);

const mongoose = require('mongoose');
const User = require('../src/models/User');

const TIERS = ['volunteer', 'chw', 'nurse', 'midwife', 'doctor'];
const argAfter = (name) =>
  process.argv.includes(name) ? process.argv[process.argv.indexOf(name) + 1] : null;

function normalizePhone(p) {
  let s = String(p).replace(/[\s\-+]/g, '');
  if (s.startsWith('0')) s = '233' + s.slice(1);
  return s;
}

async function main() {
  await mongoose.connect(process.env.MONGO_URI || process.env.MONGODB_URI);
  console.log(`[verify] connected to ${mongoose.connection.name}\n`);

  const approve = argAfter('--approve');
  const reject = argAfter('--reject');
  const note = argAfter('--note');
  const tier = argAfter('--tier');

  if (approve || reject) {
    const phone = normalizePhone(approve || reject);
    const user = await User.findOne({ phone });
    if (!user) throw new Error(`No user with phone ${phone}`);
    if (tier && !TIERS.includes(tier)) throw new Error(`tier must be one of: ${TIERS.join(', ')}`);
    user.credentials.status = approve ? 'verified' : 'rejected';
    if (approve) user.credentials.verifiedAt = new Date();
    if (tier) user.credentials.tier = tier;
    if (note) user.credentials.note = note;
    await user.save();
    console.log(
      `${approve ? '✅ VERIFIED' : '⛔ REJECTED'} ${user.name || '(no name)'} (${user.phone}) — tier ${user.credentials.tier}` +
        (note ? ` — note: ${note}` : '')
    );
  } else {
    const pending = await User.find({ role: 'volunteer', 'credentials.status': 'pending' })
      .sort({ updatedAt: -1 })
      .lean();
    if (!pending.length) {
      console.log('Review queue is empty — no pending responders. 🎉');
    } else {
      console.log(`${pending.length} responder(s) awaiting review:\n`);
      for (const u of pending) {
        const c = u.credentials || {};
        console.log(`• ${u.name || '(no name)'} — ${u.phone}`);
        console.log(`    claims: ${c.tier || 'volunteer'}   license no: ${c.licenseNumber || '—'}   region: ${u.region || '—'} / ${u.district || '—'}`);
        for (const d of c.documents || []) console.log(`    doc [${d.kind}]: ${d.url}`);
        console.log(`    approve: node scripts/verify_responders.js --env ${envFile} --approve ${u.phone}${c.tier ? ' --tier ' + c.tier : ''}`);
        console.log('');
      }
    }
  }
  await mongoose.disconnect();
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
