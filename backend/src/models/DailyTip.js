const mongoose = require('mongoose');
const syncable = require('./plugins/syncable');

// A day's feeding/nutrition tip (AI-personalized or from the offline
// library). Kept forever so caregivers can browse past guidance.
const dailyTipSchema = new mongoose.Schema(
  {
    audience: {
      type: String,
      enum: ['pregnancy', 'lactating', 'child', 'general'],
      required: true,
    },
    title: { type: String, required: true },
    body: { type: String, required: true },
    forDay: { type: String, required: true }, // YYYY-MM-DD
    source: { type: String, enum: ['ai', 'offline'], default: 'offline' },
  },
  { _id: false }
);

dailyTipSchema.plugin(syncable);
dailyTipSchema.index({ owner: 1, forDay: -1 });

module.exports = mongoose.model('DailyTip', dailyTipSchema);
