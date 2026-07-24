# GrowWithMe — Feature Roadmap

AI-assisted care reminders, risk detection and referral alerts for mothers and
children 0–59 months in Northern Ghana. Local-first Flutter app + Node/MongoDB
backend + Arkesel SMS + Cloudinary.

## Shipped

| Feature | Theme |
| --- | --- |
| Phone + OTP auth (real SMS via Arkesel), consent-first onboarding | Responsible |
| Local-first sync (offline UUIDs, LWW, tombstones) | Low connectivity |
| Offline IMCI-aligned triage (child + pregnancy), adaptive questions | Early risk detection |
| Urgent alert flow: geo-routed nearest volunteer + facility, SMS to all parties | Referral follow-up |
| Care calendar: Ghana EPI immunizations, Vitamin A, deworming, growth checks, ANC/PNC | Reminders |
| Pregnancy journey: LMP/EDD → ANC calendar → "baby is born" → PNC + newborn handoff | Continuum of care |
| Growth monitoring: WHO weight-for-age screening + chart, offline malnutrition flags | Early risk detection |
| Nutrition tips engine: age-banded, Northern Ghana foods, daily rotation | Local nutrition guidance |
| Voice mode: auto-read questions, urgent guidance always spoken | Voice-first |
| Home-screen reminders widget, facility catchment dashboard API, request logging | CHPS workflows |

## Shipped (wave 2)

| Feature | Theme |
| --- | --- |
| "Nana" AI educator: chat + voice (NVIDIA NIM + ElevenLabs, offline intent fallback), agentic actions with confirmation, persistent conversation memory (synced) | Voice-first, AI |
| Nana home-screen widget (tap → spoken daily briefing) + reminders widget | Low literacy |
| AI pregnancy check-ins every 2–3 days: personalized questions from her history; fixed deterministic danger core always wins | Early risk detection |
| High-risk → automatic PDF patient report (pdfkit → Cloudinary) SMSed to her registered check-up hospital, responders and Care Circle | Referral follow-up |
| Emergency closest-hospital fallback via Google Places (name + phone + live location SMS) when registry has nothing nearby | Referral |
| Pregnancy journey card: week progress, local baby-size analogies, week-aware do's & don'ts, risk badge, check-in prompts | Education |
| Care Signals monitoring scan + Care Circle + first-aid cards | CHPS workflows |
| **Nana's Kitchen**: seasonal, budget-adaptive meal plans (AI builds from her pantry when money is tight; portions in local measures; offline library fallback) for pregnancy, lactation and young children | Local nutrition guidance |
| **Daily Plate tracker**: tap-the-food-groups dietary diversity score (WHO-style, 8 groups, target 5+) with weekly chart; plans and logs persisted + synced | Nutrition, low literacy |

## Building now

### 1. "Nana" — AI care educator (in-app + widget)
- Chat assistant with a caring Ghanaian-elder persona; simple English, short sentences.
- **Brain**: NVIDIA NIM free API (Llama 3.1 70B, OpenAI-compatible), proxied by our
  backend so keys stay server-side. **Never diagnoses** — the deterministic triage
  engine remains the only risk classifier; Nana educates and escalates.
- **Agentic actions** with user confirmation: add a child, start pregnancy tracking,
  log a weight, read today's plan. Executed **locally** (local-first) then synced.
- **Hybrid offline**: local intent parser covers core commands with no connectivity;
  the LLM enriches when online.
- **Voice**: ElevenLabs free tier for natural speech (backend proxy), on-device TTS
  as automatic offline fallback; mic input via on-device speech recognition.
- **Second home-screen widget**: "Nana says…" daily message; tap → app opens and
  speaks your daily briefing.

### 2. Care Signals — monitor everything, catch issues early
Daily backend scan producing prioritized signals for CHPS staff:
- Missed visits (immunization/ANC) past grace period
- Urgent alerts not closed within 24h (broken referral loop)
- Growth faltering (weight under −2SD or trending down)
- Third-trimester pregnancies with overdue ANC
- **Lost-to-follow-up radar**: families with no app activity in 30+ days, ranked by
  risk (recent urgent case, underweight child, late pregnancy first)
Each signal → facility dashboard + gentle SMS nudge to the caregiver.

### 3. Care Circle
Link a second phone (father, grandmother) that receives SMS copies of reminders
and urgent alerts — the person who controls transport often isn't the mother.

### 4. First-aid cards
On an urgent result: spoken, emoji-illustrated "do this right now while help
comes" steps (convulsion positioning, ORS with local measures, keep breastfeeding,
kangaroo warmth for newborns).

## Next
- Facility dashboard web UI (API exists)
- Recorded Dagbani/local-language audio prompts through the same voice pipeline
- SMS/USSD companion channel for feature phones
- Immunization card photo backup (Cloudinary)
