const asyncHandler = require('../utils/asyncHandler');
const User = require('../models/User');
const Child = require('../models/Child');
const Assessment = require('../models/Assessment');
const Reminder = require('../models/Reminder');
const Alert = require('../models/Alert');

// GET /api/v1/dashboard/catchment (facility/admin)
// The lightweight facility view: registered mothers & children with their
// latest risk status, upcoming/missed visits, and open urgent cases.
// Catchment = caregivers in the facility's district when set, else all.
const catchment = asyncHandler(async (req, res) => {
  const caregiverQuery = { role: 'caregiver' };
  if (req.user.role === 'facility' && req.user.district) {
    // Caregivers who haven't set a district yet stay visible to every facility
    // rather than falling through the cracks of the catchment filter.
    caregiverQuery.$or = [
      { district: req.user.district },
      { district: { $in: [null, ''] } },
    ];
  }

  const caregivers = await User.find(caregiverQuery)
    .select('name phone community district lastSyncedAt')
    .sort({ name: 1 })
    .limit(500)
    .lean();
  const caregiverIds = caregivers.map((c) => c._id);

  const now = new Date();
  const [children, latestAssessments, reminders, openAlerts] = await Promise.all([
    Child.find({ owner: { $in: caregiverIds }, deleted: false })
      .select('name sex dateOfBirth owner')
      .lean(),
    Assessment.aggregate([
      { $match: { owner: { $in: caregiverIds }, deleted: false } },
      { $sort: { completedAt: -1 } },
      { $group: { _id: '$owner', riskLevel: { $first: '$riskLevel' }, completedAt: { $first: '$completedAt' } } },
    ]),
    Reminder.aggregate([
      { $match: { owner: { $in: caregiverIds }, deleted: false, status: { $in: ['upcoming', 'missed'] } } },
      {
        $group: {
          _id: '$owner',
          missed: { $sum: { $cond: [{ $eq: ['$status', 'missed'] }, 1, 0] } },
          upcoming: { $sum: { $cond: [{ $eq: ['$status', 'upcoming'] }, 1, 0] } },
          nextDue: { $min: { $cond: [{ $gte: ['$dueDate', now] }, '$dueDate', null] } },
        },
      },
    ]),
    Alert.find({ caregiver: { $in: caregiverIds }, status: { $nin: ['closed'] } })
      .select('caregiver status createdAt summary')
      .lean(),
  ]);

  const byOwner = (arr) => Object.fromEntries(arr.map((x) => [String(x._id), x]));
  const childrenByOwner = {};
  for (const child of children) {
    (childrenByOwner[String(child.owner)] ||= []).push(child);
  }
  const assessmentMap = byOwner(latestAssessments);
  const reminderMap = byOwner(reminders);
  const alertsByOwner = {};
  for (const alert of openAlerts) {
    (alertsByOwner[String(alert.caregiver)] ||= []).push(alert);
  }

  const rows = caregivers.map((cg) => {
    const id = String(cg._id);
    return {
      caregiver: cg,
      children: childrenByOwner[id] || [],
      latestRisk: assessmentMap[id] || null,
      visits: reminderMap[id] || { missed: 0, upcoming: 0, nextDue: null },
      openAlerts: alertsByOwner[id] || [],
    };
  });

  res.json({
    success: true,
    stats: {
      caregivers: caregivers.length,
      children: children.length,
      openUrgentCases: openAlerts.length,
      caregiversWithMissedVisits: rows.filter((r) => r.visits.missed > 0).length,
    },
    rows,
  });
});

module.exports = { catchment };
