# GrowWithMe — Demo APK Install Guide (TOVO LABs)

**Included with our outreach emails** for technical reviewers who want to run the real app.

## What this is
- File: `GrowWithMe-demo.apk` — release build of the caregiver app (mothers' client).
- Android 8.0+ (arm64). No Play Store needed. Full offline core: triage, calendar, growth charts, Nana offline mode all work with data off.

## Install (5 minutes)
1. Copy the APK to the phone (WhatsApp to yourself, USB, or Google Drive).
2. Tap the APK → Android will ask to allow installing from that app (Settings → Install unknown apps → Allow for that browser/file manager once).
3. Tap Install → Open.
4. Register a phone number — a real SMS OTP arrives only if the Arkesel backend is up; otherwise use the reviewer demo login if provided in the email cover note. [CONFIRM demo login before sending]

## What to try first
1. **Add a child** (name, age) → care calendar builds offline.
2. **Run a triage** for the child — try a "urgent" symptom combination to see the alert flow: nearest responder + facility SMS routing + PDF patient report.
3. **Turn on Airplane mode** and run triage again — it still works.
4. **Ask Nana** something (mic or keyboard): "add child", "what are the immunizations for a 6 month old".
5. Growth: log a weight below the WHO −2SD line and see the malnutrition flag.

## Notes for reviewers
- The app is consent-first: onboarding explains what is stored and why; location only asked at urgent alert time.
- No data leaves the device except SMS gateway traffic (backend proxied) and explicit Cloudinary-hosted patient reports for referrals.
- AI: NVIDIA NIM (Llama 3.1) when online; 1 MB on-device intent engine when offline. Nana never diagnoses — deterministic IMCI-aligned rules own every risk verdict.
- Full feature list: ROADMAP.md (on request).

Contact: Abdul Hafis Mohammed — CEO & Software Engineer, TOVO LABs | abdulhafis2847@gmail.com | [+233 ...]
