const mongoose = require('mongoose');
const syncable = require('./plugins/syncable');

// Weight measurements from growth-monitoring visits, synced from the app.
// Powers the facility view of children whose growth is faltering.
const growthRecordSchema = new mongoose.Schema(
  {
    child: { type: String, ref: 'Child', required: true },
    weightKg: { type: Number, required: true },
    measuredAt: { type: Date, required: true },
  },
  { _id: false }
);

growthRecordSchema.plugin(syncable);
growthRecordSchema.index({ child: 1, measuredAt: 1 });

module.exports = mongoose.model('GrowthRecord', growthRecordSchema);
