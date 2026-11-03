# MIT Solve Global Health Challenge — application pack (drafted 27 Oct 2026)

Portal: solve.mit.edu/challenges → Global Health Challenge. Deadline ~2 Nov 2026 (verify on portal).
Most long-form answers are adapted from UNICEF_form_answers.md — consistent story, consistent numbers.
The pitch video you record for UNICEF (UNICEF_pitch_video_guide.md) works here too — record once, use twice.

## Solution title
GrowWithMe — offline AI care companion for mothers and children under five

## One-line tagline (Solve loves these)
Care that works where the network doesn't: offline IMCI triage, EPI-synced reminders, and a closed SMS referral loop for last-mile mothers.

## Solution summary (~100 words)

GrowWithMe is an offline-first mobile platform for mothers and children under five in Northern Ghana, where connectivity, distance and literacy block timely care. It delivers IMCI-aligned child and pregnancy triage with zero connectivity, WHO growth monitoring with malnutrition flags, a care calendar synced to Ghana's EPI immunization schedule with spoken reminders, and "Nana", a voice-first AI educator with a compact on-device model. One tap generates a PDF patient report SMSed to the nearest clinic, volunteer responders and the hospital — every referral tracked to closure. The full product is built and working today; we seek funding for a supervised district pilot.

## What need/challenge does it address (use UNICEF "Need" answer, 100–150 words)
→ paste from UNICEF_form_answers.md

## How it solves it (use UNICEF "Solution" answer)
→ paste from UNICEF_form_answers.md

## What makes it innovative (draft — ~120 words)

Three design properties that existing maternal-health apps in the region lack, engineered from day one rather than retrofitted: (1) The core journey — triage, calendar, growth monitoring — runs with the network fully off, including Nana's on-device AI understanding in about one megabyte. (2) Risk classification is deliberately bounded: a deterministic IMCI-aligned rules engine owns every verdict and can raise, never lower, an AI suggestion — making the system auditable by health authorities in a way LLM-first products are not. (3) The referral loop closes: most digital tools stop at "alert sent", while GrowWithMe tracks each urgent alert from danger sign to confirmed facility arrival, and surfaces missed visits, growth faltering and lost-to-follow-up families on a facility dashboard.

## Equity statement (draft — ~100 words)

GrowWithMe is built for the families digital health usually skips: low-literacy mothers on basic Android phones with no data credit. Every critical flow is usable by voice, in simple language, with consent explained aloud before any data is collected. SMS keeps the referral loop working on any phone, including feature phones held by caregivers and volunteers. The design decisions come from the context itself — Northern Ghana's connectivity gaps, literacy levels and health-worker realities — and the pilot is co-designed with community health workers and a community-rooted local NGO rather than parachuted in.

## Impact & metrics to report in the application (use honestly)

- Working prototype, internally verified end-to-end (offline triage, alerts, calendar, offline Nana) — no field trial yet; the pilot is the ask.
- Pilot targets: 1,500–2,000 mother-child registrations; every urgent alert time-stamped from danger sign to facility arrival; measurable lift in EPI completion and ANC/PNC attendance vs district baseline.
- Repository (public): https://github.com/pious2847/GrowWithMe
- Website: https://pious2847.github.io/GrowWithMe/

## Stage selector
Prototype → moving to Pilot. Markets: Ghana (first), scalable to other low-connectivity settings in West Africa and beyond.

## Video link
Same 2-minute real-team video as UNICEF (record once, use twice). Animated demo available as a supplement, not a substitute.

## Team
Abdul Hafis Mohammed — Founder, CEO & Software Engineer, TOVO LABs (Ghanaian software engineering & product studio). Built the full stack in-house: Flutter offline-first app, Node/Express/MongoDB backend, SMS referral gateway, hybrid AI (cloud LLM + on-device model). [Add other team members here if any — do not invent.]
