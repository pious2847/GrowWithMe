const asyncHandler = require('../utils/asyncHandler');
const ApiError = require('../utils/apiError');
const Facility = require('../models/Facility');

const MAX_PAGE = 200;
const FACILITY_TYPES = new Set(['chps', 'clinic', 'health_centre', 'hospital']);

function escapeRegex(value) {
  return String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// GET /api/v1/facilities/nearby?lng=..&lat=..&maxKm=50&country=GH
const nearby = asyncHandler(async (req, res) => {
  const lng = parseFloat(req.query.lng);
  const lat = parseFloat(req.query.lat);
  if (Number.isNaN(lng) || Number.isNaN(lat)) {
    throw ApiError.badRequest('lng and lat query params are required');
  }
  const maxKm = Math.min(parseFloat(req.query.maxKm) || 50, 200);
  const filter = {
    active: true,
    location: {
      $near: {
        $geometry: { type: 'Point', coordinates: [lng, lat] },
        $maxDistance: maxKm * 1000,
      },
    },
  };
  if (req.query.country) filter.country = String(req.query.country).toUpperCase().slice(0, 8);

  const facilities = await Facility.find(filter).limit(20);
  res.json({ success: true, facilities });
});

// GET /api/v1/facilities?country=GH&region=Northern&q=tamale&page=1&limit=50
// Paged so a national registry (tens of thousands of CHPS compounds) never
// arrives as one unbounded response.
const list = asyncHandler(async (req, res) => {
  const filter = { active: req.query.includeInactive === 'true' ? { $ne: false } : true };
  if (req.query.country) filter.country = String(req.query.country).toUpperCase().slice(0, 8);
  if (req.query.region) filter.region = String(req.query.region).slice(0, 80);
  if (req.query.district) filter.district = String(req.query.district).slice(0, 80);
  if (req.query.q) {
    filter.name = new RegExp(escapeRegex(String(req.query.q).slice(0, 60)), 'i');
  }

  const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 50, 1), MAX_PAGE);
  const page = Math.max(parseInt(req.query.page, 10) || 1, 1);

  const [facilities, total] = await Promise.all([
    Facility.find(filter)
      .sort({ name: 1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .lean(),
    Facility.countDocuments(filter),
  ]);

  res.json({
    success: true,
    page,
    limit,
    total,
    hasMore: page * limit < total,
    facilities,
  });
});

// POST /api/v1/facilities (admin)
const create = asyncHandler(async (req, res) => {
  const facility = await Facility.create(req.body);
  res.status(201).json({ success: true, facility });
});

/**
 * POST /api/v1/facilities/bulk (admin)
 * Body: { facilities: [ ...same shape as create... ] } (max 5000)
 *
 * Idempotent when rows carry `externalId` (DHIS2 org unit, national code) —
 * re-importing a registry updates rows instead of duplicating them. Without
 * one, name + district + country is used as the natural key.
 */
const bulkImport = asyncHandler(async (req, res) => {
  const rows = Array.isArray(req.body?.facilities) ? req.body.facilities : req.body;
  if (!Array.isArray(rows) || rows.length === 0) {
    throw ApiError.badRequest('Provide a facilities[] array');
  }
  if (rows.length > 5000) {
    throw ApiError.badRequest('A bulk import can contain at most 5000 facilities');
  }

  const valid = [];
  const rejected = [];
  rows.forEach((row, index) => {
    const coords = row?.location?.coordinates;
    const okCoords =
      Array.isArray(coords) &&
      coords.length === 2 &&
      Number.isFinite(Number(coords[0])) &&
      Number.isFinite(Number(coords[1])) &&
      Math.abs(Number(coords[0])) <= 180 &&
      Math.abs(Number(coords[1])) <= 90;
    if (!row || !row.name || !FACILITY_TYPES.has(row.type) || !okCoords) {
      rejected.push({
        index,
        reason:
          'name, a valid type (chps, clinic, health_centre, hospital) and location.coordinates [lng, lat] are required',
      });
      return;
    }
    valid.push({
      ...row,
      name: String(row.name).slice(0, 160),
      country: String(row.country || 'GH').toUpperCase().slice(0, 8),
      location: {
        type: 'Point',
        coordinates: [Number(coords[0]), Number(coords[1])],
      },
    });
  });

  if (valid.length === 0) {
    throw ApiError.badRequest('No valid facilities in the batch', rejected);
  }

  const operations = valid.map((doc) => {
    const filter = doc.externalId
      ? { country: doc.country, externalId: doc.externalId }
      : { country: doc.country, name: doc.name, district: doc.district || null };
    return { updateOne: { filter, update: { $set: doc }, upsert: true } };
  });

  const result = await Facility.bulkWrite(operations, { ordered: false });
  res.status(201).json({
    success: true,
    received: rows.length,
    accepted: valid.length,
    rejected: rejected.length,
    inserted: result.upsertedCount,
    updated: result.modifiedCount,
    matched: result.matchedCount,
    errors: rejected.slice(0, 50),
  });
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

module.exports = { nearby, list, create, bulkImport, update };
