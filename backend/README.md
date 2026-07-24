# GrowWithMe Backend

Node.js/Express/MongoDB backend for **GrowWithMe** (working title: CareCompanion) — care reminders, offline triage sync, and referral alerts for maternal and under-five health in Northern Ghana.

The mobile app is **local-first**: everything works offline on the device, and this backend is the sync + coordination layer (SMS fallback, volunteer/facility alert routing, facility dashboard).

## Stack

- Express 4 + Mongoose 8 (MongoDB)
- Arkesel — OTP login SMS, reminder SMS fallback, urgent alert SMS
- Cloudinary — photos and voice notes
- JWT auth (access + refresh), phone-number + OTP login
- node-cron — daily reminder SMS job (08:00)

## Getting started

```bash
cd backend
npm install
copy .env.example .env   # then fill in values
npm run dev
```

Requirements: Node 20+, MongoDB running locally (or an Atlas URI in `MONGODB_URI`).

Dev conveniences:
- With `ARKESEL_API_KEY` empty, SMS (including OTP codes) are printed to the server console instead of sent.
- `npm run seed` loads demo facilities around Tamale plus a demo volunteer and facility-staff account.

## API overview (`/api/v1`)

| Method | Route | Auth | Purpose |
| --- | --- | --- | --- |
| POST | `/auth/request-otp` | – | Send OTP to a phone number |
| POST | `/auth/verify-otp` | – | Verify OTP; creates account on first login; returns JWTs |
| POST | `/auth/refresh` | – | Exchange refresh token for new tokens |
| GET/PATCH/DELETE | `/users/me` | ✓ | Profile, consent flags, right-to-erasure delete |
| POST | `/sync` | ✓ | Local-first push/pull sync (see below) |
| GET | `/alerts` | ✓ | Alerts relevant to the requester (role-scoped) |
| PATCH | `/alerts/:id/status` | ✓ | Volunteer/facility advance the referral: acknowledged → en_route → at_facility → closed |
| GET | `/facilities` / `/facilities/nearby` | ✓ | Facility registry / geo lookup |
| POST | `/uploads` | ✓ | Multipart upload (field `file`) → Cloudinary URL |
| GET | `/dashboard/catchment` | facility/admin | Mothers & children with latest risk, missed visits, open cases |

## Sync protocol

`POST /api/v1/sync`

```json
{
  "lastPulledAt": 0,
  "push": {
    "children": [ { "_id": "<uuid>", "clientUpdatedAt": 1721800000000, "name": "...", "dateOfBirth": "..." } ],
    "pregnancies": [],
    "assessments": [],
    "reminders": []
  }
}
```

Rules:
- `_id` is a **client-generated UUID** so records can be created offline.
- Conflicts resolve **last-write-wins** on the device-set `clientUpdatedAt` (epoch ms).
- Deletes are soft (`deleted: true` tombstones) so they propagate across devices.
- Response contains `pull` (all server changes since `lastPulledAt`, plus the user's alerts) and `serverTime` — store it as the next `lastPulledAt`.
- **An urgent assessment pushed during sync automatically fires the referral flow**: nearest available volunteer (25 km) and facility (50 km) found by geo query, SMS sent to volunteer + facility + caregiver, `Alert` record created and returned in the next pull. This is how offline triage results trigger help the moment connectivity returns.

## Privacy (MEST policy alignment)

- Consent flags captured at onboarding (`consent.dataProcessing`, `consent.locationOnUrgent`, `consent.smsReminders`).
- Location is only stored on urgent assessments/alerts, not continuously.
- `DELETE /users/me` implements the right to erasure — removes the account and every owned record.

## Roles

- `caregiver` — self-signup via OTP; owns children/pregnancies/assessments/reminders.
- `volunteer` — provisioned by admin; receives urgent alerts; has geolocation + availability.
- `facility` — provisioned by admin; linked to a `Facility`; sees catchment dashboard and facility alerts.
- `admin` — manages facilities and accounts.
