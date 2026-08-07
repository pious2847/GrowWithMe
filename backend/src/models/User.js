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
    // Responders (role=volunteer): professional tier + verification.
    // Tier + verified status drive alert routing priority — a verified
    // nurse nearby outranks an unverified volunteer next door.
    credentials: {
      tier: {
        type: String,
        enum: ['volunteer', 'chw', 'nurse', 'midwife', 'doctor'],
        default: 'volunteer',
      },
      licenseNumber: { type: String, trim: true },
      documents: [
        {
          _id: false,
          kind: { type: String, enum: ['ghana_card', 'license', 'other'] },
          url: { type: String },
          uploadedAt: { type: Date, default: Date.now },
        },
      ],
      status: {
        type: String,
        enum: ['unverified', 'pending', 'verified', 'rejected'],
        default: 'unverified',
      },
      verifiedAt: { type: Date },
      note: { type: String, trim: true },
    },
    // Freshness of the responder's live location (heartbeat from the app)
    lastSeenAt: { type: Date },
    consent: {
      dataProcessing: { type: Boolean, default: false },
      locationOnUrgent: { type: Boolean, default: false },
      smsReminders: { type: Boolean, default: true },
      // Responders: signed the patient-confidentiality agreement (HIPAA-style
      // duties: use patient data only for care, never share it). Registration
      // cannot proceed without it.
      patientConfidentiality: { type: Boolean, default: false },
      consentedAt: { type: Date },
    },
    // Care Circle: trusted family members (father, grandmother...) who receive
    // SMS copies of reminders and urgent alerts. Max 2.
    careCircle: [
      {
        _id: false,
        name: { type: String, trim: true },
        phone: { type: String, trim: true },
        relation: { type: String, trim: true },
      },
    ],
    lastSyncedAt: { type: Date },
  },
  { timestamps: true }
);

userSchema.index({ location: '2dsphere' });
userSchema.index({ role: 1, available: 1 });

module.exports = mongoose.model('User', userSchema);
