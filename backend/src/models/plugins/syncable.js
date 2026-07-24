const mongoose = require('mongoose');

// Shared shape for local-first collections. The Flutter app owns these records:
// - _id is a client-generated UUID string so records can be created offline
// - clientUpdatedAt (epoch ms, set by the device) drives last-write-wins conflict resolution
// - deleted is a soft-delete tombstone so deletions propagate to other devices
// - server `updatedAt` (mongoose timestamps) drives incremental pulls
function syncable(schema) {
  schema.add({
    _id: { type: String, required: true },
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    clientUpdatedAt: { type: Number, required: true },
    deleted: { type: Boolean, default: false },
  });
  schema.set('timestamps', true);
  schema.index({ owner: 1, updatedAt: 1 });
}

module.exports = syncable;
