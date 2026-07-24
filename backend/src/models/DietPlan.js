const mongoose = require('mongoose');
const syncable = require('./plugins/syncable');

// A saved one-day meal plan (AI-personalized or from the offline library),
// kept so her care team can see what guidance she received.
const dietPlanSchema = new mongoose.Schema(
  {
    audience: {
      type: String,
      enum: ['pregnancy', 'lactating', 'child', 'general'],
      required: true,
    },
    season: { type: String },
    budget: { type: String, enum: ['low', 'ok'] },
    pantry: { type: String },
    // Her full spoken/typed words when she talked to Nana instead of the wizard
    spokenText: { type: String },
    planJson: { type: String, required: true },
    source: { type: String, enum: ['ai', 'offline'], default: 'offline' },
    plannedFor: { type: Date, required: true },
  },
  { _id: false }
);

dietPlanSchema.plugin(syncable);

module.exports = mongoose.model('DietPlan', dietPlanSchema);
