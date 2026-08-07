const asyncHandler = require('../utils/asyncHandler');
const ApiError = require('../utils/apiError');
const Alert = require('../models/Alert');
const User = require('../models/User');
const { uploadBuffer, configured } = require('../services/cloudinaryService');
const logger = require('../utils/logger');

const TIERS = ['volunteer', 'chw', 'nurse', 'midwife', 'doctor'];
// Tiers claiming a medical profession MUST provide a license number and a
// license document before their account can enter admin review.
const LICENSED_TIERS = ['nurse', 'midwife', 'doctor'];
const NEARBY_M = 25000;

// Recomputes verification progress after any profile/document change: an
// account reaches 'pending' (admin review queue) only when every requirement
// for its claimed tier is on file.
function refreshVerificationStatus(user) {
  const docs = user.credentials.documents || [];
  const hasGhanaCard = docs.some((d) => d.kind === 'ghana_card');
  const needsLicense = LICENSED_TIERS.includes(user.credentials.tier);
  const hasLicense = docs.some((d) => d.kind === 'license');
  const complete =
    hasGhanaCard &&
    (!needsLicense || (hasLicense && user.credentials.licenseNumber));
  if (complete && user.credentials.status === 'unverified') {
    user.credentials.status = 'pending';
  }
}

// POST /api/v1/responder/profile — become (or update) a responder.
// Role switches to 'volunteer'; the professional tier lives in credentials
// and only counts for routing once an admin verifies the documents.
// Accepts consent flags from the onboarding privacy screen — registration
// is refused until the confidentiality agreement is signed.
const saveProfile = asyncHandler(async (req, res) => {
  const { name, tier, licenseNumber, region, district, community, consent } = req.body;
  if (tier && !TIERS.includes(tier)) {
    throw ApiError.badRequest(`tier must be one of: ${TIERS.join(', ')}`);
  }
  const user = req.user;

  if (consent && typeof consent === 'object') {
    if (consent.patientConfidentiality === true) {
      user.consent.patientConfidentiality = true;
      user.consent.consentedAt = new Date();
    }
    if (consent.dataProcessing === true) user.consent.dataProcessing = true;
  }

  // A profile (name/tier) cannot be saved before the privacy agreement.
  const savingProfile = name !== undefined || tier !== undefined;
  if (savingProfile && !user.consent.patientConfidentiality) {
    throw ApiError.badRequest(
      'You must accept the patient confidentiality agreement before registering as a responder'
    );
  }

  if (tier && LICENSED_TIERS.includes(tier)) {
    const license = licenseNumber !== undefined ? licenseNumber : user.credentials.licenseNumber;
    if (!license || !String(license).trim()) {
      throw ApiError.badRequest(
        `A professional license number is required to register as a ${tier}`
      );
    }
  }

  if (user.role === 'caregiver') user.role = 'volunteer';
  if (name) user.name = name;
  if (region !== undefined) user.region = region;
  if (district !== undefined) user.district = district;
  if (community !== undefined) user.community = community;
  if (tier) user.credentials.tier = tier;
  if (licenseNumber !== undefined) user.credentials.licenseNumber = licenseNumber;
  refreshVerificationStatus(user);
  await user.save();
  res.json({ success: true, user });
});

// POST /api/v1/responder/documents — multipart field "file", body "kind"
// (ghana_card | license | other). Once a Ghana Card is on file the account
// moves to 'pending' for admin review.
const uploadDocument = asyncHandler(async (req, res) => {
  if (!configured()) throw new ApiError(503, 'File uploads are not configured');
  if (!req.file) throw ApiError.badRequest('No file provided (use multipart field "file")');
  const kind = ['ghana_card', 'license', 'other'].includes(req.body.kind)
    ? req.body.kind
    : 'other';

  const result = await uploadBuffer(req.file.buffer, {
    folder: `growwithme/credentials/${req.user._id}`,
    resourceType: 'image',
  });

  const user = req.user;
  // Re-uploading the Ghana Card or license replaces the old one (e.g. after
  // rejection); 'other' documents accumulate.
  if (kind !== 'other') {
    user.credentials.documents = user.credentials.documents.filter((d) => d.kind !== kind);
  }
  user.credentials.documents.push({ kind, url: result.secure_url });
  // A rejected account that submits fresh documents goes back into review.
  if (user.credentials.status === 'rejected') user.credentials.status = 'unverified';
  refreshVerificationStatus(user);
  await user.save();
  res.status(201).json({ success: true, user });
});

