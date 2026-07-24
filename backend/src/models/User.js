const mongoose = require('mongoose');

const pointSchema = new mongoose.Schema(
  {
    type: { type: String, enum: ['Point'], default: 'Point' },
    coordinates: { type: [Number], default: undefined }, // [lng, lat]
  },
  { _id: false }
);

const userSchema = new mongoose.Schema(
  {
    phone: { type: String, required: true, unique: true, trim: true },
    name: { type: String, trim: true },
    role: {
      type: String,
      enum: ['caregiver', 'volunteer', 'facility', 'admin'],
      default: 'caregiver',
    },
    language: { type: String, enum: ['en', 'dagbani', 'twi', 'hausa', 'other'], default: 'en' },
    region: { type: String, trim: true },
    district: { type: String, trim: true },
    community: { type: String, trim: true },
    location: { type: pointSchema, default: undefined },
    photoUrl: { type: String },
    // Volunteers: availability for urgent alert routing
    available: { type: Boolean, default: true },
    // Facility staff and volunteers are attached to a facility
    facility: { type: mongoose.Schema.Types.ObjectId, ref: 'Facility' },
    consent: {
      dataProcessing: { type: Boolean, default: false },
      locationOnUrgent: { type: Boolean, default: false },
      smsReminders: { type: Boolean, default: true },
      consentedAt: { type: Date },
    },
    lastSyncedAt: { type: Date },
  },
  { timestamps: true }
);

userSchema.index({ location: '2dsphere' });
userSchema.index({ role: 1, available: 1 });

module.exports = mongoose.model('User', userSchema);
