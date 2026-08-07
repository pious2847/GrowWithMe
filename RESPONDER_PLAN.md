# GrowWithMe Responder — Plan

The second app in the GrowWithMe system: for health volunteers, CHWs, nurses,
midwives and doctors who answer urgent alerts. Closes the referral loop the
caregiver app opens.

## Architecture decisions

- **Separate Flutter app** (`responder/`), same backend, same OTP auth. A
  responder is a `User` with `role: 'volunteer'` plus a new `credentials`
  block; caregivers and responders never mix UIs.
- **Map: flutter_map (OpenStreetMap)** — no API key, no billing, works for
  the demo and rural Ghana. Google Maps only via "Navigate" deep links
  (turn-by-turn happens in the Google Maps app, free).
- **SMS stays the push channel** (no FCM for hackathon). The alert SMS now
  carries a deep link that opens the responder app on the live alert.
- **Verification is manual-by-admin** (hackathon-real): responder uploads
  Ghana Card + professional license photos → Cloudinary; an admin endpoint
  approves and sets the tier. Unverified users can register but stay
  "pending" and rank lowest in routing.

## Responder tiers & routing priority

`credentials.tier`: `volunteer` < `chw` < `nurse` < `midwife` < `doctor`

Alert routing (replaces nearest-volunteer):
1. Geo query: all available responders within 25 km of the patient.
2. Score = tierWeight (2/3/4/4.5/5) + 2 if verified − 0.15 × distanceKm.
3. Highest score is assigned + SMSed; facility + its emergency contacts
   are SMSed in parallel. A verified nurse 5 km away beats an unverified
   volunteer 1 km away; a volunteer 1 km away beats a doctor 24 km away.

## Backend additions (same service)

- `User.credentials`: tier, licenseNumber, documents[{kind,url}],
  status unverified|pending|verified|rejected, verifiedAt. `User.lastSeenAt`.
- `Facility.emergencyContacts[{name, phone, role}]` — all pinged on alerts.
- Routes `/api/v1/responder/*`:
  - `POST /profile` — become a responder (tier, region, license no.)
  - `POST /documents` — multipart upload (ghana_card | license | other) → Cloudinary
  - `POST /location` — heartbeat {lng, lat}; app sends on open + every few
    minutes foregrounded → keeps routing fresh
  - `POST /availability` — on/off duty
  - `GET /alerts` — mine (active) + unassigned nearby
  - `GET /alerts/:id` — live detail: summary, danger signs, report URL,
    patient phone, location, timeline
  - `POST /alerts/:id/status` — acknowledged | en_route | at_facility |
    closed (+SMS to caregiver on accept: "help is coming")
  - `GET /facilities/nearby` — registry facilities around the responder
- Admin (role=admin): `POST /admin/verify/:userId`, `POST /admin/facilities`
  (with emergency contacts), `GET /admin/pending`.
- Deep link: `GET /a/:alertId` — public HTML: minimal status + "Open in
  responder app" (`growwithme://alert/<id>`), used as the SMS link.

## Responder app screens

1. **Onboarding**: phone OTP (same flow) → "I am a responder" profile form
   (name, tier, region/district, license no.) → document capture
   (Ghana Card front + professional license, camera/gallery) → pending-
   verification screen (auto-refreshes; badge when verified).
2. **Home**: on/off-duty switch, verified badge, list of alerts (mine first,
   then nearby unassigned) with distance + age; pull-to-refresh + 30 s poll.
3. **Map tab**: OSM map with my location, alert pins (red), facility pins
   (green); tap pin → alert/facility card.
4. **Alert detail**: danger signs, patient name/phone (call button), risk
   report (opens PDF), distance, big action buttons: Accept → En route →
   At facility → Close; "Navigate" opens Google Maps directions.
5. **Deep link**: SMS link opens straight into Alert detail.

## Milestones

- **M1 (backend)**: models + responder routes + tiered routing + facility
  contacts + deep-link page. Testable with curl before any UI exists.
- **M2 (app core)**: project init, auth, responder registration + document
  upload, pending/verified state.
- **M3 (alerts)**: home list + alert detail + status actions + navigate.
- **M4 (map + polish)**: map tab, location heartbeat, deep link handling,
  demo seed (verified nurse near demo location).

## Demo story (hackathon)

Mother's check-in finds danger signs → volunteer 0500782010 (verified
nurse, 2 km away) gets SMS → taps link → sees live report + map → Accept
(mother gets "Nurse X is coming" SMS) → Navigate → At facility → Close.
Full loop, two phones, ~90 seconds.
