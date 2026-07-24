const cron = require('node-cron');
const User = require('../models/User');
const Child = require('../models/Child');
const Pregnancy = require('../models/Pregnancy');
const Reminder = require('../models/Reminder');
const Alert = require('../models/Alert');
const Assessment = require('../models/Assessment');
const GrowthRecord = require('../models/GrowthRecord');
const CareSignal = require('../models/CareSignal');
const { sendSms } = require('./arkesel');
const logger = require('../utils/logger');

// Simplified WHO weight-for-age -2SD anchors (kg), matching the app's
// screening tables. Linear interpolation between anchor months.
const MINUS_2SD = {
  male: [[0, 2.5], [3, 5.0], [6, 6.4], [9, 7.1], [12, 7.7], [18, 8.8], [24, 9.7], [36, 11.3], [48, 12.7], [60, 14.1]],
  female: [[0, 2.4], [3, 4.5], [6, 5.7], [9, 6.5], [12, 7.0], [18, 8.1], [24, 9.0], [36, 10.8], [48, 12.3], [60, 13.7]],
};

function minus2sd(ageMonths, sex) {
  const table = MINUS_2SD[sex === 'female' ? 'female' : 'male'];
  if (ageMonths <= table[0][0]) return table[0][1];
  if (ageMonths >= table[table.length - 1][0]) return table[table.length - 1][1];
  for (let i = 0; i < table.length - 1; i++) {
    const [m1, w1] = table[i];
    const [m2, w2] = table[i + 1];
    if (ageMonths >= m1 && ageMonths <= m2) {
      return w1 + ((w2 - w1) * (ageMonths - m1)) / (m2 - m1);
    }
  }
  return table[table.length - 1][1];
}

async function upsertSignal({ caregiver, child = null, pregnancy = null, type, severity, message }) {
  await CareSignal.findOneAndUpdate(
    { caregiver, type, child, pregnancy },
    {
      $set: { severity, message, lastDetectedAt: new Date() },
      $setOnInsert: { status: 'open' },
    },
    { upsert: true }
  );
}

/**
 * The daily "monitor everything" scan. Each check errs toward escalation:
 * better a spurious visit than a missed emergency.
 */
async function runScan() {
  const now = new Date();
  let created = 0;

  // 1. Missed visits per caregiver
  const missed = await Reminder.aggregate([
    { $match: { deleted: false, status: 'missed' } },
    { $group: { _id: '$owner', count: { $sum: 1 } } },
  ]);
  for (const m of missed) {
    await upsertSignal({
      caregiver: m._id,
      type: 'missed_visits',
      severity: m.count >= 3 ? 'critical' : 'warning',
      message: `${m.count} care visit${m.count === 1 ? '' : 's'} missed — needs catch-up`,
    });
    created++;
  }

  // 2. Urgent alerts still open after 24h — the referral loop is broken
  const staleAlerts = await Alert.find({
    status: { $nin: ['closed'] },
    createdAt: { $lt: new Date(now - 24 * 60 * 60 * 1000) },
  }).select('caregiver assessment createdAt');
  for (const a of staleAlerts) {
    await upsertSignal({
      caregiver: a.caregiver,
      type: 'open_urgent',
      severity: 'critical',
      message: `Urgent case from ${a.createdAt.toDateString()} is still not closed — follow up now`,
    });
    created++;
  }

  // 3. Growth faltering: latest weight under -2SD
  const latestWeights = await GrowthRecord.aggregate([
    { $match: { deleted: false } },
    { $sort: { measuredAt: -1 } },
    { $group: { _id: '$child', weightKg: { $first: '$weightKg' }, measuredAt: { $first: '$measuredAt' }, owner: { $first: '$owner' } } },
  ]);
  for (const w of latestWeights) {
    const child = await Child.findById(w._id).select('sex dateOfBirth name');
    if (!child) continue;
    const ageMonths = (w.measuredAt - child.dateOfBirth) / (1000 * 60 * 60 * 24 * 30.44);
    if (w.weightKg < minus2sd(ageMonths, child.sex)) {
      await upsertSignal({
        caregiver: w.owner,
        child: w._id,
        type: 'growth_faltering',
        severity: 'critical',
        message: `${child.name}: weight ${w.weightKg}kg is low for age — nutrition assessment needed`,
      });
      created++;
    }
  }

  // 4. Third-trimester pregnancies with missed ANC
  const duePregnancies = await Pregnancy.find({
    deleted: false,
    status: 'active',
    expectedDueDate: { $lt: new Date(now.getTime() + 90 * 24 * 60 * 60 * 1000) },
  }).select('owner expectedDueDate');
  for (const p of duePregnancies) {
    const missedAnc = await Reminder.countDocuments({
      deleted: false,
      pregnancy: p._id,
      type: 'anc',
      status: 'missed',
    });
    if (missedAnc > 0) {
      await upsertSignal({
        caregiver: p.owner,
        pregnancy: p._id,
        type: 'anc_overdue',
        severity: 'critical',
        message: `Third-trimester pregnancy with ${missedAnc} missed ANC visit${missedAnc === 1 ? '' : 's'}`,
      });
      created++;
    }
  }

  // 5. Lost to follow-up: quiet for 30+ days, ranked by risk
  const quietSince = new Date(now - 30 * 24 * 60 * 60 * 1000);
  const quietUsers = await User.find({
    role: 'caregiver',
    $or: [{ lastSyncedAt: { $lt: quietSince } }, { lastSyncedAt: null, createdAt: { $lt: quietSince } }],
  }).select('_id name');
  for (const u of quietUsers) {
    const [recentUrgent, activePregnancy] = await Promise.all([
      Assessment.exists({ owner: u._id, riskLevel: 'urgent', completedAt: { $gt: new Date(now - 60 * 24 * 60 * 60 * 1000) } }),
      Pregnancy.exists({ owner: u._id, deleted: false, status: 'active' }),
    ]);
    const highRisk = Boolean(recentUrgent || activePregnancy);
    await upsertSignal({
      caregiver: u._id,
      type: 'lost_to_followup',
      severity: highRisk ? 'critical' : 'warning',
      message: highRisk
        ? 'No contact for 30+ days with a recent urgent case or active pregnancy — prioritize a home visit'
        : 'No contact for 30+ days — check in with this family',
    });
    created++;
  }

  // Gentle SMS nudge for new critical signals (one per signal, ever)
  const toNudge = await CareSignal.find({
    status: 'open',
    severity: 'critical',
    smsNudgeSentAt: null,
    type: { $in: ['missed_visits', 'anc_overdue', 'growth_faltering'] },
  })
    .populate('caregiver', 'phone name consent')
    .limit(50);
  for (const s of toNudge) {
    const cg = s.caregiver;
    if (!cg || !cg.phone || (cg.consent && cg.consent.smsReminders === false)) continue;
    const r = await sendSms(
      cg.phone,
      'GrowWithMe: please visit your nearest CHPS compound or clinic soon for a check-up. Your health worker is expecting you.'
    );
    if (r.ok) {
      s.smsNudgeSentAt = new Date();
      await s.save();
    }
  }

  logger.info(`[signals] scan complete — ${created} signals upserted`);
  return created;
}

function startCareSignalScan() {
  cron.schedule('30 7 * * *', () => {
    runScan().catch((err) => logger.error('[signals] scan failed:', err));
  });
  logger.info('[signals] daily scan scheduled (07:30)');
}

module.exports = { runScan, startCareSignalScan };
