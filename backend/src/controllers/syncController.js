const asyncHandler = require('../utils/asyncHandler');
const ApiError = require('../utils/apiError');
const Child = require('../models/Child');
const Pregnancy = require('../models/Pregnancy');
const Assessment = require('../models/Assessment');
const Reminder = require('../models/Reminder');
const GrowthRecord = require('../models/GrowthRecord');
const ChatMessage = require('../models/ChatMessage');
const DietPlan = require('../models/DietPlan');
const DietLog = require('../models/DietLog');
const DailyTip = require('../models/DailyTip');
const Alert = require('../models/Alert');
const { raiseAlert } = require('../services/alertService');
const logger = require('../utils/logger');

// Collections the device can push. Order matters: parents before dependents.
const SYNCABLE = [
  { key: 'children', model: Child },
  { key: 'pregnancies', model: Pregnancy },
  { key: 'assessments', model: Assessment },
  { key: 'reminders', model: Reminder },
  { key: 'growthRecords', model: GrowthRecord },
  { key: 'chatMessages', model: ChatMessage },
  { key: 'dietPlans', model: DietPlan },
  { key: 'dietLogs', model: DietLog },
  { key: 'dailyTips', model: DailyTip },
];

const PROTECTED_FIELDS = ['owner', 'createdAt', 'updatedAt', '__v', 'alert'];

function sanitize(doc) {
  const clean = { ...doc };
  for (const f of PROTECTED_FIELDS) delete clean[f];
  return clean;
}

/**
 * POST /api/v1/sync
 * Body: { lastPulledAt: epoch-ms (0 on first sync), push: { children: [], pregnancies: [], assessments: [], reminders: [] } }
 *
 * Push: upserts each record scoped to the authenticated user. Conflicts are
 * resolved last-write-wins on the device-set clientUpdatedAt. Urgent
 * assessments arriving without an alert trigger the referral alert flow —
 * this is how offline urgent triage results fire the moment connectivity returns.
 *
 * Pull: returns every record (including soft-delete tombstones) changed on the
 * server since lastPulledAt, minus the ones just pushed, plus the user's
 * alerts. The response's serverTime is the client's next lastPulledAt.
 */
const sync = asyncHandler(async (req, res) => {
  const { lastPulledAt = 0, push = {} } = req.body || {};
  const owner = req.user._id;
  const applied = {};
  const pushedIds = {};

  for (const { key, model } of SYNCABLE) {
    const incoming = Array.isArray(push[key]) ? push[key] : [];
    applied[key] = { accepted: 0, skipped: 0 };
    pushedIds[key] = [];

    for (const raw of incoming) {
      if (!raw || typeof raw._id !== 'string' || typeof raw.clientUpdatedAt !== 'number') {
        applied[key].skipped += 1;
        continue;
      }
      const doc = sanitize(raw);
      pushedIds[key].push(doc._id);

      const existing = await model.findOne({ _id: doc._id });
      if (existing) {
        if (String(existing.owner) !== String(owner)) {
          // Record belongs to another user — refuse silently, never leak
          applied[key].skipped += 1;
          continue;
        }
        if (existing.clientUpdatedAt >= doc.clientUpdatedAt) {
          applied[key].skipped += 1; // server copy is same or newer: LWW keeps it
          continue;
        }
        existing.set(doc);
        await existing.save();
        applied[key].accepted += 1;
      } else {
        const created = await model.create({ ...doc, owner });
        applied[key].accepted += 1;

        if (key === 'assessments' && created.riskLevel === 'urgent' && !created.alert) {
          logger.warn(
            `[sync] URGENT assessment ${created._id} from user=${req.user.phone} — raising alert`
          );
          try {
            const alert = await raiseAlert(created, req.user);
            created.alert = alert._id;
            await created.save();
            logger.info(
              `[alert] ${alert._id} status=${alert.status} volunteer=${alert.volunteer || 'none'} facility=${alert.facility || 'none'}`
            );
          } catch (err) {
            logger.error('[sync] alert flow failed:', err);
          }
        }
      }
    }
  }

  const since = new Date(Number(lastPulledAt) || 0);
  const pull = {};
  for (const { key, model } of SYNCABLE) {
    pull[key] = await model
      .find({ owner, updatedAt: { $gt: since }, _id: { $nin: pushedIds[key] } })
      .lean();
  }
  pull.alerts = await Alert.find({ caregiver: owner, updatedAt: { $gt: since } })
    .populate('volunteer', 'name phone')
    .populate('facility', 'name phone type location')
    .lean();

  req.user.lastSyncedAt = new Date();
  await req.user.save();

  const pushSummary = SYNCABLE.map(({ key }) => `${key}:${applied[key].accepted}`).join(' ');
  const pullSummary = Object.entries(pull)
    .map(([k, v]) => `${k}:${v.length}`)
    .join(' ');
  logger.info(`[sync] user=${req.user.phone} pushed {${pushSummary}} pulled {${pullSummary}}`);

  res.json({ success: true, serverTime: Date.now(), applied, pull });
});

module.exports = { sync, SYNCABLE };
