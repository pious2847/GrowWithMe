const mongoose = require('mongoose');

// A risk signal produced by the daily monitoring scan — the "catch it before
// it becomes a problem" layer. Facilities work these like a triage queue.
const careSignalSchema = new mongoose.Schema(
  {
    caregiver: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    child: { type: String, ref: 'Child' },
    pregnancy: { type: String, ref: 'Pregnancy' },
    type: {
      type: String,
      enum: [
        'missed_visits',
        'open_urgent',
        'growth_faltering',
        'anc_overdue',
        'lost_to_followup',
      ],
      required: true,
    },
    severity: { type: String, enum: ['info', 'warning', 'critical'], required: true },
    message: { type: String, required: true },
    status: {
      type: String,
      enum: ['open', 'acknowledged', 'resolved'],
      default: 'open',
      index: true,
    },
    lastDetectedAt: { type: Date, default: Date.now },
    smsNudgeSentAt: { type: Date },
  },
  { timestamps: true }
);

// One live signal per (caregiver, type, subject) — the scan upserts.
careSignalSchema.index(
  { caregiver: 1, type: 1, child: 1, pregnancy: 1 },
  { unique: true }
);

module.exports = mongoose.model('CareSignal', careSignalSchema);
