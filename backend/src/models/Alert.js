const mongoose = require('mongoose');

// Server-side referral alert raised for an urgent assessment. Routed to the
// nearest available volunteer and nearest facility; the timeline tracks the
// referral loop until it is closed.
const alertSchema = new mongoose.Schema(
  {
    assessment: { type: String, ref: 'Assessment', required: true },
    caregiver: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    riskLevel: { type: String, enum: ['urgent'], default: 'urgent' },
    summary: { type: String, required: true },
    location: {
      type: { type: String, enum: ['Point'] },
      coordinates: { type: [Number] },
    },
    volunteer: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    facility: { type: mongoose.Schema.Types.ObjectId, ref: 'Facility' },
    reportUrl: { type: String },
    status: {
      type: String,
      enum: ['pending', 'notified', 'acknowledged', 'en_route', 'at_facility', 'closed', 'unassigned'],
      default: 'pending',
      index: true,
    },
    timeline: [
      {
        _id: false,
        at: { type: Date, default: Date.now },
        event: String,
        by: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        note: String,
      },
    ],
    smsResults: [
      {
        _id: false,
        to: String,
        kind: { type: String }, // volunteer | facility | caregiver
        ok: Boolean,
        error: String,
        at: { type: Date, default: Date.now },
      },
    ],
  },
  { timestamps: true }
);

alertSchema.index({ facility: 1, status: 1 });
alertSchema.index({ volunteer: 1, status: 1 });

module.exports = mongoose.model('Alert', alertSchema);
