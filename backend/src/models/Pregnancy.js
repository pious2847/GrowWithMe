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
  },
  { _id: false }
);

pregnancySchema.plugin(syncable);

module.exports = mongoose.model('Pregnancy', pregnancySchema);
