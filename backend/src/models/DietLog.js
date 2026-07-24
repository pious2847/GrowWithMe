const mongoose = require('mongoose');
const syncable = require('./plugins/syncable');

// Daily Plate tracker: which food groups she ate that day. The diversity
// score (target 5+/8 groups) is a proven proxy for diet quality and can feed
// the Care Signals monitor when persistently low.
const dietLogSchema = new mongoose.Schema(
  {
    day: { type: String, required: true }, // YYYY-MM-DD
    groupsJson: { type: String, required: true }, // JSON array of group indexes
    score: { type: Number, required: true },
    // Which of Nana's recommended meals she actually prepared that day
    eatenMealsJson: { type: String },
  },
  { _id: false }
);

dietLogSchema.plugin(syncable);
dietLogSchema.index({ owner: 1, day: 1 });

module.exports = mongoose.model('DietLog', dietLogSchema);
