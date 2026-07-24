const Alert = require('../models/Alert');
const User = require('../models/User');
const Facility = require('../models/Facility');
const { sendSms } = require('./arkesel');

const MAX_VOLUNTEER_DISTANCE_M = 25000; // 25 km
const MAX_FACILITY_DISTANCE_M = 50000; // 50 km

function findNearestVolunteer(coordinates) {
  return User.findOne({
    role: 'volunteer',
    available: true,
    location: {
      $near: {
        $geometry: { type: 'Point', coordinates },
        $maxDistance: MAX_VOLUNTEER_DISTANCE_M,
      },
    },
  });
}

function findNearestFacility(coordinates) {
  return Facility.findOne({
    active: true,
    location: {
      $near: {
        $geometry: { type: 'Point', coordinates },
        $maxDistance: MAX_FACILITY_DISTANCE_M,
      },
    },
  });
}

function buildSummary(assessment, caregiver) {
  const signs = (assessment.dangerSigns || []).join(', ') || 'not specified';
  const subject =
    assessment.subjectType === 'child'
      ? 'a child under 5'
      : assessment.subjectType === 'pregnancy'
        ? 'a pregnant mother'
        : 'a mother';
  return (
    `URGENT: ${caregiver.name || 'A caregiver'} (${caregiver.phone}) needs help for ${subject}. ` +
    `Danger signs: ${signs}.`
  );
}

/**
 * Raises the referral alert for an urgent assessment: finds the nearest
 * available volunteer and facility, records the Alert, and notifies both by
 * SMS (plus a confirmation SMS to the caregiver). Falls back to 'unassigned'
 * with self-help guidance when no volunteer is in range.
 */
async function raiseAlert(assessment, caregiver) {
  const coordinates = assessment.location && assessment.location.coordinates;
  const summary = buildSummary(assessment, caregiver);

  let volunteer = null;
  let facility = null;
  let placesHospital = null;
  if (coordinates && coordinates.length === 2) {
    [volunteer, facility] = await Promise.all([
      findNearestVolunteer(coordinates),
      findNearestFacility(coordinates),
    ]);
    // Real-world fallback: nothing in our registry nearby → ask Google Places
    // for the closest hospital and its phone number.
    if (!facility) {
      const { findNearestHospital } = require('./googlePlaces');
      placesHospital = await findNearestHospital(coordinates[0], coordinates[1]);
    }
  }

  // Clinician-facing PDF report (best-effort) — travels by SMS link so the
  // receiving facility can see history before the patient arrives.
  const { buildRiskReport } = require('./reportService');
  const reportUrl = await buildRiskReport(caregiver, assessment);
  const reportNote = reportUrl ? ` Patient report: ${reportUrl}` : '';

  // The hospital where she does her checks/scans, if registered.
  let usualHospital = null;
  if (assessment.pregnancy) {
    const Pregnancy = require('../models/Pregnancy');
    const preg = await Pregnancy.findById(assessment.pregnancy).lean();
    if (preg && preg.hospitalPhone) {
      usualHospital = { name: preg.hospitalName, phone: preg.hospitalPhone };
    }
  }

  const alert = new Alert({
    assessment: assessment._id,
    caregiver: caregiver._id,
    summary,
    location: coordinates ? { type: 'Point', coordinates } : undefined,
    volunteer: volunteer ? volunteer._id : undefined,
    facility: facility ? facility._id : undefined,
    reportUrl: reportUrl || undefined,
    status: volunteer || facility || placesHospital ? 'pending' : 'unassigned',
    timeline: [{ event: 'created', note: 'Urgent assessment received' }],
  });

  const mapsLink =
    coordinates && coordinates.length === 2
      ? ` Location: https://maps.google.com/?q=${coordinates[1]},${coordinates[0]}`
      : '';

  const sends = [];
  if (volunteer && volunteer.phone) {
    sends.push(
      sendSms(volunteer.phone, `${summary}${mapsLink} Please respond and assist to the nearest facility.`).then(
        (r) => alert.smsResults.push({ to: volunteer.phone, kind: 'volunteer', ok: r.ok, error: r.error })
      )
    );
  }
  if (facility && facility.phone) {
    sends.push(
      sendSms(facility.phone, `${summary}${mapsLink}${reportNote} A case may be on the way to your facility.`).then((r) =>
        alert.smsResults.push({ to: facility.phone, kind: 'facility', ok: r.ok, error: r.error })
      )
    );
  }
  // Closest hospital found via Google Places (registry had nothing nearby)
  if (placesHospital && placesHospital.phone) {
    sends.push(
      sendSms(
        placesHospital.phone,
        `${summary}${mapsLink}${reportNote} A patient near you needs urgent care and may be heading to your facility.`
      ).then((r) =>
        alert.smsResults.push({ to: placesHospital.phone, kind: 'facility', ok: r.ok, error: r.error })
      )
    );
  }
  // Her usual hospital gets the report for follow-up, even if it is not the closest.
  if (usualHospital && usualHospital.phone) {
    sends.push(
      sendSms(
        usualHospital.phone,
        `GrowWithMe: your antenatal patient ${caregiver.name || caregiver.phone} had an urgent risk assessment.${reportNote}${mapsLink} Please follow up.`
      ).then((r) =>
        alert.smsResults.push({ to: usualHospital.phone, kind: 'usual_hospital', ok: r.ok, error: r.error })
      )
    );
  }
  const caregiverMsg = volunteer
    ? `Help is on the way. Volunteer ${volunteer.name || ''} (${volunteer.phone}) has been notified.` +
      (facility ? ` Nearest facility: ${facility.name}.` : '')
    : facility
      ? `Please go to ${facility.name}${facility.phone ? ` (${facility.phone})` : ''} as soon as possible. They have been notified.`
      : 'No volunteer is available nearby. Please move to the nearest health facility as soon as possible.';
  sends.push(
    sendSms(caregiver.phone, caregiverMsg).then((r) =>
      alert.smsResults.push({ to: caregiver.phone, kind: 'caregiver', ok: r.ok, error: r.error })
    )
  );
  // Care Circle: the family members who can arrange transport get told too.
  for (const member of caregiver.careCircle || []) {
    if (!member.phone) continue;
    sends.push(
      sendSms(member.phone, `${summary}${mapsLink} Please help them get to a health facility now.`).then(
        (r) => alert.smsResults.push({ to: member.phone, kind: 'care_circle', ok: r.ok, error: r.error })
      )
    );
  }

  await Promise.all(sends);
  if (volunteer || facility || placesHospital || usualHospital) {
    alert.status = 'notified';
    alert.timeline.push({ event: 'notified', note: 'Responders notified by SMS' });
  }
  await alert.save();
  return alert;
}

module.exports = { raiseAlert };
