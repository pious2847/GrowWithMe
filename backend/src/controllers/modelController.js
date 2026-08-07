const asyncHandler = require('../utils/asyncHandler');
const ApiError = require('../utils/apiError');
const MlModel = require('../models/MlModel');

// GET /api/v1/models/:name — the manifest apps poll before downloading.
// 404 (or active:false) simply means "no model available": apps hide the
// feature and keep working — this endpoint must never be load-bearing.
const getModel = asyncHandler(async (req, res) => {
  const model = await MlModel.findOne({ name: req.params.name, active: true }).lean();
  if (!model) throw ApiError.notFound('No active model with that name');
  res.json({ success: true, model });
});

// POST /api/v1/admin/models — upsert a model manifest (from the training
// notebook). Body: { name, version, url, sha256, sizeBytes?, kind?, active?,
// ...anything else lands in meta }.
const upsertModel = asyncHandler(async (req, res) => {
  const { name, version, url, sha256, sizeBytes, kind, active, ...meta } = req.body;
  if (!name || !url || !sha256 || version === undefined) {
    throw ApiError.badRequest('name, version, url and sha256 are required');
  }
  const model = await MlModel.findOneAndUpdate(
    { name },
    {
      name,
      version,
      url,
      sha256,
      sizeBytes,
      kind: kind || 'tflite',
      active: active !== false,
      meta,
    },
    { new: true, upsert: true, setDefaultsOnInsert: true }
  );
  res.status(201).json({ success: true, model });
});

module.exports = { getModel, upsertModel };
