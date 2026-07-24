const mongoose = require('mongoose');
const syncable = require('./plugins/syncable');

// Care calendar entries. Generated on-device from DOB / pregnancy status (so
// they exist offline), synced up so the server can send SMS fallback for due
// visits and facilities can see missed ones.
const reminderSchema = new mongoose.Schema(
  {
    child: { type: String, ref: 'Child' },
    pregnancy: { type: String, ref: 'Pregnancy' },
    type: {
      type: String,
      enum: [
        'immunization',
        'growth_monitoring',
        'vitamin_a',
        'deworming',
        'anc',
        'pnc',
        'follow_up',
        'nutrition',
        'custom',
        'other',
      ],
      required: true,
    },
    title: { type: String, required: true },
    description: { type: String },
    dueDate: { type: Date, required: true },
    status: {
      type: String,
      enum: ['upcoming', 'done', 'missed', 'snoozed'],
      default: 'upcoming',
    },
    snoozedUntil: { type: Date },
    completedAt: { type: Date },
    smsSentAt: { type: Date },
  },
  { _id: false }
);

reminderSchema.plugin(syncable);
reminderSchema.index({ status: 1, dueDate: 1 });

module.exports = mongoose.model('Reminder', reminderSchema);
