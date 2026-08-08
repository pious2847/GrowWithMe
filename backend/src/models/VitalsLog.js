const mongoose = require('mongoose');

// Shadow-mode data flywheel (OFFLINE_MODEL_PLAN.md Phase 4): every on-device
// vitals assessment is logged — de-identified numbers, the model's prediction,
// and (for caregivers) the rules engine's verdict alongside it. When enough
// local rows exist, the maternal-risk model is fine-tuned from Bangladesh
// clinical data toward the Northern-Ghana population actually being served.
const vitalsLogSchema = new mongoose.Schema(
  {
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    source: { type: String, enum: ['responder', 'caregiver'], required: true },
    modelName: { type: String, default: 'maternal-risk' },
    modelVersion: { type: Number },
    // The six vitals as entered; null/absent = not measured.
    values: { type: mongoose.Schema.Types.Mixed, default: {} },
    usedInputs: { type: Number },
    prediction: {
      label: { type: String },
      probs: { type: [Number], default: undefined },
    },
    // Caregiver context: what the deterministic rules said for the same case.
    rulesRiskLevel: { type: String },
    // Responder context: the alert this assessment belongs to, if any.
    alert: { type: mongoose.Schema.Types.ObjectId, ref: 'Alert' },
    // Filled in later (manually or by follow-up): what actually happened —
    // this is the label future fine-tuning trains on.
    outcome: { type: String, trim: true },
  },
  { timestamps: true }
);

vitalsLogSchema.index({ createdAt: -1 });

module.exports = mongoose.model('VitalsLog', vitalsLogSchema);
