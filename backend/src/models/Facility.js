const mongoose = require('mongoose');

const facilitySchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    type: {
      type: String,
      enum: ['chps', 'clinic', 'health_centre', 'hospital'],
      required: true,
    },
    phone: { type: String, trim: true },
    region: { type: String, trim: true },
    district: { type: String, trim: true },
    community: { type: String, trim: true },
    location: {
      type: { type: String, enum: ['Point'], default: 'Point' },
      coordinates: { type: [Number], required: true }, // [lng, lat]
    },
    active: { type: Boolean, default: true },
  },
  { timestamps: true }
);

facilitySchema.index({ location: '2dsphere' });

module.exports = mongoose.model('Facility', facilitySchema);
