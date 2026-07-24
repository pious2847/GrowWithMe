const asyncHandler = require('../utils/asyncHandler');
const ApiError = require('../utils/apiError');

const ALLOWED_UPDATES = [
  'name',
  'language',
  'region',
  'district',
  'community',
  'photoUrl',
  'available',
];

// GET /api/v1/users/me
const getMe = asyncHandler(async (req, res) => {
  res.json({ success: true, user: req.user });
});

// PATCH /api/v1/users/me
const updateMe = asyncHandler(async (req, res) => {
  for (const key of ALLOWED_UPDATES) {
    if (req.body[key] !== undefined) req.user[key] = req.body[key];
  }
  if (req.body.location && Array.isArray(req.body.location.coordinates)) {
    req.user.location = { type: 'Point', coordinates: req.body.location.coordinates };
  }
  if (req.body.consent) {
    const { dataProcessing, locationOnUrgent, smsReminders } = req.body.consent;
    if (dataProcessing !== undefined) req.user.consent.dataProcessing = dataProcessing;
    if (locationOnUrgent !== undefined) req.user.consent.locationOnUrgent = locationOnUrgent;
    if (smsReminders !== undefined) req.user.consent.smsReminders = smsReminders;
    req.user.consent.consentedAt = new Date();
  }
  await req.user.save();
  res.json({ success: true, user: req.user });
});

// DELETE /api/v1/users/me — MEST privacy policy: right to erasure.
// Removes the account and all owned records.
const deleteMe = asyncHandler(async (req, res) => {
  const Child = require('../models/Child');
  const Pregnancy = require('../models/Pregnancy');
  const Assessment = require('../models/Assessment');
  const Reminder = require('../models/Reminder');
  const Alert = require('../models/Alert');

  const owner = req.user._id;
  await Promise.all([
    Child.deleteMany({ owner }),
    Pregnancy.deleteMany({ owner }),
    Assessment.deleteMany({ owner }),
    Reminder.deleteMany({ owner }),
    Alert.deleteMany({ caregiver: owner }),
  ]);
  await req.user.deleteOne();
  res.json({ success: true, message: 'Account and all associated data deleted' });
});

module.exports = { getMe, updateMe, deleteMe };
