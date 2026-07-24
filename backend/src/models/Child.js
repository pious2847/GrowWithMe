const mongoose = require('mongoose');
const syncable = require('./plugins/syncable');

const childSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    sex: { type: String, enum: ['male', 'female'] },
    dateOfBirth: { type: Date, required: true },
    photoUrl: { type: String },
    birthWeightKg: { type: Number },
    notes: { type: String },
  },
  { _id: false }
);

childSchema.plugin(syncable);

module.exports = mongoose.model('Child', childSchema);
