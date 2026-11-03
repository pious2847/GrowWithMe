'use strict';

/**
 * End-to-end smoke test against a throwaway local database.
 *
 * Exercises the parts that unit tests cannot: real Express routing, Mongo
 * indexes (including the action TTL and facility uniqueness), bulk facility
 * import idempotency, action-event idempotency/export and OTP abuse limits.
 *
 * Run:
 *   node scripts/smoke_backend.js
 *
 * Uses mongodb://127.0.0.1:27017/growwithme_smoke and DROPS that database.
 * SMS is forced into dev mode. Never point MONGODB_URI at real data.
 */

process.env.NODE_ENV = 'test';
process.env.MONGODB_URI =
  process.env.SMOKE_MONGODB_URI || 'mongodb://127.0.0.1:27017/growwithme_smoke';
process.env.ARKESEL_API_KEY = '';
process.env.RATE_LIMIT_DISABLED = 'false';

const assert = require('assert');
const mongoose = require('mongoose');

const app = require('../src/app');
const User = require('../src/models/User');
const { signAccessToken } = require('../src/utils/jwt');

if (!/growwithme_smoke/.test(process.env.MONGODB_URI)) {
  throw new Error('Refusing to run: MONGODB_URI must point at the growwithme_smoke database');
}

async function main() {
  await mongoose.connect(process.env.MONGODB_URI);
  await mongoose.connection.dropDatabase();
  for (const name of mongoose.modelNames()) {
    await mongoose.model(name).createIndexes();
  }
  console.log('db ready:', mongoose.connection.name);

  const admin = await User.create({
    phone: '233240000001',
    name: 'Smoke Admin',
    role: 'admin',
  });
  const caregiver = await User.create({
    phone: '233240000002',
    name: 'Smoke Caregiver',
    role: 'caregiver',
  });
  const adminToken = signAccessToken(admin);
  const caregiverToken = signAccessToken(caregiver);

  const server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  const base = `http://127.0.0.1:${server.address().port}`;

  async function call(method, path, { token, body, raw } = {}) {
    const res = await fetch(`${base}${path}`, {
      method,
      headers: {
        ...(body ? { 'content-type': 'application/json' } : {}),
        ...(token ? { authorization: `Bearer ${token}` } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    });
    const text = await res.text();
    let json = null;
    try {
      json = JSON.parse(text);
    } catch {
      /* ndjson or html */
    }
    return { status: res.status, headers: res.headers, json, text };
  }

  const pass = [];
  function ok(name) {
    pass.push(name);
    console.log(`  ok  ${name}`);
  }

  try {
    const ready = await call('GET', '/health/ready');
    assert.strictEqual(ready.status, 200, ready.text);
    assert.strictEqual(ready.json.db, 'connected');
    ok('health/ready reports connected Mongo');

    const rows = [
      {
        name: 'Tamale Teaching Hospital',
        type: 'hospital',
        country: 'GH',
        region: 'Northern',
        district: 'Tamale Metropolitan',
        externalId: 'GH-EPI-001',
        location: { type: 'Point', coordinates: [-0.8393, 9.4008] },
      },
      {
        name: 'Kano General Hospital',
        type: 'hospital',
        country: 'NG',
        region: 'Kano',
        district: 'Kano Municipal',
        externalId: 'NG-EPI-001',
        location: { type: 'Point', coordinates: [8.5167, 12.0022] },
      },
      { name: 'Missing coordinates', type: 'clinic', country: 'GH' },
      { name: 'Wrong type', type: 'pharmacy', location: { coordinates: [0, 0] } },
    ];
    const bulk1 = await call('POST', '/api/v1/facilities/bulk', {
      token: adminToken,
      body: { facilities: rows },
    });
    assert.strictEqual(bulk1.status, 201, bulk1.text);
    assert.strictEqual(bulk1.json.accepted, 2);
    assert.strictEqual(bulk1.json.rejected, 2);
    assert.strictEqual(bulk1.json.inserted, 2);
    ok('bulk import accepts valid rows and reports rejected rows');

    const bulk2 = await call('POST', '/api/v1/facilities/bulk', {
      token: adminToken,
      body: { facilities: rows.slice(0, 2) },
    });
    assert.strictEqual(bulk2.json.inserted, 0, JSON.stringify(bulk2.json));
    assert.strictEqual(bulk2.json.matched, 2);
    ok('re-import is idempotent (no duplicates)');

    const page = await call(
      'GET',
      '/api/v1/facilities?country=GH&q=tamale&page=1&limit=10',
      { token: caregiverToken }
    );
    assert.strictEqual(page.status, 200);
    assert.strictEqual(page.json.total, 1);
    assert.strictEqual(page.json.facilities[0].externalId, 'GH-EPI-001');
    ok('facility list filters by country + name and pages');

    const nearby = await call(
      'GET',
      '/api/v1/facilities/nearby?lng=-0.84&lat=9.40&maxKm=20&country=GH',
      { token: caregiverToken }
    );
    assert.strictEqual(nearby.status, 200, nearby.text);
    assert.ok(nearby.json.facilities.length >= 1);
    assert.ok(nearby.json.facilities.every((f) => f.country === 'GH'));
    ok('nearby search uses the 2dsphere index and country filter');

    const events = {
      events: [
        {
          clientEventId: 'smoke-e1',
          sessionId: 'sess-smoke',
          screen: 'home',
          action: 'home.quick.nana',
          target: 'nana.orb',
          params: { offline: true, tab: 'home', childName: 'SHOULD_BE_DROPPED' },
          appVersion: '1.0.0',
          platform: 'android',
          country: 'GH',
          region: 'Northern',
          consentVersion: 'v1',
        },
        {
          clientEventId: 'smoke-e2',
          sessionId: 'sess-smoke',
          screen: 'calendar',
          action: 'calendar.remind_me',
          params: { step: 1 },
          appVersion: '1.0.0',
          platform: 'android',
          country: 'GH',
        },
      ],
    };
    const ingest1 = await call('POST', '/api/v1/actions/events', {
      token: caregiverToken,
      body: events,
    });
    assert.strictEqual(ingest1.status, 202, ingest1.text);
    assert.strictEqual(ingest1.json.inserted, 2);
    ok('action events batch ingests');

    const retry = await call('POST', '/api/v1/actions/events', {
      token: caregiverToken,
      body: {
        events: [
          events.events[0], // duplicate
          { clientEventId: 'smoke-e3', action: 'nana.chat.open', screen: 'nana' },
        ],
      },
    });
    assert.strictEqual(retry.status, 202, retry.text);
    assert.strictEqual(retry.json.inserted, 1);
    ok('duplicate clientEventId is idempotent');

    const ActionEvent = require('../src/models/ActionEvent');
    const stored = await ActionEvent.findOne({ clientEventId: 'smoke-e1' }).lean();
    assert.strictEqual(stored.params.childName, undefined, 'non-allow-listed param leaked');
    assert.strictEqual(stored.params.offline, true);
    ok('non-allow-listed params never reach the database');

    const summary = await call('GET', '/api/v1/actions/summary?days=7', {
      token: adminToken,
    });
    assert.strictEqual(summary.status, 200);
    assert.strictEqual(summary.json.total, 3);
    ok('action summary counts events');

    const denied = await call('GET', '/api/v1/actions/export', { token: caregiverToken });
    assert.strictEqual(denied.status, 403);
    ok('dataset export is admin-only');

    const exported = await call('GET', '/api/v1/actions/export?days=7', {
      token: adminToken,
    });
    assert.strictEqual(exported.status, 200);
    assert.ok(exported.headers.get('content-type').includes('ndjson'));
    const lines = exported.text.trim().split('\n').map((line) => JSON.parse(line));
    assert.strictEqual(lines.length, 3);
    assert.strictEqual(lines[0].sessionId, 'sess-smoke');
    assert.ok(!('user' in lines[0]), 'export leaked a user reference');
    ok('dataset export streams chronological JSONL without user references');

    const otpStatuses = [];
    for (let i = 0; i < 6; i += 1) {
      const r = await call('POST', '/api/v1/auth/request-otp', {
        body: { phone: '+233 24 000 0099' },
      });
      otpStatuses.push(r.status);
    }
    assert.deepStrictEqual(otpStatuses.slice(0, 5), [200, 200, 200, 200, 200]);
    assert.strictEqual(otpStatuses[5], 429);
    ok('OTP requests are limited per phone (5 / 15 min)');

    const fallback = await call('GET', '/api/v1/config/regions/ZZ');
    assert.strictEqual(fallback.status, 200);
    assert.strictEqual(fallback.json.fallback, true);
    assert.strictEqual(fallback.json.code, 'XX');
    ok('unknown country falls back to the international care pack');

    console.log(`\n${pass.length} backend smoke checks passed.`);
  } finally {
    await new Promise((resolve) => server.close(resolve));
    await mongoose.connection.dropDatabase();
    await mongoose.disconnect();
  }
}

main().catch((err) => {
  console.error('\nBACKEND SMOKE FAILED:', err);
  process.exit(1);
});
