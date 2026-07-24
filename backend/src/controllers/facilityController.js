const asyncHandler = require('../utils/asyncHandler');
const ApiError = require('../utils/apiError');
const Facility = require('../models/Facility');

// GET /api/v1/facilities/nearby?lng=..&lat=..&maxKm=50
const nearby = asyncHandler(async (req, res) => {
  const lng = parseFloat(req.query.lng);
  const lat = parseFloat(req.query.lat);
  if (Number.isNaN(lng) || Number.isNaN(lat)) {
    throw ApiError.badRequest('lng and lat query params are required');
  }
  const maxKm = Math.min(parseFloat(req.query.maxKm) || 50, 200);
  const facilities = await Facility.find({
    active: true,
    location: {
      $near: {
        $geometry: { type: 'Point', coordinates: [lng, lat] },
        $maxDistance: maxKm * 1000,
      },
    },
  }).limit(20);
  res.json({ success: true, facilities });
});

// GET /api/v1/facilities
const list = asyncHandler(async (req, res) => {
  const facilities = await Facility.find({ active: true }).sort({ name: 1 }).limit(500);
  res.json({ success: true, facilities });
});

// POST /api/v1/facilities (admin)
const create = asyncHandler(async (req, res) => {
  const facility = await Facility.create(req.body);
  res.status(201).json({ success: true, facility });
});

// PATCH /api/v1/facilities/:id (admin)
const update = asyncHandler(async (req, res) => {
  const facility = await Facility.findByIdAndUpdate(req.params.id, req.body, {
    new: true,
    runValidators: true,
  });
  if (!facility) throw ApiError.notFound('Facility not found');
  res.json({ success: true, facility });
});

module.exports = { nearby, list, create, update };
