# UNICEF Femtech Ventures — application answers (paste-ready, word-counts validated 25 Oct 2026)

**Deadline: 4 Nov 2026** · portal: unicef.org/innovation/FemTechCall

## Quick fields

| Field | Value |
|---|---|
| Company's web page | `https://pious2847.github.io/GrowWithMe/` *(live after the 30-second Pages toggle — see checklist)* |
| Designation | Founder, CEO & Software Engineer |
| Year founded | 2026 |
| Solution addresses | The **maternal continuum of care** option (Pillar 1) — plus any options matching: maternal/newborn health, child health, last-mile/offline access |
| Technologies used | AI/Machine learning · Mobile application · Offline/edge computing · SMS/messaging (pick the equivalents in their list) |
| Repository | `https://github.com/pious2847/GrowWithMe` — **already public**, no access grant needed |
| Amount to raise | `$100,000` |
| Revenue last year | `$0` (founded 2026; pre-revenue) |
| Share with partners? | **Yes** (more exposure through their partner network) |
| Newsletter? | Yes |

## Need or challenge (100–150 words)

Northern Ghana carries some of the country's worst maternal and child health outcomes. Ghana's maternal mortality ratio stands at 234 deaths per 100,000 live births, with the northern regions historically above the national average. Around 30% of children under five in the North are stunted; roughly three in four households face food insecurity; and only about one child in four receives a minimum acceptable diet. The drivers are structural: long distances to facilities, poor connectivity, low literacy, and referrals that quietly die between the CHPS compound and the hospital. Existing digital-health pilots fail here because they assume a smartphone, data credit, or literacy that families do not have. Mothers and children under five therefore lack timely, continuous care from pregnancy through the fifth year — the exact gap GrowWithMe addresses.

## Solution (100–250 words)

GrowWithMe, by TOVO LABs, is an offline-first care companion for mothers and children under five in Northern Ghana, delivered as an Android app that works fully without data. It combines five engineered capabilities. First, IMCI-aligned triage for children and pregnancy: adaptive questions with deterministic danger rules that always override the AI, running with zero connectivity. Second, WHO growth monitoring that plots every weight and raises a malnutrition flag below minus two standard deviations. Third, a care calendar synced to Ghana's EPI immunization schedule — immunizations, ANC and PNC visits, Vitamin A, deworming — with spoken reminders for low-literacy mothers. Fourth, "Nana", a voice-first AI health educator with a compact on-device model that keeps core commands working offline. Fifth, a closed referral loop: one tap generates a PDF patient report and SMSes it to the nearest CHPS compound, registered volunteer responders and the mother's hospital, with every alert tracked to closure on a facility dashboard that also surfaces missed visits, growth faltering and lost-to-follow-up families. Consent-first onboarding and local-language-friendly content are built in from day one.

## How are you using the technologies (100–150 words)

We use AI in a deliberately bounded way. A cloud LLM (Llama 3.1 via NVIDIA NIM) powers Nana's conversational health education when online, and a compact fine-tuned on-device language model keeps core voice commands working with no connectivity; ElevenLabs provides speech. Risk classification is never delegated to AI: a deterministic IMCI-aligned rules engine owns every verdict, keeping decisions auditable for health authorities. The app is built in Flutter with an offline-first architecture (local sync, last-write-wins, tombstones), backed by Node/Express and MongoDB, the Arkesel SMS gateway and Cloudinary — API keys proxied server-side so nothing sensitive sits on the device. SMS keeps the referral loop alive on any phone, with or without data.

## Current technical status (100–150 words)

The solution is a working prototype, fully built and demonstrable today. The caregiver Android app, responder flow, facility dashboard, SMS referral routing, offline triage, EPI-synced care calendar, growth monitoring and both online and offline Nana modes are implemented; a demo APK runs the complete offline journey in airplane mode. What remains before pilot: completing registration of TOVO LABs as a private company in Ghana (in progress); a supervised district pilot agreement with the Ghana Health Service in the Northern Region (conversations initiated with the GHS Country Innovation Platform); CHW training materials; and a data-protection review of pilot procedures with the district health directorate. A demonstration video and the APK are available to reviewers immediately.

## Prototyping and testing results (100–150 words)

Testing to date is internal functional verification, not yet a field trial. Every core flow has been exercised end-to-end on real Android devices: offline triage completes with the network disabled and returns correct low, moderate or urgent verdicts; urgent alerts generate the PDF patient report and dispatch SMS to facility and responder test numbers; the EPI-synced calendar schedules immunization, ANC/PNC, Vitamin A and deworming reminders correctly by child age; WHO minus-two-SD crossings raise malnutrition flags; and Nana's on-device model handles core commands in airplane mode. The referral loop was verified with test recipients acknowledging and closing alerts on the facility dashboard. A supervised field pilot with CHPS facilities is the explicit next step, and the purpose of this application.

## 12-month targets/milestones (100–150 words)

Months 1–3: complete company registration; sign a supervised-pilot agreement with GHS or the district health directorate; finalize data-protection and consent procedures. Months 4–6: train about 40 community health workers and launch in one Northern Region district with roughly five CHPS facilities, targeting 1,500–2,000 mother-and-child registrations. Months 7–9: operate the pilot with every urgent alert time-stamped from danger sign to facility arrival; iterate from CHW and mother feedback; publish the open-source components required by the fund. Months 10–12: demonstrate measurable lifts in EPI schedule completion and ANC/PNC attendance against the district baseline; deliver the pilot report; and prepare the scale-up plan with GHS for additional districts.

## Key partners (max 150 words)

NA — no formal partners yet. In October 2026 we initiated pilot and implementation conversations with the Ghana Health Service Country Innovation Platform, UNDP Ghana Accelerator Lab, UNFPA Ghana, WHO Ghana, RAINS Tamale, Moving Health Foundation and MTN Ghana Foundation, and a joint evaluation discussion with the University for Development Studies, Tamale.

## Capital and contributions (100–150 words)

TOVO LABs is founder-funded. Contributions to date: over a year of unpaid founder engineering time across mobile, backend and AI integration — the entire platform was built in-house — plus personal laptops and Android test devices, internet and cloud costs, SMS gateway test credits, and self-created training data for the on-device model (a 55,000-example intent dataset). No external investment, grants or loans have been received. This grant would be the first external capital, covering pilot operations, devices for community health workers, SMS and data costs, clinical-content review and independent evaluation — converting a self-funded working prototype into measured field evidence. The founding team continues to work on the project full-time, without salary.
