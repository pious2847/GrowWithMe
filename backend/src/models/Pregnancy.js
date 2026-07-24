const mongoose = require('mongoose');
const syncable = require('./plugins/syncable');

const pregnancySchema = new mongoose.Schema(
  {
    lastMenstrualPeriod: { type: Date },
    expectedDueDate: { type: Date, required: true },
    status: { type: String, enum: ['active', 'delivered', 'ended'], default: 'active' },
    deliveredAt: { type: Date },
    gravida: { type: Number },
    parity: { type: Number },
    notes: { type: String },
    // The hospital/clinic where she does her checks and scans — receives the
    // PDF risk report when the AI check-in flags a problem.
    hospitalName: { type: String, trim: true },
    hospitalPhone: { type: String, trim: true },
    lastCheckinAt: { type: Date },
    lastRiskLevel: { type: String, enum: ['low', 'moderate', 'urgent'] },
  },
  { _id: false }
);

pregnancySchema.plugin(syncable);

module.exports = mongoose.model('Pregnancy', pregnancySchema);
