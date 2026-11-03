# GrowWithMe Backend

Node.js/Express/MongoDB backend for **GrowWithMe** (working title: CareCompanion) — care reminders, offline triage sync, referral alerts and a consented action-model training feed for maternal and under-five health. It starts in Ghana and ships country care packs for Nigeria, Kenya, Uganda and Tanzania, with a safe international fallback for every other country.

The mobile app is **local-first**: everything works offline on the device, and this backend is the sync + coordination layer (SMS fallback, volunteer/facility alert routing, facility dashboard, optional AI).

## Stack

- Express 4 + Mongoose 8 (MongoDB)
- Arkesel — OTP login SMS, reminder SMS fallback, urgent alert SMS
- Cloudinary — photos and voice notes
- JWT auth (access + refresh), phone-number + OTP login
- node-cron — daily reminder SMS job (08:00) and care-signal scan

## Countries and care packs

`GET /api/v1/config/regions` returns every shipped care pack: administrative
regions, emergency numbers, languages, the national immunization schedule,
growth standard, familiar local foods and the applicable data-protection law.
`GET /api/v1/config/regions/:code` returns one pack; unknown codes fall back to
the international pack with `fallback: true` instead of failing — a caregiver
anywhere must still get safe guidance.

Adding a country is a data change in `src/config/regions.js`, not a code change.

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
| GET | `/health`, `/health/ready` | – | Liveness and Mongo-aware readiness |
| GET | `/config/app` | – | Feature flags, minimum version, supported languages |
| GET | `/config/regions` | – | All country care packs |
| GET | `/config/regions/:code` | – | One care pack (international fallback) |
| POST | `/auth/request-otp` | – | Send OTP to a phone number |
| POST | `/auth/verify-otp` | – | Verify OTP; creates account on first login; returns JWTs |
| POST | `/auth/refresh` | – | Exchange refresh token for new tokens |
| GET/PATCH/DELETE | `/users/me` | ✓ | Profile, consent flags, right-to-erasure delete |
| POST | `/sync` | ✓ | Local-first push/pull sync (see below) |
| POST | `/actions/events` | ✓ | Consented action events for on-device model training |
| GET | `/actions/summary` | admin | Aggregate-only action/screen/day counts |
| GET | `/actions/export` | admin | Streaming JSONL training set |
| GET | `/alerts` | ✓ | Alerts relevant to the requester (role-scoped) |
| PATCH | `/alerts/:id/status` | ✓ | Volunteer/facility advance the referral: acknowledged → en_route → at_facility → closed |
| GET | `/facilities` / `/facilities/nearby` | ✓ | Facility registry / geo lookup (country + region filters, paged) |
| POST | `/facilities/bulk` | admin | Idempotent national-registry import (max 5000/row batch) |
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

## Facility registry at national scale

Facilities carry `country` (ISO-3166, default `GH`) and an optional
`externalId` (DHIS2 org unit or national code). Listing is paged and filterable:

```
GET /facilities?country=GH&region=Northern&q=tamale&page=1&limit=50
GET /facilities/nearby?lng=-0.84&lat=9.4&maxKm=50&country=GH
```

`POST /facilities/bulk` (admin) imports up to 5000 rows per call. Rows with an
`externalId` are upserted by country + external code; otherwise country + name +
district is the natural key, so re-importing a registry never duplicates
facilities. Invalid rows are reported back instead of failing the whole batch.

## Action-model training feed

The app can record consented interactions (screen, action, target, allow-listed
metadata such as `offline`, `riskLevel`, `step`) and batch them to
`POST /actions/events` when connectivity returns. The collection is deliberately
narrow: **never** free text, names or health values. `params` is filtered against
an allow-list server-side and `clientEventId` makes retries idempotent.

- `GET /actions/summary?days=30` — aggregate counts for the admin dashboard.
- `GET /actions/export?days=180&country=GH&limit=100000` — chronological JSONL
  for training, with `sessionId` (random per app session) so sequences survive
  but no user reference is included.
- Events expire automatically after `ACTION_EVENT_RETENTION_DAYS` (default 400,
  minimum 30) via a TTL index.

## Operational safeguards

- **Phone numbers are masked in every log line** (`+233******78`); authenticated
  requests are tagged with a hashed user reference instead.
- **OTP abuse limits:** 5 codes per phone and 25 per IP per 15 minutes. Verify
  attempts are capped per caller, and each code already allows 5 guesses.
- **AI limits:** 40 Nana calls per user per hour per endpoint, so a stuck client
  cannot burn provider credits unnoticed.
- **General API ceiling:** `API_RATE_LIMIT_PER_MIN` (default 600) per IP.
  Set `RATE_LIMIT_DISABLED=true` only for local load tests.
- **Readiness and graceful shutdown:** `/health/ready` reflects Mongo state;
  `SIGTERM` drains in-flight requests and closes the database cleanly.
- Set `NODE_ENV=production` to enable `trust proxy` and require real JWT,
  Mongo and SMS environment variables at boot.

## Verifying the backend

```bash
npm run smoke
```

Runs the full HTTP flow against a throwaway `growwithme_smoke` database:
index builds, bulk facility import idempotency, geo lookup, action-event
idempotency, allow-list sanitisation, admin-only export, OTP rate limits and
the international care-pack fallback. It drops that database when done and
forces SMS into dev mode, so it never sends real messages.

## Privacy (MEST policy alignment)

- Consent flags captured at onboarding (`consent.dataProcessing`, `consent.locationOnUrgent`, `consent.smsReminders`).
- Location is only stored on urgent assessments/alerts, not continuously.
- `DELETE /users/me` implements the right to erasure — removes the account and every owned record.

## Roles

- `caregiver` — self-signup via OTP; owns children/pregnancies/assessments/reminders.
- `volunteer` — provisioned by admin; receives urgent alerts; has geolocation + availability.
- `facility` — provisioned by admin; linked to a `Facility`; sees catchment dashboard and facility alerts.
- `admin` — manages facilities and accounts.
