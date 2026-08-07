const mongoose = require('mongoose');

// Registry of downloadable on-device ML models (see OFFLINE_MODEL_PLAN.md).
// Apps poll GET /models/:name and background-download when the version is
// newer than what they hold; bumping `version` here rolls a new model out to
// every phone with no app release. `active: false` is the kill switch.
const mlModelSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, unique: true, trim: true },
    version: { type: Number, required: true, default: 1 },
    kind: { type: String, enum: ['tflite', 'llm'], default: 'tflite' },
    url: { type: String, required: true },
    sha256: { type: String, required: true },
    sizeBytes: { type: Number },
    active: { type: Boolean, default: true },
    // Everything the app needs to use the model correctly (feature order,
    // normalization stats, valid input ranges, class labels, disclaimer...)
    meta: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  { timestamps: true }
);

module.exports = mongoose.model('MlModel', mlModelSchema);
