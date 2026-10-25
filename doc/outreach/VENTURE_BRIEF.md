# GrowWithMe â€” Venture Brief (1-page, by TOVO LABs)

**GrowWithMe, by TOVO LABs â€” offline AI care companion for mothers and children 0â€“59 months in Northern Ghana.**

**The problem.** Northern Ghana carries some of the country's worst maternal and child health outcomes. The causes are structural and well known: long distances to facilities, poor connectivity, low literacy, and referrals that quietly die between the CHPS compound and the hospital. Most digital-health pilots fail here for the same reasons â€” they assume a smartphone, data credit, or literacy the family doesn't have.

**What we built (working today, not a concept).** A local-first app that works with no internet on a basic Android phone:

- **Offline IMCI-aligned triage** (child + pregnancy) â€” adaptive questions, deterministic danger rules that always win; no connectivity needed.
- **Referral loop that closes:** one tap generates a PDF patient report, SMSed to the mother's registered hospital, the nearest geo-routed volunteer responders and her Care Circle; every alert is tracked until closed.
- **Care calendar synced to Ghana's EPI schedule** â€” immunizations, Vitamin A, deworming, growth checks, ANC/PNC â€” with spoken reminders for low-literacy users.
- **"Nana", a voice-first AI educator** (Ghanaian-elder persona): chat + spoken daily briefing, agentic actions with user confirmation; hybrid offline, intent parser covers core commands with zero connectivity. Nana never diagnoses â€” the deterministic triage engine is the only risk classifier.
- **Pregnancy journey:** LMP/EDD â†’ week-aware ANC calendar â†’ newborn handoff â†’ PNC continuing with the child's record; local-language-friendly content, nutrition plans adapted to Northern Ghana staples and budgets.
- **Facility dashboard + Care Signals:** daily backend scan surfaces missed visits, unclosed urgent alerts, growth faltering, overdue third-trimester ANC and lost-to-follow-up families â€” each with an SMS nudge.

**Technical base.** Flutter (offline-first, local sync with LWW + tombstones) + Node/Express/MongoDB backend + Arkesel SMS + Cloudinary; AI via NVIDIA NIM (Llama 3.1) and ElevenLabs, proxied server-side so keys never leave the backend.

**Why we win where others didn't.** Three properties are engineered in from day one: offline-first (the app is fully usable with data off), voice-first (everything important can be *heard*), and consent-first (explicit consent around sensitive health data). The AI educates and escalates; only the deterministic engine ever classifies risk â€” auditable and defensible to health authorities.

**What we're asking for.** [Per funder: seed grant of X / inclusion in cohort Y / pilot partnership.] We want to run a supervised pilot in [DISTRICT], Northern Region, with [N] community health workers and [N] facilities, and generate the evidence needed to scale nationally with the Ghana Health Service.

**The team.** TOVO LABs is a Ghanaian software engineering and product studio building digital solutions for modern organizations. [Add 1â€“2 lines per member: name, focus (e.g. mobile, backend, health ops), any relevant background.]

**Demo.** 2-minute video on request; a working Android APK is available today for technical reviewers.

Contact: Abdul Hafis Mohammed, CEO & Software Engineer â€” TOVO LABs | abdulhafis2847@gmail.com | 059 988 0977

