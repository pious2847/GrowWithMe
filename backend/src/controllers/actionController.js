const { once } = require('events');
const ActionEvent = require('../models/ActionEvent');
const ApiError = require('../utils/apiError');
const logger = require('../utils/logger');

// Parameters that are safe to keep for model training. Anything else is
// dropped before it touches the database — this collection must never become
// a shadow copy of someone's health record.
const ALLOWED_PARAMS = new Set([
  'actionName',
  'route',
  'tab',
  'subjectType',
  'hasChild',
  'childCount',
  'riskLevel',
  'step',
  'stepCount',
  'inputKind',
  'source',
  'offline',
  'language',
  'screen',
  'success',
]);

function sanitizeParams(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return {};
  const out = {};
  for (const [key, raw] of Object.entries(value)) {
    if (!ALLOWED_PARAMS.has(key)) continue;
    if (raw === null || ['string', 'number', 'boolean'].includes(typeof raw)) {
      out[key] = typeof raw === 'string' ? raw.slice(0, 120) : raw;
    }
  }
  return out;
}

function normalizeEvent(body, req) {
  return {
    user: req.user ? req.user._id : undefined,
    sessionId: String(body.sessionId || '').slice(0, 120) || undefined,
    screen: String(body.screen || '').slice(0, 120),
    action: String(body.action || '').slice(0, 120),
    target: body.target ? String(body.target).slice(0, 160) : undefined,
    params: sanitizeParams(body.params),
    success: body.success !== false,
    durationMs:
      typeof body.durationMs === 'number'
        ? Math.max(0, Math.min(body.durationMs, 600000))
        : undefined,
    appVersion: body.appVersion ? String(body.appVersion).slice(0, 40) : undefined,
    platform: body.platform ? String(body.platform).slice(0, 20) : undefined,
    country: body.country ? String(body.country).slice(0, 8) : undefined,
    region: body.region ? String(body.region).slice(0, 80) : undefined,
    consentVersion: body.consentVersion
      ? String(body.consentVersion).slice(0, 20)
      : undefined,
    clientEventId: body.clientEventId
      ? String(body.clientEventId).slice(0, 80)
      : undefined,
    occurredAt: body.occurredAt ? new Date(body.occurredAt) : new Date(),
  };
}

/**
 * POST /api/v1/actions/events
 * Accepts one event or a batch of up to 100. Idempotent per clientEventId.
 */
async function ingest(req, res, next) {
  try {
    const raw = Array.isArray(req.body?.events)
      ? req.body.events
      : req.body?.action
        ? [req.body]
        : null;
    if (!raw || raw.length === 0) {
      throw ApiError.badRequest('Provide an event or an events[] batch');
    }
    if (raw.length > 100) {
      throw ApiError.badRequest('A batch can contain at most 100 events');
    }

    const docs = raw
      .filter((e) => e && e.action)
      .map((e) => normalizeEvent(e, req));
    if (docs.length === 0) throw ApiError.badRequest('No valid events');

    let inserted = 0;
    try {
      const result = await ActionEvent.insertMany(docs, { ordered: false });
      inserted = result.length;
    } catch (err) {
      // Duplicate clientEventId is expected on retry; everything else is real.
      if (err?.code === 11000 || err?.writeErrors?.every((e) => e.code === 11000)) {
        inserted = err?.result?.insertedCount ?? 0;
      } else {
        throw err;
      }
    }

    res.status(202).json({ accepted: docs.length, inserted });
  } catch (err) {
    next(err);
  }
}

/**
 * GET /api/v1/actions/summary?days=30
 * Aggregate-only view for admins — counts by action and screen, no user rows.
 */
async function summary(req, res, next) {
  try {
    const days = Math.min(Math.max(Number(req.query.days) || 30, 1), 180);
    const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000);

    const [byAction, byScreen, byDay, total] = await Promise.all([
      ActionEvent.aggregate([
        { $match: { occurredAt: { $gte: since } } },
        { $group: { _id: '$action', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $limit: 40 },
      ]),
      ActionEvent.aggregate([
        { $match: { occurredAt: { $gte: since } } },
        { $group: { _id: '$screen', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $limit: 40 },
      ]),
      ActionEvent.aggregate([
        { $match: { occurredAt: { $gte: since } } },
        {
          $group: {
            _id: { $dateToString: { format: '%Y-%m-%d', date: '$occurredAt' } },
            count: { $sum: 1 },
          },
        },
        { $sort: { _id: 1 } },
      ]),
      ActionEvent.countDocuments({ occurredAt: { $gte: since } }),
    ]);

    res.json({ days, total, byAction, byScreen, byDay });
  } catch (err) {
    next(err);
  }
}

/**
 * GET /api/v1/actions/export?days=180&country=GH&action=home.quick.nana&limit=100000
 *
 * Admin-only JSONL export for training the on-device action model. Streams
 * rows in chronological order so long sessions stay in sequence, and never
 * includes the user reference — only the client-generated session id.
 */
async function exportDataset(req, res, next) {
  try {
    const days = Math.min(Math.max(Number(req.query.days) || 180, 1), 730);
    const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
    const limit = Math.min(Math.max(Number(req.query.limit) || 100000, 1), 500000);

    const filter = { occurredAt: { $gte: since } };
    if (req.query.country) filter.country = String(req.query.country).slice(0, 8).toUpperCase();
    if (req.query.action) filter.action = String(req.query.action).slice(0, 120);

    const stamp = new Date().toISOString().slice(0, 10);
    res.setHeader('Content-Type', 'application/x-ndjson; charset=utf-8');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="growwithme-actions-${stamp}.jsonl"`
    );

    const cursor = ActionEvent.find(filter)
      .select(
        'sessionId screen action target params success durationMs appVersion platform country region occurredAt consentVersion'
      )
      .sort({ occurredAt: 1 })
      .limit(limit)
      .lean()
      .cursor();

    let count = 0;
    for await (const doc of cursor) {
      const line = `${JSON.stringify(doc)}\n`;
      if (!res.write(line)) await once(res, 'drain');
      count += 1;
    }
    res.end();
    logger.info(`[actions] dataset export: ${count} rows (${days}d) by admin`);
  } catch (err) {
    // Once streaming has begun we cannot switch to a JSON error response.
    if (res.headersSent) {
      logger.error('[actions] dataset export aborted:', err);
      res.end();
      return;
    }
    next(err);
  }
}

module.exports = { ingest, summary, exportDataset };
