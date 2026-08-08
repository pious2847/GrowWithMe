/**
 * Demo-day kit: seeds the demo accounts, warms the server, checks credits.
 * Usage: node scripts/demo_seed.js [--env atlas-credentials.env] [--lng -1.0713] [--lat 10.8625]
 *
 * Idempotent — run it as often as you like (e.g. right before presenting).
 */
const path = require('path');
const envFile = process.argv.includes('--env')
  ? process.argv[process.argv.indexOf('--env') + 1]
  : '.env';
require('dotenv').config({ path: path.join(__dirname, '..', envFile) });
// Fill in anything the chosen env file lacks (e.g. provider API keys for the
// credit checks live in .env while Mongo lives in atlas-credentials.env).
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
require('dns').setServers(['8.8.8.8', '1.1.1.1']);

const axios = require('axios');
const mongoose = require('mongoose');
const User = require('../src/models/User');

const arg = (name, fallback) =>
  process.argv.includes(name)
    ? parseFloat(process.argv[process.argv.indexOf(name) + 1])
    : fallback;

// Default demo center: the dev team's real test location.
const LNG = arg('--lng', -1.0713351);
const LAT = arg('--lat', 10.8625197);

const NURSE = {
  phone: '233506294654',
  name: 'Farid Mohammed',
  tier: 'nurse',
  license: 'NMC-DEMO-2026-001',
};
const CAREGIVER = { phone: '233544782975', name: 'Sulemana Mohammed' };

async function seed() {
  const uri = process.env.MONGO_URI || process.env.MONGODB_URI;
  await mongoose.connect(uri);
  console.log(`[seed] connected to ${mongoose.connection.name}`);

  // Verified nurse ~1 km from the demo point, on duty, fresh heartbeat —
  // the tiered router should pick her over anyone else nearby.
  const nurse = await User.findOneAndUpdate(
    { phone: NURSE.phone },
    {
      phone: NURSE.phone,
      name: NURSE.name,
      role: 'volunteer',
      available: true,
      region: 'Upper East',
      district: 'Bolgatanga',
      location: { type: 'Point', coordinates: [LNG + 0.008, LAT + 0.004] },
      lastSeenAt: new Date(),
      'credentials.tier': NURSE.tier,
      'credentials.status': 'verified',
      'credentials.verifiedAt': new Date(),
      'credentials.licenseNumber': NURSE.license,
      'consent.patientConfidentiality': true,
      'consent.dataProcessing': true,
      'consent.consentedAt': new Date(),
    },
    { new: true, upsert: true, setDefaultsOnInsert: true }
  );
  console.log(`[seed] nurse ready: ${nurse.name} (${nurse.phone}) — ${nurse.credentials.tier}, ${nurse.credentials.status}, on duty ~1 km from demo point`);

  // Demo caregiver: exists with consents, so OTP login goes straight to the app.
  const cg = await User.findOneAndUpdate(
    { phone: CAREGIVER.phone },
    {
      phone: CAREGIVER.phone,
      name: CAREGIVER.name,
      role: 'caregiver',
      language: 'en',
      region: 'Upper East',
      district: 'Bolgatanga',
      'consent.dataProcessing': true,
      'consent.locationOnUrgent': true,
      'consent.smsReminders': true,
      'consent.consentedAt': new Date(),
    },
    { new: true, upsert: true, setDefaultsOnInsert: true }
  );
  console.log(`[seed] caregiver ready: ${cg.name} (${cg.phone})`);
  await mongoose.disconnect();
}

async function warmup() {
  const base = (process.env.PUBLIC_URL || 'https://growwithme.onrender.com').replace(/\/$/, '');
  try {
    const t = Date.now();
    await axios.get(`${base}/health`, { timeout: 90000 });
    console.log(`[warmup] server awake in ${((Date.now() - t) / 1000).toFixed(1)}s — ${base}`);
  } catch (e) {
    console.log(`[warmup] FAILED to reach ${base}/health: ${e.message}`);
  }
}

async function credits() {
  if (process.env.ARKESEL_API_KEY) {
    try {
      const r = await axios.get('https://sms.arkesel.com/api/v2/clients/balance-details', {
        headers: { 'api-key': process.env.ARKESEL_API_KEY },
        timeout: 15000,
      });
      console.log(`[credits] Arkesel SMS: ${JSON.stringify(r.data.data || r.data)}`);
    } catch (e) {
      console.log(`[credits] Arkesel check failed (${e.response ? e.response.status : e.message})`);
    }
  } else {
    console.log('[credits] Arkesel: no ARKESEL_API_KEY in this env file — check the Render dashboard');
  }
  if (process.env.ELEVENLABS_API_KEY) {
    try {
      const r = await axios.get('https://api.elevenlabs.io/v1/user/subscription', {
        headers: { 'xi-api-key': process.env.ELEVENLABS_API_KEY },
        timeout: 15000,
      });
      const left = r.data.character_limit - r.data.character_count;
      console.log(`[credits] ElevenLabs voice: ${left} of ${r.data.character_limit} chars left (${r.data.tier}) — NOTE: verify this matches the key on Render`);
    } catch (e) {
      console.log(`[credits] ElevenLabs check failed (${e.response ? e.response.status : e.message})`);
    }
  } else {
    console.log('[credits] ElevenLabs: no ELEVENLABS_API_KEY in this env file — check the Render dashboard');
  }
}

(async () => {
  await seed();
  await warmup();
  await credits();
  console.log('\n[demo] Checklist: nurse app logged in as ' + NURSE.phone + ' and ON DUTY, ' +
    'caregiver app logged in as ' + CAREGIVER.phone + ', both phones charged, data on.');
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
