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
  if (coordinates && coordinates.length === 2) {
    [volunteer, facility] = await Promise.all([
      findNearestVolunteer(coordinates),
      findNearestFacility(coordinates),
    ]);
  }

  const alert = new Alert({
    assessment: assessment._id,
    caregiver: caregiver._id,
    summary,
    location: coordinates ? { type: 'Point', coordinates } : undefined,
    volunteer: volunteer ? volunteer._id : undefined,
    facility: facility ? facility._id : undefined,
    status: volunteer || facility ? 'pending' : 'unassigned',
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
      sendSms(facility.phone, `${summary}${mapsLink} A case may be on the way to your facility.`).then((r) =>
        alert.smsResults.push({ to: facility.phone, kind: 'facility', ok: r.ok, error: r.error })
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

  await Promise.all(sends);
  if (volunteer || facility) {
    alert.status = 'notified';
    alert.timeline.push({ event: 'notified', note: 'Volunteer/facility notified by SMS' });
  }
  await alert.save();
  return alert;
}

module.exports = { raiseAlert };
