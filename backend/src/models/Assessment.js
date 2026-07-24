const mongoose = require('mongoose');
const syncable = require('./plugins/syncable');

// A triage session completed on-device (works fully offline) and synced up.
// Risk classification happens in the app's deterministic rules layer; the
// backend trusts riskLevel but re-triggers the alert flow for urgent cases
// that arrive without an alert (e.g. completed offline).
const assessmentSchema = new mongoose.Schema(
  {
    subjectType: { type: String, enum: ['child', 'pregnancy', 'mother'], required: true },
    child: { type: String, ref: 'Child' },
    pregnancy: { type: String, ref: 'Pregnancy' },
    answers: [
      {
        _id: false,
        questionId: String,
        question: String,
        answer: mongoose.Schema.Types.Mixed,
      },
    ],
    dangerSigns: [{ type: String }],
    riskLevel: { type: String, enum: ['low', 'moderate', 'urgent'], required: true },
    guidance: { type: String },
    // Location is only captured for urgent assessments, with onboarding consent
    location: {
      type: { type: String, enum: ['Point'] },
      coordinates: { type: [Number] }, // [lng, lat]
    },
    startedAt: { type: Date },
    completedAt: { type: Date, required: true },
    alert: { type: mongoose.Schema.Types.ObjectId, ref: 'Alert' },
  },
  { _id: false }
);

assessmentSchema.plugin(syncable);
assessmentSchema.index({ riskLevel: 1, completedAt: -1 });

module.exports = mongoose.model('Assessment', assessmentSchema);
