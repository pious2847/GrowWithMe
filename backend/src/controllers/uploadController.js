const asyncHandler = require('../utils/asyncHandler');
const ApiError = require('../utils/apiError');
const { uploadBuffer, configured } = require('../services/cloudinaryService');

// POST /api/v1/uploads  (multipart/form-data, field "file")
// Handles photos and voice notes; returns the hosted URL for the app to store.
const upload = asyncHandler(async (req, res) => {
  if (!configured()) {
    throw new ApiError(503, 'File uploads are not configured on this server (Cloudinary keys missing)');
  }
  if (!req.file) throw ApiError.badRequest('No file provided (use multipart field "file")');

  const kind = req.body.kind || 'general'; // e.g. child_photo | voice_note | profile
  const result = await uploadBuffer(req.file.buffer, {
    folder: `growwithme/${kind}`,
    resourceType: 'auto',
  });

  res.status(201).json({
    success: true,
    file: {
      url: result.secure_url,
      publicId: result.public_id,
      resourceType: result.resource_type,
      bytes: result.bytes,
      format: result.format,
    },
  });
});

module.exports = { upload };
