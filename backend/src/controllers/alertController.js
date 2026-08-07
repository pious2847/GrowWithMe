const asyncHandler = require('../utils/asyncHandler');
const ApiError = require('../utils/apiError');
const Alert = require('../models/Alert');

const STATUS_FLOW = ['acknowledged', 'en_route', 'at_facility', 'closed'];

function canAccess(alert, user) {
  const id = String(user._id);
  const caregiverId = String(alert.caregiver && alert.caregiver._id ? alert.caregiver._id : alert.caregiver);
  const volunteerId = alert.volunteer
    ? String(alert.volunteer._id ? alert.volunteer._id : alert.volunteer)
    : null;
  return (
    user.role === 'admin' ||
    caregiverId === id ||
    (volunteerId && volunteerId === id) ||
    // Responders may open unassigned alerts (to step in when no one was
    // auto-assigned, or via the SMS deep link).
    (user.role === 'volunteer' && !volunteerId) ||
    (user.role === 'facility' && user.facility && String(alert.facility) === String(user.facility))
  );
}

// GET /api/v1/alerts — list alerts relevant to the requester
const listAlerts = asyncHandler(async (req, res) => {
  const { status } = req.query;
  const query = {};
  if (status) query.status = status;

  if (req.user.role === 'volunteer') query.volunteer = req.user._id;
  else if (req.user.role === 'facility') {
    if (!req.user.facility) throw ApiError.badRequest('Your account is not linked to a facility');
    query.facility = req.user.facility;
  } else if (req.user.role === 'caregiver') query.caregiver = req.user._id;

  const alerts = await Alert.find(query)
    .sort({ createdAt: -1 })
    .limit(100)
    .populate('caregiver', 'name phone community')
    .populate('volunteer', 'name phone')
    .populate('facility', 'name phone type');
  res.json({ success: true, alerts });
});

// GET /api/v1/alerts/:id
const getAlert = asyncHandler(async (req, res) => {
  const alert = await Alert.findById(req.params.id)
    .populate('caregiver', 'name phone community')
    .populate('volunteer', 'name phone')
    .populate('facility', 'name phone type location')
    .populate('assessment');
  if (!alert) throw ApiError.notFound('Alert not found');
  if (!canAccess(alert, req.user)) throw ApiError.forbidden();
  res.json({ success: true, alert });
});

// PATCH /api/v1/alerts/:id/status { status, note? } — volunteers/facilities move
// the referral along its lifecycle until the loop is closed.
const updateStatus = asyncHandler(async (req, res) => {
  const { status, note } = req.body;
  if (!STATUS_FLOW.includes(status)) {
    throw ApiError.badRequest(`status must be one of: ${STATUS_FLOW.join(', ')}`);
  }
  const alert = await Alert.findById(req.params.id);
  if (!alert) throw ApiError.notFound('Alert not found');
  if (!canAccess(alert, req.user) || req.user.role === 'caregiver') throw ApiError.forbidden();

  // A responder accepting an unassigned alert claims it.
  const claiming = req.user.role === 'volunteer' && !alert.volunteer;
  if (claiming) alert.volunteer = req.user._id;

  const firstAccept = status === 'acknowledged' && alert.status !== 'acknowledged';
  alert.status = status;
  alert.timeline.push({ event: status, by: req.user._id, note });
  await alert.save();

  // Tell the mother help is on the way the moment a responder accepts.
  if (firstAccept && req.user.role === 'volunteer') {
    const User = require('../models/User');
    const { sendSms } = require('../services/arkesel');
    const caregiver = await User.findById(alert.caregiver).lean();
    if (caregiver && caregiver.phone) {
      const who = req.user.name || 'A health responder';
      sendSms(
        caregiver.phone,
        `${who} (${req.user.phone}) has accepted your case and is on the way. Stay where you can be found and keep your phone close.`
      ).catch(() => {});
    }
  }
  res.json({ success: true, alert });
});

module.exports = { listAlerts, getAlert, updateStatus };
