const mongoose = require('mongoose');

// Interaction metadata is kept long enough to train a model across seasons,
// then expires automatically. 400 days by default; override for a shorter
// retention promise in a specific market with ACTION_EVENT_RETENTION_DAYS.
const RETENTION_DAYS = Math.min(
  Math.max(parseInt(process.env.ACTION_EVENT_RETENTION_DAYS || '400', 10), 30),
  3650
);

/**
 * A single consented interaction event used to train the on-device action
 * model. Deliberately narrow: screen/target identifiers and action names,
 * never free-text health content. Chat text and patient values live in their
 * own consented collections.
 */
const actionEventSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true },
    sessionId: { type: String, trim: true, index: true },
    // Stable identifiers from the app action registry, e.g. "home.quick.nana".
    screen: { type: String, trim: true, maxlength: 120 },
    action: { type: String, trim: true, maxlength: 120, index: true },
    target: { type: String, trim: true, maxlength: 160 },
    // Only allow-listed, non-PHI parameters survive sanitisation.
    params: { type: mongoose.Schema.Types.Mixed },
    success: { type: Boolean, default: true },
    durationMs: { type: Number, min: 0, max: 600000 },
    appVersion: { type: String, trim: true, maxlength: 40 },
    platform: { type: String, trim: true, maxlength: 20 },
    country: { type: String, trim: true, maxlength: 8 },
    region: { type: String, trim: true, maxlength: 80 },
    consentVersion: { type: String, trim: true, maxlength: 20 },
    clientEventId: { type: String, trim: true, maxlength: 80 },
    occurredAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

actionEventSchema.index({ occurredAt: -1, action: 1 });
actionEventSchema.index(
  { occurredAt: 1 },
  { expireAfterSeconds: RETENTION_DAYS * 24 * 60 * 60, name: 'occurredAt_ttl' }
);
actionEventSchema.index(
  { user: 1, clientEventId: 1 },
  { unique: true, partialFilterExpression: { clientEventId: { $type: 'string' } } }
);

module.exports = mongoose.model('ActionEvent', actionEventSchema);
