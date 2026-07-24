const mongoose = require('mongoose');
const syncable = require('./plugins/syncable');

// Nana conversation history, synced from the app. Kept so the assistant can
// remember the caregiver's situation and so past guidance can inform care.
const chatMessageSchema = new mongoose.Schema(
  {
    role: { type: String, enum: ['user', 'assistant'], required: true },
    content: { type: String, required: true },
    sentAt: { type: Date, required: true },
  },
  { _id: false }
);

chatMessageSchema.plugin(syncable);
chatMessageSchema.index({ owner: 1, sentAt: -1 });

module.exports = mongoose.model('ChatMessage', chatMessageSchema);
