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
    // ISO-3166 alpha-2. Defaults to Ghana so existing demo/seed data keeps
    // working while new countries import side by side.
    country: {
      type: String,
      trim: true,
      uppercase: true,
      maxlength: 8,
      default: 'GH',
      index: true,
    },
    // National registry key (e.g. DHIS2 org unit). When present it makes
    // re-imports idempotent instead of duplicating every facility.
    externalId: { type: String, trim: true, maxlength: 80 },
    region: { type: String, trim: true },
    district: { type: String, trim: true },
    community: { type: String, trim: true },
    location: {
      type: { type: String, enum: ['Point'], default: 'Point' },
      coordinates: { type: [Number], required: true }, // [lng, lat]
    },
    active: { type: Boolean, default: true },
    // Emergency contacts (matron on duty, ambulance line...) — every one of
    // them is SMSed when an urgent alert routes to this facility.
    emergencyContacts: [
      {
        _id: false,
        name: { type: String, trim: true },
        phone: { type: String, trim: true },
        role: { type: String, trim: true },
      },
    ],
  },
  { timestamps: true }
);

facilitySchema.index({ location: '2dsphere' });
facilitySchema.index({ country: 1, region: 1, name: 1 });
facilitySchema.index(
  { country: 1, externalId: 1 },
  { unique: true, partialFilterExpression: { externalId: { $type: 'string' } } }
);

module.exports = mongoose.model('Facility', facilitySchema);