// POST /api/v1/responder/location — the app's heartbeat {lng, lat}.
// Keeps routing decisions based on where responders ARE, not where they
// registered.
const updateLocation = asyncHandler(async (req, res) => {
  const { lng, lat } = req.body;
  if (typeof lng !== 'number' || typeof lat !== 'number') {
    throw ApiError.badRequest('lng and lat (numbers) are required');
  }
  req.user.location = { type: 'Point', coordinates: [lng, lat] };
  req.user.lastSeenAt = new Date();
  await req.user.save();
  res.json({ success: true });
});

// POST /api/v1/responder/availability — on/off duty.
const setAvailability = asyncHandler(async (req, res) => {
  req.user.available = Boolean(req.body.available);
  await req.user.save();
  res.json({ success: true, available: req.user.available });
});

// GET /api/v1/responder/alerts — my active cases first, then unassigned
// alerts near my last known location (so any nearby responder can step in
// when no one was auto-assigned).
const nearbyAlerts = asyncHandler(async (req, res) => {
  const mine = await Alert.find({
    volunteer: req.user._id,
    status: { $ne: 'closed' },
  })
    .sort({ createdAt: -1 })
    .limit(25)
    .populate('caregiver', 'name phone community')
    .populate('facility', 'name phone type location')
    .lean();

  let unassigned = [];
  const coords = req.user.location && req.user.location.coordinates;
  if (coords && coords.length === 2) {
    try {
      unassigned = await Alert.find({
        volunteer: { $exists: false },
        status: { $in: ['pending', 'notified', 'unassigned'] },
        location: {
          $near: {
            $geometry: { type: 'Point', coordinates: coords },
            $maxDistance: NEARBY_M,
          },
        },
      })
        .limit(25)
        .populate('caregiver', 'name phone community')
        .populate('facility', 'name phone type location')
        .lean();
    } catch (err) {
      // Geo index missing/mid-build must not take the whole list down —
      // fall back to recent unassigned alerts without the distance filter.
      logger.error(`[responder] $near query failed, falling back to non-geo list: ${err.message}`);
      unassigned = await Alert.find({
        volunteer: { $exists: false },
        status: { $in: ['pending', 'notified', 'unassigned'] },
      })
        .sort({ createdAt: -1 })
        .limit(25)
        .populate('caregiver', 'name phone community')
        .populate('facility', 'name phone type location')
        .lean();
    }
  }
  res.json({ success: true, mine, unassigned });
});

// ---- Admin: verification queue ----

// GET /api/v1/admin/responders/pending
const pendingResponders = asyncHandler(async (req, res) => {
  const users = await User.find({
    role: 'volunteer',
    'credentials.status': 'pending',
  })
    .select('name phone region district community credentials createdAt')
    .sort({ updatedAt: -1 })
    .limit(100);
  res.json({ success: true, users });
});

// POST /api/v1/admin/responders/:id/verify { status: verified|rejected, tier?, note? }
const verifyResponder = asyncHandler(async (req, res) => {
  const { status, tier, note } = req.body;
  if (!['verified', 'rejected'].includes(status)) {
    throw ApiError.badRequest('status must be verified or rejected');
  }
  if (tier && !TIERS.includes(tier)) {
    throw ApiError.badRequest(`tier must be one of: ${TIERS.join(', ')}`);
  }
  const user = await User.findById(req.params.id);
  if (!user) throw ApiError.notFound('User not found');
  user.credentials.status = status;
  if (tier) user.credentials.tier = tier;
  if (note !== undefined) user.credentials.note = note;
  if (status === 'verified') user.credentials.verifiedAt = new Date();
  await user.save();
  res.json({ success: true, user });
});

module.exports = {
  saveProfile,
  uploadDocument,
  updateLocation,
  setAvailability,
  nearbyAlerts,
  pendingResponders,
  verifyResponder,
};
